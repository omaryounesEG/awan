# Awan — Native setup (Android)

Everything the app needs from the platform, and **why** it is hand-written
instead of pulled from a package.

---

## 1. Why `geolocator` is not used

The Step-1 dependency list asked for `geolocator`. It cannot be built on this
toolchain. A clean, isolated probe was run (`flutter create` + `flutter pub add
geolocator …` + `flutter build apk --debug`):

```
2: Task failed with an exception.
* What went wrong:
A problem occurred configuring project ':geolocator_android'.
> Failed to notify project evaluation listener.
   > Cannot invoke method substring() on null object
   > compileSdkVersion is not specified. Please add it to build.gradle
BUILD FAILED in 3m 59s
```

The same failure occurs at `geolocator 14.0.2`. The Android module reads the
Flutter extension properties that a library module does not receive under AGP 8.1
+ Gradle 8.3, and the only "fix" would be patching the shared pub cache — not
reproducible on another machine, so not acceptable.

**Decision:** `geolocator` was removed from `pubspec.yaml`; the fix is read from
`LocationManager` over a 20-line method channel (below). The behaviour is
equivalent for prayer times: last-known fix first (instant), then one bounded
single update with a 6-second ceiling, and no background updates ever.

---

## 2. Channel `awan/location`

| Method | Arguments | Returns | Notes |
| --- | --- | --- | --- |
| `hasPermission` | — | `bool` | Fine **or** coarse granted |
| `requestPermission` | — | `bool` | Delivers the answer from `onRequestPermissionsResult` |
| `isServiceEnabled` | — | `bool` | `LocationManager.isLocationEnabled` |
| `openLocationSettings` | — | `null` | Opens the system location screen |
| `getLocation` | — | `Map` or `null` | `{latitude, longitude, accuracy}`; `null` = no fix within 6 s |
| `timeZoneId` | — | `String` | `TimeZone.getDefault().id` — the IANA id `zonedSchedule` needs |

**Why `timeZoneId` matters:** `flutter_local_notifications` schedules in a
`TZDateTime`. If `timezone`'s local location were left at UTC, every adhan would
fire shifted by the device offset (three hours in Cairo). `DateTime.now()
.timeZoneName` only yields an abbreviation (`EET`, `EST`) that is often absent
from the IANA database, so the real zone id is read natively.

## 3. Channel `awan/ringer`

| Method | Arguments | Returns | Notes |
| --- | --- | --- | --- |
| `hasPolicyAccess` | — | `bool` | Do-Not-Disturb access (required to silence on API 23+) |
| `openPolicySettings` | — | `null` | `ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS` |
| `hasExactAlarmAccess` | — | `bool` | `canScheduleExactAlarms()` on API 31+ |
| `setSilentNow` | `{silent}` | `bool` | Immediate manual toggle |
| `currentMode` | — | `String` | `normal` \| `silent` \| `vibrate` |
| `scheduleWindows` | `{windows: [{start, end}]}` | `int` | Exact alarms; returns how many were armed |
| `cancelWindows` | — | `null` | Cancels the whole reserved id range |

Silence windows are performed by **`AlarmManager` → `RingerAlarmReceiver`**, not
by a Dart isolate: the phone falls silent for the adhan even when the app was
killed, and nothing of ours stays alive to consume battery.

Alarm ids for silence windows live in `900000..900499` — disjoint from the adhan
notification ids (`100000+`), so cancelling one set can never touch the other.

---

## 4. Manifest

Permissions, and why each one is there, are annotated inline in
`android/app/src/main/AndroidManifest.xml`:

* `INTERNET`, `ACCESS_NETWORK_STATE` — mosque lookup + optional verification only;
* `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` — never in the background;
* `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`,
  `VIBRATE`, `WAKE_LOCK` — the adhan;
* `ACCESS_NOTIFICATION_POLICY` — silence automation;
* `POST_NOTIFICATIONS` — Android 13+ runtime permission.

Two receivers are declared explicitly: `ScheduledNotificationReceiver` and
`ScheduledNotificationBootReceiver` (without the second one, scheduled adhans do
**not** survive a reboot).

## 5. Gradle

* `android/app/build.gradle`
  * `minSdk = 23` — floor for the native channels, and no permission shims;
  * `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4` — the
    notifications plugin uses `java.time` for scheduled alarms, unavailable
    before API 26.
* `android/build.gradle`
  * a `subprojects { afterEvaluate { … } }` block that supplies a missing
    `namespace` (AGP 8 requirement) to plugins built for older AGP, using the
    plugin's own group id. Applied in the project's own gradle files so the build
    stays reproducible from a clean clone.
