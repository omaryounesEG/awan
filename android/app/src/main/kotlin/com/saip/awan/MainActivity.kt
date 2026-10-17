package com.saip.awan

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

/**
 * The only native code the app owns.
 *
 * Two channels:
 *
 * * `awan/location` — a device fix without a heavyweight plugin (the `geolocator`
 *   Android module cannot even be configured on this toolchain, see
 *   NATIVE_SETUP.md), plus the IANA zone id that `zonedSchedule` needs.
 * * `awan/ringer` — hands the mute/unmute moments to `AlarmManager`, so the OS,
 *   and not a background service of ours, performs the switch.
 *
 * Nothing here runs periodically and nothing holds a wakelock.
 */
class MainActivity : FlutterActivity() {

    /** Kept so `cleanUpFlutterEngine` can close the ONNX session with the engine. */
    private var semanticEncoder: SemanticEncoder? = null

    companion object {
        private const val LOCATION_CHANNEL = "awan/location"

        /**
         * Auto-silent (ringer) channel. Named after the app, not the feature, so
         * the Dart side reads as `com.awan.app/audio`.
         */
        private const val AUDIO_CHANNEL = "com.awan.app/audio"

        /**
         * Compass stream. An `EventChannel` rather than a method channel because
         * the reading is continuous, and cold: the sensor is registered in
         * `onListen` and released in `onCancel`, which is what makes "closing the
         * screen stops the compass" true rather than aspirational.
         */
        private const val HEADING_CHANNEL = "com.awan.app/sensors/heading"

        /** The recitation checker's microphone: 16 kHz mono PCM, live. */
        private const val RECITATION_AUDIO_CHANNEL = "com.awan.app/recitation/audio"
        private const val SENSOR_TAG = "AwanSensors"
        private const val PERMISSION_REQUEST = 5261
        private const val FIX_TIMEOUT_MS = 6_000L

        /** The prayer clock: raised over the keyguard, ticking while locked. */
        private const val CLOCK_CHANNEL = "awan/clock"

        /**
         * Auditioning the bundled alert clips. Previewed through the *same* raw
         * resource the notification will use, so what the reader hears in the
         * picker is exactly what will ring — not an approximation of it.
         */
        private const val SOUNDS_CHANNEL = "awan/sounds"
        /** The next-prayer card: one id, one channel, dismissed by a tap. */
        private const val CARD_CHANNEL = "awan.lockscreen-v2"
        const val CARD_ID = 1

        /** Ids reserved for silence alarms, so they never collide with adhans. */
        /** Where the armed windows are kept for the post-reboot re-arm. */
        const val PREFS_WINDOWS = "awan_ringer_windows"

        const val SILENCE_ID_BASE = 900_000
        const val SILENCE_ID_MAX = 900_500
        const val EXTRA_MODE = "awan.ringer.mode"
        const val MODE_SILENT = "silent"
        const val MODE_NORMAL = "normal"
    }

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingFixResult: MethodChannel.Result? = null
    private var fixListener: LocationListener? = null
    private val handler = Handler(Looper.getMainLooper())

    /** Calendar access: one bridge, so its pending permission answer is kept. */
    private var calendarBridge: CalendarBridge? = null

