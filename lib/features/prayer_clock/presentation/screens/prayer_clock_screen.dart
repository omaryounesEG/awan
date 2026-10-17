import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/l10n/app_localizations.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/utils/date_x.dart';
import 'package:awan/features/prayer_clock/domain/entities/clock_face.dart';
import 'package:awan/features/prayer_clock/presentation/widgets/clock_digits.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';

/// The wall clock the reader actually reads: the time, the countdown to the next
/// adhan, the prayer it belongs to, and the hijri date — in that order, which is
/// the order the eye asks for them.
///
/// It is also what the lock screen shows: the app can draw this over the keyguard
/// (`MainActivity` is `showWhenLocked`), and Android does not let a third-party
/// app replace the system's own lock-screen clock, so a full-screen screen of
/// ours is the honest maximum.
class PrayerClockScreen extends ConsumerStatefulWidget {
  const PrayerClockScreen({
    super.key,
    this.embedded = false,
  });

  /// Embedded in the app's navigator (a normal screen) vs. shown full-screen over
  /// the keyguard: only the lock-screen case hides the chrome.
  final bool embedded;


  @override
  ConsumerState<PrayerClockScreen> createState() => _PrayerClockScreenState();
}

class _PrayerClockScreenState extends ConsumerState<PrayerClockScreen> {
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _keepScreenOn(true);
  }

  @override
  void dispose() {
    _keepScreenOn(false);
    super.dispose();
  }

  /// A clock that dims out while you are looking at it is not a clock. The flag
  /// lives on the window, so nothing of ours stays awake to hold it.
  void _keepScreenOn(bool on) {
    unawaited(ref.read(clockOverlayServiceProvider).keepScreenOn(on));
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    final AppLocalizations l10n = context.l10n;
    final DateTime now = ref.watch(nowProvider);
    final NextPrayerState next = ref.watch(nextPrayerProvider);
    final ClockFace face = ClockFace.fromWire(settings.prayerClockFace);
    final bool night = settings.prayerClockNight;
    final ClockFaceStyle style = clockFaceStyle(face, night: night);

    final Color background =
        night ? const Color(0xFF05070B) : const Color(0xFFF7F8FA);
    final Color foreground =
        night ? const Color(0xFFE8EAF0) : const Color(0xFF141821);

    final NextPrayer? prayer = next.next;
    // Over the lock screen this is a clock, not a settings page: the face chooser
    // belongs in the app, where there is room to read it.
    final bool chrome = _chromeVisible;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _chromeVisible = !_chromeVisible),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // 1) the time — the biggest thing here, and the only element the
                // face colours.
                Flexible(
                  flex: 4,
                  child: FittedBox(
                    // Contain, not scaleDown: the digits are vector art, and the
                    // clock is meant to be the biggest thing on this screen.
                    fit: BoxFit.contain,
                    child: ClockDigits(
                      time: now,
                      face: face,
                      night: night,
                      scale: 1.0,
                    ),
                  ),
                ),
                // 2) what is left of the wait, in the face's *other* colour: two
                // large numbers in one hue read as one blur.
                Flexible(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          countdownLabel(next.remaining, settings.localeCode),
                          style: TextStyle(
                            color: style.accent,
                            fontSize: 46,
                            fontWeight: FontWeight.w300,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Text(
                        '${l10n.remaining} · ${l10n.nextPrayer}',
                        style: TextStyle(
                          color: style.accent.withOpacity(0.75),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3) which prayer
                if (prayer != null)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${prayerLabel(l10n, prayer.name)} · '
                        '${formatClock(prayer.at, settings.localeCode)}',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                // 4) the hijri date (gregorian under it, quietly)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          hijriLabel(
                            now,
                            localeCode: settings.localeCode,
                            offsetDays: settings.hijriOffsetDays,
                          ),
                          style: TextStyle(
                            color: foreground.withOpacity(0.85),
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          gregorianLabel(now, settings.localeCode),
                          style: TextStyle(
                            color: foreground.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (chrome)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _FacePicker(
                        current: face,
                        night: night,
                        onFace: (ClockFace value) => ref
                            .read(settingsControllerProvider.notifier)
                            .setPrayerClockFace(value),
                        onNight: (bool value) => ref
                            .read(settingsControllerProvider.notifier)
                            .setPrayerClockNight(value),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The face chooser: four swatches and a day/night switch, moved off the screen
/// with a tap so the clock itself stays bare.
class _FacePicker extends StatelessWidget {
  const _FacePicker({
    required this.current,
    required this.night,
    required this.onFace,
    required this.onNight,
  });

  final ClockFace current;
  final bool night;
  final ValueChanged<ClockFace> onFace;
  final ValueChanged<bool> onNight;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        for (final ClockFace face in ClockFace.values)
          ChoiceChip(
            label: Text(_label(l10n, face)),
            selected: face == current,
            onSelected: (bool _) => onFace(face),
          ),
        FilterChip(
          avatar: Icon(
            night ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 16,
          ),
          label: Text(l10n.clockNight),
          selected: night,
          onSelected: onNight,
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n, ClockFace face) => switch (face) {
        ClockFace.segment => l10n.clockFaceSegment,
        ClockFace.white => l10n.clockFaceWhite,
        ClockFace.red => l10n.clockFaceRed,
        ClockFace.green => l10n.clockFaceGreen,
      };
}
