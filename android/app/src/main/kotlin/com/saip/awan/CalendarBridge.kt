package com.saip.awan

import android.Manifest
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.app.Activity
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

/**
 * The phone's own calendar, read and written through the system provider.
 *
 * Why the provider and not a plugin: the observer has to be a real
 * `ContentObserver` on `CalendarContract.Events`, and the write has to carry the
 * app's own marker so a later pass can find its blocks again. Both are three
 * lines here and a dependency elsewhere.
 *
 * Nothing is read until the reader grants READ_CALENDAR, and nothing is written
 * without WRITE_CALENDAR — the app never asks for an account, only for the
 * calendars the phone already has.
 */
class CalendarBridge(
    private val activity: Activity,
    private val messenger: io.flutter.plugin.common.BinaryMessenger
) {
    private val context: Context get() = activity
    companion object {
        private const val TAG = "AwanCalendar"
        const val CHANNEL = "awan/calendar"
        const val CHANGES_CHANNEL = "awan/calendar/changes"
        const val REQUEST_CODE = 5262

        /** Prefix written into DESCRIPTION: our blocks, not the reader's events. */
        const val MARKER = "awan:block:"
    }

    private val resolver: ContentResolver get() = context.contentResolver
    private var events: EventChannel.EventSink? = null
    private var observer: ContentObserver? = null
    private val handler = Handler(Looper.getMainLooper())
    private var pendingNotify = false

    fun register() {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "hasPermission" -> result.success(hasPermission())
                    "requestPermission" -> requestPermission(result)
                    "writableCalendarId" -> result.success(writableCalendarId())
                    "query" -> {
                        val start = call.argument<Number>("start")?.toLong() ?: 0L
                        val end = call.argument<Number>("end")?.toLong() ?: 0L
                        result.success(query(start, end))
                    }
                    "insert" -> result.success(insert(call))
                    "move" -> result.success(move(call))
                    "delete" -> result.success(delete(call))
                    "startWatching" -> {
                        startWatching()
                        result.success(null)
                    }
                    "stopWatching" -> {
                        stopWatching()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: SecurityException) {
                Log.i(TAG, "no calendar permission: $error")
                result.error("permission", error.message, null)
            } catch (error: Exception) {
                Log.i(TAG, "calendar call failed: $error")
                result.error("calendar", error.message, null)
            }
        }
        EventChannel(messenger, CHANGES_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    events = sink
                    startWatching()
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                    stopWatching()
                }
            }
        )
    }

    private var pendingResult: MethodChannel.Result? = null

    /**
     * The OS dialog is the only way to grant calendar access, so the answer
     * arrives in `onRequestPermissionsResult` and the caller waits on it.
     */
    private fun requestPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success(true)
            return
        }
        pendingResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.READ_CALENDAR,
                Manifest.permission.WRITE_CALENDAR
            ),
            REQUEST_CODE
        )
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST_CODE) return
        val result = pendingResult ?: return
        pendingResult = null
        result.success(grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED })
    }

    private fun hasPermission(): Boolean {
        val read = ContextCompat.checkSelfPermission(
            context, Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        val write = ContextCompat.checkSelfPermission(
            context, Manifest.permission.WRITE_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        return read && write
    }

    /** The first calendar this app may write to, preferring the primary one. */
    private fun writableCalendarId(): String? {
        if (!hasPermission()) return null
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            CalendarContract.Calendars.IS_PRIMARY,
        )
        val selection =
            "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL}>=?"
        val args = arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString())
        resolver.query(
            CalendarContract.Calendars.CONTENT_URI, projection, selection, args, null
        )?.use { cursor ->
            var fallback: String? = null
            while (cursor.moveToNext()) {
                val id = cursor.getLong(0).toString()
                val primary = if (cursor.isNull(2)) 0 else cursor.getInt(2)
                if (primary == 1) return id
                if (fallback == null) fallback = id
            }
            return fallback
        }
        return null
    }

    private fun query(start: Long, end: Long): List<Map<String, Any?>> {
        if (!hasPermission()) return emptyList()
        val projection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.DTEND,
            CalendarContract.Events.ALL_DAY,
            CalendarContract.Events.ORGANIZER,
            CalendarContract.Events.AVAILABILITY,
            CalendarContract.Events.CALENDAR_ID,
            CalendarContract.Events.DESCRIPTION,
        )
        // A meeting that started before the window and ends inside it still
        // matters, so the selection is on the *end* against the window start.
        val selection =
            "${CalendarContract.Events.DTSTART} <= ? AND " +
                "(${CalendarContract.Events.DTEND} IS NULL OR " +
                "${CalendarContract.Events.DTEND} >= ?)"
        val args = arrayOf(end.toString(), start.toString())
        val out = ArrayList<Map<String, Any?>>()
        resolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            selection,
            args,
            "${CalendarContract.Events.DTSTART} ASC",
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val allDay = cursor.getInt(4) == 1
                val dtStart = if (cursor.isNull(2)) 0L else cursor.getLong(2)
                val dtEnd = if (cursor.isNull(3)) {
                    dtStart + 30 * 60 * 1000L
                } else cursor.getLong(3)
                val organizer = if (cursor.isNull(5)) null else cursor.getString(5)
                val availability = if (cursor.isNull(6)) 0 else cursor.getInt(6)
                out.add(
                    mapOf(
                        "id" to cursor.getLong(0).toString(),
                        "title" to (if (cursor.isNull(1)) "" else cursor.getString(1)),
                        "start" to dtStart,
                        "end" to dtEnd,
                        "allDay" to allDay,
                        "isOrganizer" to (organizer == null),
                        "busy" to (availability != CalendarContract.Events.AVAILABILITY_FREE),
                        "calendarId" to cursor.getLong(7).toString(),
                        "note" to if (cursor.isNull(8)) "" else cursor.getString(8),
                    )
                )
            }
        }
        return out
    }

    private fun insert(call: io.flutter.plugin.common.MethodCall): String? {
        if (!hasPermission()) return null
        val calendarId = call.argument<String>("calendarId") ?: writableCalendarId() ?: return null
        val start = call.argument<Number>("start")?.toLong() ?: return null
        val end = call.argument<Number>("end")?.toLong() ?: return null
        val title = call.argument<String>("title") ?: ""
        val marker = call.argument<String>("marker") ?: ""
        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId.toLong())
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DESCRIPTION, MARKER + marker)
            put(CalendarContract.Events.DTSTART, start)
            put(CalendarContract.Events.DTEND, end)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
            put(CalendarContract.Events.HAS_ALARM, 0)
            put(
                CalendarContract.Events.AVAILABILITY,
                CalendarContract.Events.AVAILABILITY_BUSY
            )
            put(CalendarContract.Events.EVENT_END_TIMEZONE, TimeZone.getDefault().id)
        }
        val uri: Uri = resolver.insert(CalendarContract.Events.CONTENT_URI, values)
            ?: return null
        return ContentUris.parseId(uri).toString()
    }

    private fun move(call: io.flutter.plugin.common.MethodCall): Boolean {
        if (!hasPermission()) return false
        val id = call.argument<String>("id") ?: return false
        val start = call.argument<Number>("start")?.toLong() ?: return false
        val end = call.argument<Number>("end")?.toLong() ?: return false
        val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id.toLong())
        val values = ContentValues().apply {
            put(CalendarContract.Events.DTSTART, start)
            put(CalendarContract.Events.DTEND, end)
        }
        return resolver.update(uri, values, null, null) > 0
    }

    private fun delete(call: io.flutter.plugin.common.MethodCall): Boolean {
        if (!hasPermission()) return false
        val id = call.argument<String>("id") ?: return false
        val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id.toLong())
        return resolver.delete(uri, null, null) > 0
    }

    /**
     * One observer for the whole provider, coalesced: a calendar sync can write
     * hundreds of rows in a second, and the screen only needs to know "something
     * moved" once.
     */
    private fun startWatching() {
        if (observer != null || !hasPermission()) return
        val content = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                if (pendingNotify) return
                pendingNotify = true
                handler.postDelayed({
                    pendingNotify = false
                    events?.success(mapOf("changed" to true))
                }, 800)
            }
        }
        observer = content
        resolver.registerContentObserver(CalendarContract.Events.CONTENT_URI, true, content)
        Log.i(TAG, "watching the calendar")
    }

    private fun stopWatching() {
        val content = observer ?: return
        try {
            resolver.unregisterContentObserver(content)
        } catch (_: IllegalArgumentException) {
        }
        observer = null
        Log.i(TAG, "stopped watching the calendar")
    }
}