    /** Manual updates: the channel that hands an APK to Android's installer. */
    private var apkInstaller: ApkInstaller? = null

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        semanticEncoder?.dispose()
        semanticEncoder = null
        apkInstaller?.dispose()
        apkInstaller = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasLocationPermission())
                    "requestPermission" -> requestLocationPermission(result)
                    "isServiceEnabled" -> result.success(isLocationEnabled())
                    "openLocationSettings" -> {
                        startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                        result.success(null)
                    }
                    "getLocation" -> deliverFix(result)
                    "timeZoneId" -> result.success(TimeZone.getDefault().id)
                    else -> result.notImplemented()
                }
            }

        // Manual updates: hands a downloaded APK to Android's installer.
        apkInstaller = ApkInstaller(applicationContext, flutterEngine.dartExecutor.binaryMessenger)

        // The recitation checker's microphone: 16 kHz mono PCM straight out of
        // AudioRecord, live, never written to disk (see RecitationAudioBridge).
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, RECITATION_AUDIO_CHANNEL)
            .setStreamHandler(RecitationAudioBridge(applicationContext))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLOCK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "keepScreenOn" -> {
                        val on = call.argument<Boolean>("on") == true
                        runOnUiThread { setKeepScreenOn(on) }
                        result.success(null)
                    }
                    // The next-prayer card, posted natively for one reason: its
                    // content intent can be a *dismiss* broadcast. A card that
                    // opens the app when touched is a card that launches an app
                    // the reader did not ask for.
                    "postCard" -> {
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val at = call.argument<Number>("when")?.toLong()
                            ?: System.currentTimeMillis()
                        val countUp = call.argument<Boolean>("countUp") == true
                        runOnUiThread { postPrayerCard(title, body, at, countUp) }
                        result.success(true)
                    }
                    "cancelCard" -> {
                        runOnUiThread {
                            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                                .cancel(CARD_ID)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        calendarBridge = CalendarBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        calendarBridge?.register()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOUNDS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playPreview" -> {
                        playPreview(call.argument<String>("res"))
                        result.success(null)
                    }
                    "playSystem" -> {
                        playSystemTone()
                        result.success(null)
                    }
                    "stopPreview" -> {
                        stopPreview()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPolicyAccess" -> result.success(hasPolicyAccess())
                    "openPolicySettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "hasExactAlarmAccess" -> result.success(hasExactAlarmAccess())
                    // The two named helpers the Flutter side calls, plus the
                    // parameterised form they both reduce to.
                    "setSilentMode" -> result.success(setRingerMode(true))
                    "setNormalMode" -> result.success(setRingerMode(false))
                    "setSilentNow" -> result.success(
                        setRingerMode(call.argument<Boolean>("silent") == true)
                    )
                    "currentMode" -> result.success(currentRingerMode())
                    "scheduleWindows" -> result.success(scheduleWindows(call.arguments))
                    "cancelWindows" -> {
                        cancelWindows()
                        result.success(null)
                    }
                    // Called when auto-silent is switched off: the phone must not
                    // be left silent by an alarm that no longer exists.
                    "releaseRinger" -> {
                        releaseIfOurs()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Compass: cold stream, and a `[AwanSensors]` line for every register /
        // unregister so the lifecycle claim is checkable in logcat.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, HEADING_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
                    if (sensor == null) {
                        // No fused rotation vector: say so once, plainly, instead of
                        // leaving the dial turning on a number that never arrives.
                        Log.i(SENSOR_TAG, "no rotation-vector sensor on this device")
                        events?.error("no_sensor", "no_magnetometer", null)
                        return
                    }

                    val map = arguments as? Map<*, *>
                    val latitude = (map?.get("latitude") as? Number)?.toDouble()
                    val longitude = (map?.get("longitude") as? Number)?.toDouble()
                    magneticField = if (latitude != null && longitude != null) {
                        GeomagneticField(
                            latitude.toFloat(),
                            longitude.toFloat(),
                            0f,
                            System.currentTimeMillis()
                        )
                    } else {
                        null
                    }

                    smoothedAzimuth = null
                    headingSink = events
                    sensorManager.registerListener(
                        headingListener,
                        sensor,
                        SensorManager.SENSOR_DELAY_UI
                    )
                    Log.i(
                        SENSOR_TAG,
                        "heading listener registered, declination=${magneticField?.declination}"
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorManager.unregisterListener(headingListener)
                    headingSink = null
                    Log.i(SENSOR_TAG, "heading listener unregistered - sensor powered down")
                }
            })
    }

    // -------------------------------------------------------------- prayer card

    private fun setKeepScreenOn(on: Boolean) {
        if (on) {
            window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    /**
     * The one silent card about the next prayer.
     *
     * Counting down to [at], or — just after the adhan — up from it, which is the
     * twenty minutes in which the reader still cares how long ago it was. Touching
     * the card dismisses it: nothing here starts an activity.
     */
    private fun postPrayerCard(title: String, body: String, at: Long, countUp: Boolean) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureCardChannel(manager)
        val dismiss = PendingIntent.getBroadcast(
            this,
            CARD_ID,
            Intent(this, CardDismissReceiver::class.java).apply {
                action = CardDismissReceiver.ACTION_DISMISS
                putExtra(CardDismissReceiver.EXTRA_ID, CARD_ID)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = Notification.Builder(this, CARD_CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setWhen(at)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(!countUp)
            .setOngoing(false)
            .setAutoCancel(true)
            // Silent by construction: the channel is IMPORTANCE_LOW with no sound.
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setPriority(Notification.PRIORITY_LOW)
            .setContentIntent(dismiss)
        manager.notify(CARD_ID, builder.build())
    }

    private fun ensureCardChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(CARD_CHANNEL) != null) return
        val channel = NotificationChannel(
            CARD_CHANNEL,
            getString(R.string.app_name),
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "الصلاة القادمة والوقت المتبقي"
            setShowBadge(false)
            enableLights(false)
            enableVibration(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    // ------------------------------------------------------------------ heading

    private val sensorManager: SensorManager by lazy {
        getSystemService(Context.SENSOR_SERVICE) as SensorManager
    }

    private var headingSink: EventChannel.EventSink? = null

    /** Local magnetic declination for the last requested coordinates. */
    private var magneticField: GeomagneticField? = null

    /** Low-pass state: a raw magnetometer is far too jittery to draw. */
    private var smoothedAzimuth: Float? = null

    private val headingListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val rotation = FloatArray(9)
            SensorManager.getRotationMatrixFromVector(rotation, event.values)
            val orientation = FloatArray(3)
            SensorManager.getOrientation(rotation, orientation)

            var azimuth = Math.toDegrees(orientation[0].toDouble()).toFloat()
            if (azimuth < 0f) azimuth += 360f

            val previous = smoothedAzimuth
            val smoothed = if (previous == null) azimuth else smooth(previous, azimuth)
            smoothedAzimuth = smoothed

            // Magnetic -> true north. The qibla bearing is a true-north bearing,
            // so without this line the needle is a few degrees off everywhere.
            val declination = magneticField?.declination ?: 0f
            headingSink?.success(
                mapOf(
                    "trueHeading" to ((smoothed + declination + 360f) % 360f).toDouble(),
                    "magneticHeading" to smoothed.toDouble(),
                    "declination" to declination.toDouble()
                )
            )
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
    }

    /** Wrap-aware exponential moving average (359 -> 1 must move 2 degrees). */
    private fun smooth(previous: Float, next: Float, factor: Float = 0.18f): Float {
        val delta = ((next - previous + 540f) % 360f) - 180f
        return ((previous + delta * factor) + 360f) % 360f
    }

    // ------------------------------------------------------------------ location

    private fun hasLocationPermission(): Boolean =
        checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED ||
                checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED


    // ------------------------------------------------------------ sound preview
    //
    // One player, always stopped before the next clip starts: auditioning four
    // sounds in a row must never leave two of them talking. Released on stop, so
    // the picker holds no codec once the reader leaves it.

    private var previewPlayer: MediaPlayer? = null
    private var previewRingtone: Ringtone? = null

    private fun stopPreview() {
        previewPlayer?.let { player ->
            try {
                if (player.isPlaying) player.stop()
            } catch (_: IllegalStateException) {
                // Already finished: nothing to stop.
            }
            player.release()
        }
        previewPlayer = null
        previewRingtone?.stop()
        previewRingtone = null
    }

    private fun playPreview(name: String?) {
        stopPreview()
        if (name == null) return
        val id = resources.getIdentifier(name, "raw", packageName)
        if (id == 0) return
        val player = MediaPlayer.create(this, id) ?: return
        player.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        player.setOnCompletionListener { stopPreview() }
        previewPlayer = player
        player.start()
    }

    /** The phone's own alarm tone, the one `system` means in the picker. */
    private fun playSystemTone() {
        stopPreview()
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        val ringtone = RingtoneManager.getRingtone(this, uri) ?: return
        previewRingtone = ringtone
        ringtone.play()
    }

    private fun requestLocationPermission(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION
            ),
            PERMISSION_REQUEST
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        calendarBridge?.onRequestPermissionsResult(requestCode, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    private fun isLocationEnabled(): Boolean {
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            manager.isLocationEnabled
        } else {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                    manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    /**
     * Last known fix first (instant, and plenty accurate for prayer times), then
     * one bounded single update. The result is delivered exactly once.
     */
    private fun deliverFix(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.success(null)
            return
        }
        lastKnownFix()?.let {
            result.success(fixMap(it))
            return
        }
        if (pendingFixResult != null) {
            result.success(null)
            return
        }
        pendingFixResult = result
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val listener = LocationListener { location -> finishFix(location) }
        fixListener = listener
        try {
            manager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER, 0L, 0f, listener, Looper.getMainLooper()
            )
            manager.requestLocationUpdates(
                LocationManager.NETWORK_PROVIDER, 0L, 0f, listener, Looper.getMainLooper()
            )
        } catch (_: SecurityException) {
            finishFix(null)
            return
        } catch (_: IllegalArgumentException) {
            finishFix(null)
            return
        }
        // Never leave the caller hanging on a fix that will not arrive indoors.
        handler.postDelayed({ finishFix(null) }, FIX_TIMEOUT_MS)
    }

    private fun finishFix(location: Location?) {
        val result = pendingFixResult ?: return
        pendingFixResult = null
        fixListener?.let {
            val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            try {
                manager.removeUpdates(it)
            } catch (_: Exception) {
                // Already detached.
            }
        }
        fixListener = null
        result.success(location?.let { fixMap(it) })
    }

    private fun fixMap(location: Location): Map<String, Any> = mapOf(
        "latitude" to location.latitude,
        "longitude" to location.longitude,
        "accuracy" to location.accuracy.toDouble()
    )

    private fun lastKnownFix(): Location? {
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        var best: Location? = null
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
            if (best == null || candidate.time > best!!.time) best = candidate
        }
        return best
    }

    // -------------------------------------------------------------------- ringer

    private fun hasPolicyAccess(): Boolean {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.isNotificationPolicyAccessGranted
    }

    private fun hasExactAlarmAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val manager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return manager.canScheduleExactAlarms()
    }

    private fun currentRingerMode(): String {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return when (audio.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> MODE_SILENT
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            else -> MODE_NORMAL
        }
    }

    /** Silent needs Do-Not-Disturb access on API 23+; restoring does not. */
    private fun setRingerMode(silent: Boolean): Boolean {
        if (silent && !hasPolicyAccess()) return false
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return try {
            audio.ringerMode =
                if (silent) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL
            true
        } catch (_: SecurityException) {
            false
        }
    }

    private fun scheduleWindows(arguments: Any?): Int {
        val windows = (arguments as? Map<*, *>)?.get("windows") as? List<*> ?: return 0
        cancelWindows()
        val manager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        var armed = 0
        windows.forEachIndexed { index, raw ->
            val entry = raw as? Map<*, *>
            if (entry != null) {
                val start = (entry["start"] as? Number)?.toLong()
                val end = (entry["end"] as? Number)?.toLong()
                if (start != null && end != null) {
                    armed += armMoment(manager, index * 2, start, MODE_SILENT, now)
                    armed += armMoment(manager, index * 2 + 1, end, MODE_NORMAL, now)
                }
            }
        }
        // Remembered for [RingerBootReceiver]: a reboot wipes the alarms, and the
        // instants must not be recomputed by a Flutter engine that is not running.
        val flat = windows.mapNotNull { raw ->
            val entry = raw as? Map<*, *>
            val start = (entry?.get("start") as? Number)?.toLong()
            val end = (entry?.get("end") as? Number)?.toLong()
            if (start != null && end != null) "$start,$end" else null
        }.joinToString(";")
        getSharedPreferences(PREFS_WINDOWS, Context.MODE_PRIVATE)
            .edit().putString(RingerBootReceiver.KEY_WINDOWS, flat).apply()
        return armed
    }

    private fun armMoment(
        manager: AlarmManager,
        slot: Int,
        at: Long,
        mode: String,
        now: Long
    ): Int {
        if (at <= now || slot >= (SILENCE_ID_MAX - SILENCE_ID_BASE)) return 0
        val id = SILENCE_ID_BASE + slot
        val intent = Intent(this, RingerAlarmReceiver::class.java).apply {
            putExtra(EXTRA_MODE, mode)
            putExtra("awan.ringer.id", id)
        }
        val pending = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return try {
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            1
        } catch (_: SecurityException) {
            // Exact alarms revoked by the user: an inexact window beats none.
            manager.set(AlarmManager.RTC_WAKEUP, at, pending)
            1
        }
    }

    /**
     * Hands the ringer back when this app is the one holding it silent, and only
     * while the mode is still the one we set — a mode the user changed since is
     * theirs, not ours to undo.
     */
    private fun releaseIfOurs() {
        val prefs = getSharedPreferences(RingerAlarmReceiver.PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(RingerAlarmReceiver.KEY_OURS, false)) return
        val usedFilter = prefs.getBoolean(RingerAlarmReceiver.KEY_USED_FILTER, false)
        val ringerBefore = prefs.getInt(
            RingerAlarmReceiver.KEY_RINGER_BEFORE,
            AudioManager.RINGER_MODE_NORMAL
        )
        val filterBefore = prefs.getInt(
            RingerAlarmReceiver.KEY_FILTER_BEFORE,
            NotificationManager.INTERRUPTION_FILTER_ALL
        )
        prefs.edit().clear().apply()
        try {
            if (usedFilter) {
                val notifications =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (notifications.currentInterruptionFilter ==
                    NotificationManager.INTERRUPTION_FILTER_NONE
                ) {
                    notifications.setInterruptionFilter(filterBefore)
                }
            } else {
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                if (audio.ringerMode == AudioManager.RINGER_MODE_SILENT) {
                    audio.ringerMode = ringerBefore
                }
            }
        } catch (_: SecurityException) {
            // Do-Not-Disturb access revoked: nothing we can do, and nothing wrong.
        }
    }

    private fun cancelWindows() {
        val manager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, RingerAlarmReceiver::class.java)
        for (id in SILENCE_ID_BASE until SILENCE_ID_MAX) {
            val pending = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pending != null) {
                manager.cancel(pending)
                pending.cancel()
            }
        }
    }
}
