package com.saip.awan

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import android.util.Log
import org.json.JSONArray
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * The reader's own mosques, as fences the ringer may respect.
 *
 * Why this exists: public map data cannot answer "am I standing in *this*
 * mosque?". A small neighbourhood mosque is often missing from OSM, and indoors
 * a GPS fix is only good to 10–30 m — so the honest source of truth is the spot
 * the reader recorded while standing in it.
 *
 * The list is written once by Flutter (the store's JSON, unchanged) and read
 * here by [RingerAlarmReceiver], which may run when the app is not even in
 * memory. The check is deliberately conservative:
 *
 *  * a fix younger than two minutes is used as is;
 *  * otherwise one single update is requested and awaited for a few seconds —
 *    one shot at prayer time, not a background tracking service;
 *  * no fix at all returns `inside == null`, and the caller decides (today:
 *    keep the silence, because a phone that fails to go quiet inside a mosque
 *    is a worse bug than one that goes quiet at home during the same minutes).
 */
object MosqueFence {

    private const val TAG = "AwanFence"
    private const val PREFS = "awan_mosque_fence"
    private const val KEY_FENCES = "fences"
    private const val KEY_ENABLED = "enabled"

    /** A fix older than this is not trusted for a "you are here" answer. */
    private const val MAX_LAST_KNOWN_MS = 15 * 60 * 1000L

    /** A fix younger than this needs no new request at all. */
    private const val FRESH_MS = 2 * 60 * 1000L

    data class Fence(val name: String, val lat: Double, val lng: Double, val radius: Double)

    data class Check(
        val inside: Boolean?,
        val name: String?,
        val distance: Double?,
        val accuracy: Double?,
        val reason: String
    )

    fun write(context: Context, fencesJson: String, enabled: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_FENCES, fencesJson)
            .putBoolean(KEY_ENABLED, enabled)
            .apply()
    }

    fun isEnabled(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_ENABLED, false)

    fun fences(context: Context): List<Fence> = parse(
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_FENCES, null)
    )

    fun parse(json: String?): List<Fence> {
        if (json.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(json)
            (0 until array.length()).mapNotNull { i ->
                val item = array.optJSONObject(i) ?: return@mapNotNull null
                val lat = item.optDouble("lat", Double.NaN)
                val lng = item.optDouble("lng", Double.NaN)
                if (lat.isNaN() || lng.isNaN()) return@mapNotNull null
                Fence(
                    name = item.optString("name").ifBlank { "مسجد" },
                    lat = lat,
                    lng = lng,
                    radius = item.optDouble("radius", 10.0).coerceIn(5.0, 200.0)
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /**
     * Blocks for at most [timeoutMs]; call it off the main thread.
     *
     * [force] is for the "check now" button: a reader who just walked out of the
     * mosque must not be told they are still inside because a two-minute-old fix
     * says so. The alarm keeps the cache-first behaviour, where a fresh fix is
     * free and a request costs battery.
     */
    fun checkNow(context: Context, timeoutMs: Long = 8000, force: Boolean = false): Check {
        val list = fences(context)
        if (list.isEmpty()) return Check(null, null, null, null, "no-fences")
        val location = locate(context, timeoutMs, force)
            ?: return Check(null, null, null, null, "no-fix")
        return evaluate(list, location.latitude, location.longitude, location.accuracy.toDouble())
            .copy(reason = "fix")
    }

    fun evaluate(list: List<Fence>, lat: Double, lng: Double, accuracy: Double): Check {
        var best: Fence? = null
        var bestDistance = Double.MAX_VALUE
        for (fence in list) {
            val d = distanceMeters(lat, lng, fence.lat, fence.lng)
            if (d < bestDistance) {
                bestDistance = d
                best = fence
            }
        }
        if (best == null) return Check(null, null, null, accuracy, "no-fences")
        val inside = bestDistance <= best.radius
        Log.i(
            TAG,
            "nearest=${best.name} distance=${"%.1f".format(bestDistance)}m " +
                "radius=${best.radius}m inside=$inside accuracy=${"%.1f".format(accuracy)}m"
        )
        return Check(inside, best.name, bestDistance, accuracy, "fix")
    }

    private fun hasPermission(context: Context): Boolean =
        context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    private fun locate(context: Context, timeoutMs: Long, force: Boolean = false): Location? {
        if (!hasPermission(context)) return null
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

        var last: Location? = null
        for (provider in listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER
        )) {
            val candidate = try {
                manager.getLastKnownLocation(provider)
            } catch (_: SecurityException) {
                null
            } catch (_: IllegalArgumentException) {
                null
            } ?: continue
            val age = System.currentTimeMillis() - candidate.time
            if (age > MAX_LAST_KNOWN_MS) continue
            if (last == null || candidate.time > last.time) last = candidate
        }

        val age = last?.let { System.currentTimeMillis() - it.time } ?: Long.MAX_VALUE
        if (!force && last != null && age < FRESH_MS) return last

        // One update, then give up: this is an alarm, not a tracker.
        val provider = when {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ->
                LocationManager.GPS_PROVIDER
            manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ->
                LocationManager.NETWORK_PROVIDER
            else -> return last
        }
        val latch = CountDownLatch(1)
        var fresh: Location? = null
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                fresh = location
                latch.countDown()
            }

            @Deprecated("Required by the platform below API 30")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

            override fun onProviderEnabled(provider: String) {}

            override fun onProviderDisabled(provider: String) {}
        }
        return try {
            manager.requestSingleUpdate(provider, listener, Looper.getMainLooper())
            latch.await(timeoutMs, TimeUnit.MILLISECONDS)
            manager.removeUpdates(listener)
            fresh ?: last
        } catch (_: SecurityException) {
            last
        } catch (_: IllegalArgumentException) {
            last
        }
    }

    /** Great-circle distance, the same formula the Dart side uses. */
    fun distanceMeters(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val r = 6371000.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLng = Math.toRadians(lng2 - lng1)
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
            sin(dLng / 2) * sin(dLng / 2)
        return 2 * r * asin(min(1.0, sqrt(a)))
    }
}
