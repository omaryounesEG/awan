# Step 3 — The Hybrid Prayer Engine (Domain & Data & State)

Status: **implemented and verified** — `flutter analyze`: 0 issues; `flutter test`:
15/15; debug APK built and run on an emulator (screenshots in `docs/screens/`).

---

## Files (the names the step asked for)

| Step-3 file | Type |
| --- | --- |
| `domain/entities/prayer_times_entity.dart` | `PrayerTimesEntity` — date + fajr/sunrise/dhuhr/asr/maghrib/isha + `currentPrayer`/`nextPrayer`, `Equatable` |
| `domain/usecases/get_offline_prayer_times.dart` | `GetOfflinePrayerTimes` + `OfflinePrayerParams`, returns `Either<Failure, PrayerTimesEntity>` |
| `domain/repositories/prayer_repository.dart` | `getDailyPrayers(double lat, double lng, DateTime date)` added to the existing abstract contract |
| `data/repositories/prayer_repository_impl.dart` | implements it, writes the day to the Isar cache, passes `Left` straight through |
| `presentation/providers/prayer_provider.dart` | `@riverpod PrayerController` → `AsyncValue<PrayerTimesEntity>`, foreground-only countdown |

Supporting files that already existed (Step 1/2 work) and are reused rather than
duplicated:

* `domain/usecases/calculate_prayer_times.dart` — the **single** `adhan_dart` call
  site (`Coordinates`, `CalculationMethod`, `PrayerTimes`). `GetOfflinePrayerTimes`
  is the Clean-Architecture contract in front of it, so there is exactly one
  arithmetic core and no chance of the two drifting apart.
* `data/datasources/prayer_local_datasource.dart` — Isar cache + month computation.
* `data/datasources/aladhan_remote_datasource.dart` — verification only, never
  used for display.

## Design notes

**Why both `DayPrayerTimes` and `PrayerTimesEntity`?** The first is the engine's
*data* shape (it also carries the calculation parameters and the last verification
result, which the cache and the scheduler need); the second is the *domain* shape
with named fields, so the UI writes `entity.fajr` and cannot typo a map key into a
silent null. They convert through `PrayerTimesEntity.fromDay` / `.toDay()`.

**Infallible but still `Either`.** Offline arithmetic cannot really fail, but the
contract must: an out-of-range latitude (or a date outside 1900–2200) returns
`Left(ServerFailure(...))` instead of throwing across a boundary. The presentation
layer converts it once, at the edge, into `AsyncValue.error`.

**No polling.** `PrayerController` holds one `Timer.periodic(1s)` that **only**
exists while the app is in the foreground (`setForeground(true/false)`, driven by
the shell's `WidgetsBindingObserver`). Each tick re-derives current/next from the
entity already in memory (`entity.at(now)`) — no recalculation, no disk, no
network, no allocation of new `DateTime`s.

**A pitfall worth recording:** the provider family key must be *stable*. Passing
`DateTime.now()` (which carries seconds) into a `family` provider recreates it on
every rebuild — with a one-second ticker on screen that is an infinite
`loading` loop. `todayProvider` (local midnight) is the only thing that may be
passed as a date key.

## Verified

```bash
flutter analyze      # No issues found
flutter test         # 15/15 (domain order, adjustments, madhab, month, qibla,
                     #        Either contract, current/next derivation, equality)
flutter build apk --debug
```

Screenshots (`docs/screens/`): Arabic RTL dashboard, English LTR + OLED dark,
settings screen, elderly mode (AR and EN).
