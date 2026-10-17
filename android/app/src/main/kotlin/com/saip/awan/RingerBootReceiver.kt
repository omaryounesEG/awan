package com.saip.awan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Re-arms the silence windows after a restart.
 *
 * `AlarmManager` forgets everything when the phone reboots, and the windows are
 * computed by Dart from the prayer times — which cannot run at boot. So the
 * windows are also stored as plain instants when they are armed, and this
 * receiver hands exactly those instants back to the OS. No Flutter, no network,
 * no wake-ups: a reboot must not be the reason the phone rings in the khutbah.
 */
class RingerBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent?.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = context.getSharedPreferences(MainActivity.PREFS_WINDOWS, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_WINDOWS, null) ?: return
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        var armed = 0
        raw.split(';').forEachIndexed { index, pair ->
            val parts = pair.split(',')
            val start = parts.getOrNull(0)?.toLongOrNull()
            val end = parts.getOrNull(1)?.toLongOrNull()
            if (start != null && end != null) {
                armed += arm(context, manager, index * 2, start, MainActivity.MODE_SILENT, now)
                armed += arm(context, manager, index * 2 + 1, end, MainActivity.MODE_NORMAL, now)
            }
        }
        Log.i(TAG, "re-armed $armed silence moments after boot")
    }

    private fun arm(
        context: Context,
        manager: AlarmManager,
        slot: Int,
        at: Long,
        mode: String,
        now: Long
    ): Int {
        if (at <= now) return 0
        val id = MainActivity.SILENCE_ID_BASE + slot
        val intent = Intent(context, RingerAlarmReceiver::class.java).apply {
            putExtra(MainActivity.EXTRA_MODE, mode)
            putExtra("awan.ringer.id", id)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return try {
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            1
        } catch (_: SecurityException) {
            manager.set(AlarmManager.RTC_WAKEUP, at, pending)
            1
        }
    }

    companion object {
        private const val TAG = "AwanRinger"
        const val KEY_WINDOWS = "windows"
    }
}
