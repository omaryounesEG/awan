# Step 5 — Secure Local Notifications & Auto-Silent (zero-tracking)

Status: **implemented and verified on a device** — `flutter analyze`: 0 issues;
`flutter test`: 24/24; the adhan set was observed being armed, cancelled and
re-armed in Android's own alarm manager.

---

## Files

| Step-5 file | Type |
| --- | --- |
| `lib/core/services/notification_service.dart` | `NotificationService` — the only thing that talks to `flutter_local_notifications` |
| `lib/features/prayer_engine/domain/usecases/schedule_monthly_prayers.dart` | `ScheduleMonthlyPrayers` — the 30-day offline plan |
| `lib/features/prayer_engine/domain/entities/scheduled_adhan.dart` | `ScheduledAdhan`, `NotificationIds`, `AdhanTextBuilder` |
| `lib/features/prayer_engine/domain/repositories/adhan_scheduler_port.dart` | `AdhanSchedulerPort` — the domain's "hand it to the OS" contract |
| `lib/core/services/audio_manager_service.dart` | `AudioManagerService` — channel `com.awan.app/audio` |
| `lib/features/settings/presentation/screens/settings_screen.dart` | the `isAdhanEnabled` / `isAutoSilentEnabled` switches |
| `android/.../MainActivity.kt` + `RingerAlarmReceiver.kt` | `AudioManager` / `AlarmManager` side |

Layering is exactly as the step asked: **the service is in `core/`, the scheduling
logic is in the feature's `domain/`**, and the data layer only adapts between
them (`PrayerRepositoryImpl implements AdhanSchedulerPort`).

## Task-by-task

**Task 1 — FLN setup.** `AndroidInitializationSettings('@mipmap/ic_launcher')` +
`DarwinInitializationSettings`; permissions are requested explicitly
(`requestNotificationsPermission()` for Android 13+, `requestPermissions` for
iOS) plus exact-alarm access; three channels are created with
`Importance.max` / `Priority.max` and `AudioAttributesUsage.alarm` so the adhan
sounds like an alarm rather than a message, and does so with the app closed.

**Task 2 — the offline month.** `ScheduleMonthlyPrayers` loops 30 days, computes
each day with `adhan_dart` (no network, no cache lookup on the hot path), emits
exactly 5 notifications a day (150) — plus 150 quieter pre-adhan reminders if the
user asked for them — and hands the whole list over in one pass through
`AdhanSchedulerPort`. The class documents the zero-tracking guarantee: its only
two collaborators are the offline engine and the OS port, so nothing in it *can*
reach a socket.

**Task 3 — auto-silent.** `com.awan.app/audio` exposes `setSilentMode()`,
`setNormalMode()`, `hasPolicyAccess()`, `hasExactAlarmAccess()`, `scheduleWindows()`
and `cancelWindows()`; the mute/unmute instants are handed to `AlarmManager`
(`RingerAlarmReceiver`, ids in a reserved 900xxx space) and `ACCESS_NOTIFICATION_POLICY`
is declared in the manifest.

**Task 4 — the switches.** `isAdhanEnabled` (default `true`) and
`isAutoSilentEnabled` (default `false`) on `AppSettings`, wired so the switch *is*
the scheduler: on → request permission → arm the month; off → `cancelAll()`. A
third line shows the number of notifications the OS is actually holding, and a
`تحديث` button re-arms everything (needed after a location or method change).

## Decisions worth flagging

* **`workmanager` is not on the hot path** (the step suggested it as an option).
  A Dart background service for a silence window would be killed by aggressive
  OEMs and would cost battery; `AlarmManager` + a 30-line receiver does the same
  work with nothing kept alive. `workmanager` remains wired for the once-a-week
  Aladhan *verification* only.
* **The plan is one-shot, not periodic.** 150 exact alarms are registered once and
  forgotten; Android re-arms them across reboots. Nothing runs at prayer time.
* **Launch top-up.** A user who does not open the app for a month would run out,
  so every launch *counts* what is pending (one binder call) and re-arms only when
  fewer than 25 (a week) remain.
* **A switch that refuses rather than lies:** with the permission denied, the adhan
  switch stays off and says why; the auto-silent switch stays off if Do-Not-Disturb
  access is refused.

## A real bug this step found (and fixed)

The domain test asserts "30 distinct days". It failed with **29**: the plan used
`today.add(Duration(days: offset))`, and Egypt's DST ends inside the window, so one
"day" is 25 hours long — the next iteration landed on 23:00 of the *previous* date,
repeating a date and shifting every later instant by an hour.

Fixing that exposed a second, worse one in the engine: `adhan_dart` returns **UTC**
instants but does its own date arithmetic on the argument it is given. Handed a
*local* midnight belonging to the 25-hour day (2026-10-29), fajr and isha both came
back as `09:38Z` — a "fajr" at **12:38 local**, identical to isha. Handing the
library `DateTime.utc(y, m, d)` yields the correct `02:38Z` / `16:28Z`. Both are now
regression-locked in `test/prayer_dst_test.dart` (the whole of October 2026 is
asserted coherent, plus the wall-clock/physics split across the transition).

## Verified on the emulator

| What | Evidence |
| --- | --- |
| Fresh launch, no user action | settings shows **148** armed (150 − today's two already-passed prayers) |
| Switch OFF | count → **0**, snackbar «أُلغيت كل إشعارات الصلاة», `dumpsys alarm` **451 → 10** |
| Switch ON, permission not granted | Android dialog *"Allow Awan to send you notifications?"*; the switch stays off, and nothing is armed |
| Switch ON after **Allow** | `POST_NOTIFICATIONS: granted=true`, `dumpsys alarm` **→ 454**, count **148** |
| Reboot survival | the alarms are `RTC_WAKEUP` on `ScheduledNotificationReceiver`, re-armed by Android |

Screenshots: `docs/screens/18_topup_fresh.png`, `21_adhan_off.png`,
`22_adhan_on.png` (the system permission dialog), `23_adhan_on_granted.png`.
