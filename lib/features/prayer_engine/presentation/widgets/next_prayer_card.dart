import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/utils/date_x.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The hero card: the next prayer, how long is left, and a quiet progress arc
/// from the previous prayer to the next.
///
/// The countdown is driven by [nextPrayerProvider], which ticks once a second
/// **only while the app is in the foreground**; the arc recomputes from the
/// cached day times, so nothing here touches the network.
class NextPrayerCard extends ConsumerWidget {
  const NextPrayerCard({super.key, this.elderly = false});

  final bool elderly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final NextPrayerState state = ref.watch(nextPrayerProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final NextPrayer? next = state.next;
    if (state.loading || next == null) {
      return Card(
        child: SizedBox(
          height: elderly ? 190 : 150,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final double progress = _progress(ref, next);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(elderly ? 24 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(l10n.nextPrayer,
                    style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                Text(
                  formatClock(next.at, ui.localeCode),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: elderly ? 14 : 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        prayerLabel(l10n, next.name),
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: scheme.primary,
                                  fontSize: elderly ? 42 : null,
                                ),
                      ),
                      SizedBox(height: elderly ? 10 : 4),
                      Text(
                        state.isDue
                            ? l10n.prayerNow
                            : l10n.prayerIn(
                                countdownLabel(state.remaining, ui.localeCode),
                              ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: state.isDue ? scheme.secondary : null,
                              fontWeight: state.isDue
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: elderly ? 96 : 74,
                  height: elderly ? 96 : 74,
                  child: _ProgressArc(progress: progress, color: scheme.primary),
                ),
              ],
            ),
            if (next.previous != null) ...<Widget>[
              SizedBox(height: elderly ? 14 : 10),
              // An icon, not the «→» character: inside an Arabic paragraph the
              // shaper mirrors the arrow, so «الفجر → الظهر» was drawn pointing
              // backwards. Icons never mirror, and the Row follows the text
              // direction on its own — right-to-left reads الفجر، ثم السهم، ثم
              // الظهر; left-to-right keeps «Fajr → Dhuhr» as it was.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    prayerLabel(l10n, next.previous!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: elderly ? 8 : 6),
                    child: Icon(
                      Icons.arrow_forward,
                      size: elderly ? 18 : 13,
                      // arrow_forward is a mirroring icon, so in an RTL tree
                      // Flutter draws it as ←. Pinning it to LTR keeps the
                      // arrow the reader asked for: الفجر → الظهر, and leaves
                      // the English line untouched.
                      textDirection: TextDirection.ltr,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    prayerLabel(l10n, next.name),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 0 → just after the previous prayer, 1 → the next one has arrived.
  double _progress(WidgetRef ref, NextPrayer next) {
    final DateTime? from = _windowStart(ref, next);
    if (from == null) return 0;
    final int total = next.at.difference(from).inSeconds;
    if (total <= 0) return 0;
    final int done = DateTime.now().difference(from).inSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  DateTime? _windowStart(WidgetRef ref, NextPrayer next) {
    final DateTime today = ref.watch(todayProvider);
    final DayPrayerTimes? value =
        ref.watch(dayPrayerTimesProvider(today)).valueOrNull;
    if (value == null) return null;
    if (next.previous != null) return value.timeOf(next.previous!);
    // Before today's fajr, the window opened yesterday at isha.
    final DayPrayerTimes? previousValue = ref
        .watch(
          dayPrayerTimesProvider(today.subtract(const Duration(days: 1))),
        )
        .valueOrNull;
    return previousValue?.timeOf(PrayerName.isha);
  }
}

class _ProgressArc extends StatelessWidget {
  const _ProgressArc({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? _) => CustomPaint(
        painter: _ArcPainter(progress: value, color: color),
        child: Center(
          child: Text(
            '${(value * 100).round()}%',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 4;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.16);
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
