package com.saip.awan

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Adhan alarms with **one** notification id.
 *
 * The plugin schedules each prayer as its own notification id, so the shade kept
 * every adhan of the last days: five a day, forever, because a notification only
 * leaves when it is tapped. The reader asked for the opposite — a new adhan
 * should take the place of the previous one.
 *
 * Android replaces a notification whose id is reused, so the fix is to post
 * every adhan under [AdhanNotification.ID]. The alarms themselves still need
 * distinct request codes (an AlarmManager PendingIntent is keyed by request
 * code), so the plan is scheduled natively here and the *notification* collapses
 * to one. A timeout clears even that one a while after the adhan, so a phone
 * left alone overnight does not wake up to yesterday's Fajr.
 */
object AdhanAlarm {

    const val ACTION = "com.saip.awan.ADHAN_ALARM"

    private const val PREFS = "awan_adhan_alarms"
    private const val KEY_PLAN = "plan"
    private const val TAG = "AwanAdhanAlarm"

    fun schedule(context: Context, items: List<Map<String, Any?>>) {
        val manager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val stored = JSONArray()
        val now = System.currentTimeMillis()

        // A rebuilt plan may renumber the prayers; cancel what the previous
        // plan left armed so the phone cannot fire the same adhan twice.
        cancelArmed(context, manager)

        for (raw in items) {
            val id = (raw["id"] as? Number)?.toInt() ?: continue
            val at = (raw["at"] as? Number)?.toLong() ?: continue
            if (at <= now) continue

            val entry = JSONObject()
                .put("id", id)
                .put("at", at)
                .put("title", raw["title"] as? String ?: "")
                .put("body", raw["body"] as? String ?: "")
                .put("countdown", (raw["countdown"] as? Number)?.toLong() ?: 0L)
                .put("channel", raw["channel"] as? String ?: AdhanNotification.FALLBACK_CHANNEL)
            stored.put(entry)

            try {
                arm(manager, at, pendingIntent(context, id, entry))
            } catch (error: Exception) {
                Log.w(TAG, "could not arm $id: $error")
            }
        }

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PLAN, stored.toString())
            .apply()
        Log.i(TAG, "armed ${stored.length()} adhan alarms")
    }

    /** Cancels what this process scheduled; called whenever the plan is rebuilt. */
    fun cancelAll(context: Context) {
        val manager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val plan = readPlan(context)
        for (i in 0 until plan.length()) {
            val entry = plan.optJSONObject(i) ?: continue
            val id = entry.optInt("id", 0)
            manager.cancel(pendingIntent(context, id, entry))
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_PLAN)
            .apply()
    }

    /**
     * Alarms do not survive a reboot. The plan is kept as JSON, so the boot
     * receiver can arm the remaining prayers without the Flutter engine — the
     * same reason the silence windows are stored natively.
     */
    fun rearmAfterBoot(context: Context) {
        val plan = readPlan(context)
        if (plan.length() == 0) return
        val items = ArrayList<Map<String, Any?>>(plan.length())
        for (i in 0 until plan.length()) {
            val entry = plan.optJSONObject(i) ?: continue
            items.add(
                mapOf(
                    "id" to entry.optInt("id"),
                    "at" to entry.optLong("at"),
                    "title" to entry.optString("title"),
                    "body" to entry.optString("body"),
                    "channel" to entry.optString("channel"),
                    "countdown" to entry.optLong("countdown"),
                )
            )
        }
        schedule(context, items)
    }

    private fun cancelArmed(context: Context, manager: AlarmManager) {
        val previous = readPlan(context)
        for (i in 0 until previous.length()) {
            val entry = previous.optJSONObject(i) ?: continue
            manager.cancel(pendingIntent(context, entry.optInt("id", 0), entry))
        }
    }

    private fun readPlan(context: Context): JSONArray {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_PLAN, null) ?: return JSONArray()
        return try {
            JSONArray(raw)
        } catch (error: Exception) {
            JSONArray()
        }
    }

    private fun arm(manager: AlarmManager, at: Long, pending: PendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !manager.canScheduleExactAlarms()) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            return
        }
        try {
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        } catch (error: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        }
    }

    private fun pendingIntent(
        context: Context,
        id: Int,
        entry: JSONObject
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = ACTION
            putExtra("id", id)
            putExtra("title", entry.optString("title"))
            putExtra("body", entry.optString("body"))
            putExtra("countdown", entry.optLong("countdown"))
            putExtra("channel", entry.optString("channel"))
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}

/** What runs at the prayer time: one notification, one id. */
class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: return
        val body = intent.getStringExtra("body") ?: ""
        val channel = intent.getStringExtra("channel")
            ?: AdhanNotification.FALLBACK_CHANNEL
        val countdown = intent.getLongExtra("countdown", 0L)
        AdhanNotification.post(context, title, body, channel, countdown)
    }
}

/** Re-arms the adhan alarms after a restart. */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        AdhanAlarm.rearmAfterBoot(context)
    }
}

object AdhanNotification {

    /**
     * The single id every adhan is posted under. Reusing it is what makes the
     * new adhan *replace* the previous one instead of stacking under it.
     */
    const val ID = 2

    const val FALLBACK_CHANNEL = "awan.adhan-fallback"

    /** An adhan that is still on the shade an hour later is litter, not a call. */
    private const val TIMEOUT_MS = 20 * 60 * 1000L

    private const val TAG = "AwanAdhan"

    fun post(
        context: Context,
        title: String,
        body: String,
        channelId: String,
        countdownTo: Long = 0L
    ) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = ensureChannel(context, manager, channelId)

        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = Notification.Builder(context, channel)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setAutoCancel(true)
            .setContentIntent(open)
            .setTimeoutAfter(TIMEOUT_MS)
            .apply {
                if (countdownTo > 0L) {
                    setWhen(countdownTo)
                    setShowWhen(true)
                    setUsesChronometer(true)
                    setChronometerCountDown(true)
                }
            }
            .build()

        try {
            manager.notify(ID, notification)
        } catch (error: Exception) {
            Log.w(TAG, "notify failed: $error")
        }
    }

    /**
     * The plugin creates the adhan channels (a channel's sound is frozen at
     * creation, which is why the clip is part of its id). If the app has never
     * run since install there is nothing to post to, so a plain alarm-sound
     * channel is created once rather than losing the adhan silently.
     */
    private fun ensureChannel(
        context: Context,
        manager: NotificationManager,
        channelId: String
    ): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return channelId
        if (manager.getNotificationChannel(channelId) != null) return channelId
        if (manager.getNotificationChannel(FALLBACK_CHANNEL) == null) {
            val sound = Uri.parse(
                "android.resource://${context.packageName}/" +
                    context.resources.getIdentifier(
                        "allah_akbar",
                        "raw",
                        context.packageName
                    )
            )
            val channel = NotificationChannel(
                FALLBACK_CHANNEL,
                "الأذان",
                NotificationManager.IMPORTANCE_MAX
            ).apply {
                description = "تنبيه وقت الصلاة"
                enableVibration(true)
                setSound(
                    sound,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            manager.createNotificationChannel(channel)
        }
        return FALLBACK_CHANNEL
    }
}
