# Step 4 — The Dashboard & Elderly Mode

Status: **implemented and verified** — `flutter analyze`: 0 issues; `flutter test`:
15/15; debug APK built, installed and inspected on an emulator
(`docs/screens/12_elderly_ar_final.png`, `13_standard_dark.png`,
`14_standard_light.png`).

---

## Files

| Step-4 file | Type |
| --- | --- |
| `features/prayer_engine/presentation/screens/dashboard_screen.dart` | `DashboardScreen` + `_StandardDashboard` + `_DashboardError` |
| `features/prayer_engine/presentation/screens/elderly_dashboard_view.dart` | `ElderlyDashboardView`, `_HugeNextPrayerCard`, `ElderlyActionCard` |
| `features/prayer_engine/presentation/widgets/prayer_card.dart` | `PrayerCard` + `PrayerCardStatus {past, current, next, upcoming, marker}` |
| `features/settings/presentation/widgets/quick_settings_actions.dart` | the language / theme / elderly toggles, shared by the dashboard bar |
| `features/quran_tafseer/presentation/screens/quran_placeholder_screen.dart` | the honest "later step" target for the Quran card |

Reorganisation that came with it (the dashboard now *is* the timetable tab):

* `home/presentation/screens/home_screen.dart` → replaced by `DashboardScreen`;
* `prayer_tile.dart` → `PrayerCard` (same widget, now state-driven and reusable);
* `hijri_header.dart`, `quick_actions.dart` → moved from `features/home/` to
  `features/prayer_engine/presentation/widgets/` (they are dashboard widgets;
  `features/home/` no longer exists).

## Task-by-task

**Task 1 — one screen, two layouts.** `DashboardScreen` watches
`prayerControllerProvider` (Step 3) for the day and `appSettingsProvider` for
`isElderlyMode`; `today.when(...)` is the only gate, and the elderly branch is a
different widget tree rather than the same tree with bigger numbers.

**Task 2 — standard.** Hero card (next prayer, name, time, a one-second
countdown, and a quiet progress arc from the previous prayer), section header
with the Gregorian date, the six rows in one `Card`, the location line, the
shortcut grid. The bar carries the three toggles.

**Task 3 — elderly.** The timeline, the month grid, the location line and the
shortcut grid are **removed**, not shrunk: what remains is the next-prayer card
(name at `displaySmall`, time at `headlineMedium`, remaining), then three
full-width 96-high targets — القرآن / السبحة / الإعدادات — and the dates last.
Colours stay `onSurface`/`onPrimaryContainer` on the sand or OLED background
(maximum contrast), and the shell has already clamped the text scale to the
elderly value, so these `.sp` sizes are a base the user's own scale stacks on.

**Task 4 — `PrayerCard`.** A pure function of `(name, at, localeCode, status,
large)` — no provider reads, no clock reads, so it is safe in a golden test. The
dashboard computes the status:

* `past` → 55% opacity (78% in elderly mode, which needs contrast more than it
  needs depth cues);
* `current` → full contrast, primary-coloured label, "now" badge;
* `next` → bold, tinted row, thin primary outline top and bottom;
* `marker` (sunrise) → outline colour, different glyph.

## Decisions worth flagging

* **One timer, not two.** `PrayerController.setForeground(bool)` forwards to the
  single countdown ticker behind `nextPrayerProvider`, which the shell starts on
  `resumed` and stops on `paused`/`inactive`. Per-second work is a pure
  re-derivation (`entity.at(now)` / ticker state) — never `adhan_dart`, never
  disk, never network.
* **The Quran card is honest.** The reader is a later step, so the card opens
  `QuranPlaceholderScreen`, which says so, instead of a dead end or an empty
  screen.
* **The toggles are one widget in two places** (`QuickSettingsActions`), so the
  shell and the dashboard cannot drift.
* **RTL-aware affordances.** `chevron_left`/`chevron_right` do not mirror
  automatically; the elderly card picks by `Directionality`, so the arrow points
  the way the layout flows in both languages.

## Verified on the emulator

* Arabic + light (sand) — hero, current row (`الظهر`), next row (`العصر`, tinted),
  faded past rows, muted sunrise, shortcut grid.
* Arabic + OLED dark — same screen, halation-free.
* Arabic + elderly — three cards, huge type, nav bar showing only the selected
  label, and the floating "إيقافه" escape hatch.
* Toggling elderly from the app bar and from the floating button switches the
  layout within one frame, both directions, without touching the engine.
