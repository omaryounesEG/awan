package com.saip.awan

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Touching the next-prayer card takes it away.
 *
 * The card deliberately has no activity behind it: a reader who taps a clock
 * reminder wants the reminder gone, not an app opened over whatever they were
 * doing. Swiping it away works too — the card is not `ongoing`.
 */
class CardDismissReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return
        val id = intent?.getIntExtra(EXTRA_ID, MainActivity.CARD_ID) ?: MainActivity.CARD_ID
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id)
    }

    companion object {
        const val ACTION_DISMISS = "com.awan.app.DISMISS_CARD"
        const val EXTRA_ID = "awan.card.id"
    }
}
