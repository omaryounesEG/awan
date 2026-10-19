package com.saip.awan

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioManager
import android.util.Log

/**
 * Fires at the start and the end of a silence window.
 *
 * The alarm is delivered by `AlarmManager` (exact, allowed in Doze), so the app
 * does not have to be running, or even resident, for the phone to fall silent
 * for the adhan.
 *
 * **The phone belongs to its owner.** A silence that was already on when the
 * window opened — because the user set it by hand, or keeps the phone on
 * vibrate — is never claimed and never undone: the app only restores a silence
 * it started itself, and only while the state it set is still in place. If the
 * state changed in the meantime, the user took over and the phone is left as
 * they left it.
 *
 * Two Android APIs are needed because neither covers every version: the legacy
 * ringer mode (still the honest way to say "silent", honoured up to API 34) and
 * the interruption filter / Do-Not-Disturb, which is the only switch a modern
 * (API 35+) build honours for an app that is not the default dialer. Each is
 * read back after writing, so "we did it" is only ever recorded when the phone
 * really changed state.
 *
 * The flags live in SharedPreferences because the mute and the unmute are
 * separate alarms, hours apart, and usually neither runs inside our process.
 */
class RingerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val moment = intent.getStringExtra(MainActivity.EXTRA_MODE) ?: return

        // The reader's own mosques, when they asked for them, are the gate on
        // *starting* a silence. Unsilencing is never gated: a phone must always
        // be able to come back to its owner's volume.
        if (moment == MainActivity.MODE_SILENT && MosqueFence.isEnabled(context)) {
            val pending = goAsync()
            Thread {
                try {
                    val gate = MosqueFence.checkNow(context)
                    if (gate.inside == false) {
                        Log.i(
                            TAG,
                            "silence skipped: outside «${gate.name}» " +
                                "(${"%.0f".format(gate.distance ?: 0.0)}m away)"
                        )
                        return@Thread
                    }
                    Log.i(TAG, "mosque gate ${if (gate.inside == true) "inside" else "unknown"} (${gate.reason})")
                    apply(context, moment)
                } finally {
                    pending.finish()
                }
            }.start()
            return
        }

        apply(context, moment)
    }

    private fun apply(context: Context, moment: String) {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notifications =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        try {
            if (moment == MainActivity.MODE_SILENT) {
                silence(audio, notifications, prefs)
            } else {
                restore(audio, notifications, prefs)
            }
        } catch (_: SecurityException) {
            // Do-Not-Disturb access was revoked after the window was armed.
            Log.i(TAG, "no policy access")
        }
    }

    private fun silence(
        audio: AudioManager,
        notifications: NotificationManager,
        prefs: SharedPreferences
    ) {
        val ringerBefore = audio.ringerMode
        val filterBefore = notifications.currentInterruptionFilter
        val alreadyQuiet = ringerBefore != AudioManager.RINGER_MODE_NORMAL ||
            (filterBefore != NotificationManager.INTERRUPTION_FILTER_ALL &&
                filterBefore != NotificationManager.INTERRUPTION_FILTER_UNKNOWN)
        if (alreadyQuiet) {
            // Quiet by the owner's hand: this window is not ours, touch nothing.
            prefs.edit().putBoolean(KEY_OURS, false).apply()
            Log.i(TAG, "silence skipped: already quiet (ringer=$ringerBefore, filter=$filterBefore)")
            return
        }

        // 1) The legacy ringer: the clearest "silent" where it still applies.
        audio.ringerMode = AudioManager.RINGER_MODE_SILENT
        if (audio.ringerMode == AudioManager.RINGER_MODE_SILENT) {
            prefs.edit()
                .putBoolean(KEY_OURS, true)
                .putBoolean(KEY_USED_FILTER, false)
                .putInt(KEY_RINGER_BEFORE, ringerBefore)
                .apply()
            Log.i(TAG, "silenced (ringer was $ringerBefore)")
            return
        }

        // 2) A modern build maps the ringer onto notification modes, so the
        // policy is the only switch left: "none" is Do-Not-Disturb, i.e. silent.
        notifications.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
        if (notifications.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE) {
            prefs.edit()
                .putBoolean(KEY_OURS, true)
                .putBoolean(KEY_USED_FILTER, true)
                .putInt(KEY_FILTER_BEFORE, filterBefore)
                .apply()
            Log.i(TAG, "silenced through the interruption filter (was $filterBefore)")
            return
        }

        prefs.edit().putBoolean(KEY_OURS, false).apply()
        Log.i(TAG, "silence failed: neither the ringer nor the filter would change")
    }

    private fun restore(
        audio: AudioManager,
        notifications: NotificationManager,
        prefs: SharedPreferences
    ) {
        val ours = prefs.getBoolean(KEY_OURS, false)
        val usedFilter = prefs.getBoolean(KEY_USED_FILTER, false)
        val ringerBefore = prefs.getInt(KEY_RINGER_BEFORE, AudioManager.RINGER_MODE_NORMAL)
        val filterBefore =
            prefs.getInt(KEY_FILTER_BEFORE, NotificationManager.INTERRUPTION_FILTER_ALL)
        // One window, one set of flags: clear them whatever the outcome, so the
        // next window starts from the truth again.
        prefs.edit().clear().apply()
        if (!ours) {
            Log.i(TAG, "unmute ignored: the quiet was the owner's (ringer=${audio.ringerMode})")
            return
        }

        if (usedFilter) {
            if (notifications.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE) {
                notifications.setInterruptionFilter(filterBefore)
                Log.i(TAG, "filter restored to $filterBefore")
            } else {
                Log.i(TAG, "unmute ignored: the owner changed the mode meanwhile")
            }
            return
        }

        if (audio.ringerMode == AudioManager.RINGER_MODE_SILENT) {
            audio.ringerMode = ringerBefore
            Log.i(TAG, "ringer restored to $ringerBefore")
        } else {
            Log.i(TAG, "unmute ignored: the owner changed the ringer meanwhile")
        }
    }

    companion object {
        /** Tag for the single log line each moment writes, so support can see it. */
        const val TAG = "AwanRinger"

        /** Shared with `MainActivity`, which can also hand the ringer back. */
        const val PREFS = "awan_ringer"
        const val KEY_OURS = "muted_by_app"
        const val KEY_USED_FILTER = "used_filter"
        const val KEY_RINGER_BEFORE = "ringer_before"
        const val KEY_FILTER_BEFORE = "filter_before"
    }
}
