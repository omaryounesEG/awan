package com.saip.awan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fires exactly twenty minutes after an adhan and hands the card back to the
 * next prayer: the count-up has done its job by then, and a clock that keeps
 * counting for hours says nothing a reader needs.
 *
 * The wording travels in the intent, so this receiver holds no state and works
 * after a reboot, with the app never having been started that day.
 */
class CardSwitchReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return
        if (intent?.action != ACTION_SWITCH) return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: return
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val at = intent.getLongExtra(EXTRA_WHEN, System.currentTimeMillis())
        PrayerCard.post(context, title, body, at, countUp = false)
    }

    companion object {
        const val ACTION_SWITCH = "com.awan.app.SWITCH_CARD"
        const val EXTRA_TITLE = "awan.card.next.title"
        const val EXTRA_BODY = "awan.card.next.body"
        const val EXTRA_WHEN = "awan.card.next.when"
    }
}
