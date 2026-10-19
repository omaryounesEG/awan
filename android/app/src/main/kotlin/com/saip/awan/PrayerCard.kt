package com.saip.awan

import android.app.AlarmManager
import android.app.Notification
import android.app.Notification.BigTextStyle
import android.app.Notification.Builder
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * The one silent card that carries «الصلاة القادمة» — posted from three places
 * (the Flutter refresh, the tap-to-dismiss receiver, and the alarm that ends the
 * elapsed state), so the builder lives here instead of inside an Activity.
 *
 * The card is a single fixed id: a new call replaces the previous one rather
 * than stacking, which is why a month of refreshes does not fill the shade.
 */
object PrayerCard {

    const val CHANNEL = "awan.lockscreen-v2"
    const val ID = 1

    private const val SWITCH_REQUEST = 0x0C4D

    fun post(
        context: Context,
        title: String,
        body: String,
        at: Long,
        countUp: Boolean,
        switchAt: Long = 0L,
        afterTitle: String? = null,
        afterBody: String? = null,
        afterWhen: Long = 0L
    ) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannel(context, manager)

        val dismiss = PendingIntent.getBroadcast(
            context,
            ID,
            Intent(context, CardDismissReceiver::class.java).apply {
                action = CardDismissReceiver.ACTION_DISMISS
                putExtra(CardDismissReceiver.EXTRA_ID, ID)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = Builder(context, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(BigTextStyle().bigText(body))
            .setWhen(at)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(!countUp)
            .setOngoing(false)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setPriority(Notification.PRIORITY_LOW)
            .setContentIntent(dismiss)
        manager.notify(ID, builder.build())

        if (switchAt > 0L && afterTitle != null) {
            armSwitch(context, switchAt, afterTitle, afterBody ?: "", afterWhen)
        }
    }

    fun cancel(context: Context) {
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .cancel(ID)
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val armed = PendingIntent.getBroadcast(
            context,
            SWITCH_REQUEST,
            switchIntent(context, ""),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (armed != null) alarm.cancel(armed)
    }

    /**
     * Twenty minutes after the adhan the count-up stops being a decision aid, so
     * the card is replaced at that instant with the «next prayer» wording. This
     * is a plain alarm because the app is not running at that moment.
     */
    private fun armSwitch(
        context: Context,
        switchAt: Long,
        afterTitle: String,
        afterBody: String,
        afterWhen: Long
    ) {
        val intent = switchIntent(context, afterTitle).apply {
            putExtra(CardSwitchReceiver.EXTRA_BODY, afterBody)
            putExtra(CardSwitchReceiver.EXTRA_WHEN, afterWhen)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            SWITCH_REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarm.canScheduleExactAlarms()) {
                // Without the exact-alarm grant the switch is still armed, just
                // not to the second: better a late card than none.
                alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, switchAt, pending)
            } else {
                alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, switchAt, pending)
            }
        } catch (error: SecurityException) {
            Log.i("Awan", "card switch not armed: $error")
        }
    }

    private fun switchIntent(context: Context, title: String): Intent =
        Intent(context, CardSwitchReceiver::class.java).apply {
            action = CardSwitchReceiver.ACTION_SWITCH
            putExtra(CardSwitchReceiver.EXTRA_TITLE, title)
        }

    fun ensureChannel(context: Context, manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(CHANNEL) != null) return
        val channel = NotificationChannel(
            CHANNEL,
            context.getString(R.string.app_name),
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
}
