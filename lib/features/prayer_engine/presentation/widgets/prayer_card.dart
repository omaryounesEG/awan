import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Where a row sits relative to *now*.
///
/// The dashboard computes this once per row and passes it down, so the card
/// itself stays a pure function of its inputs (no provider reads, no clock
/// reads) and can be rendered in a golden test without a running timer.
enum PrayerCardStatus {
  /// Already happened today.
  past,

  /// The window we are inside right now (fajr → sunrise → … → isha).
  current,

  /// The next prayer to come — the one the hero card counts down to.
  next,

  /// Later today.
  upcoming,

  /// Sunrise is an astronomical marker, not a prayer: it is shown, but muted.
  marker,
}

/// One row of the day's timetable.
///
/// States are expressed with *weight and colour*, never with a badge a user has
/// to decode:
///
/// * `past` fades to 55% opacity — present but clearly behind us;
/// * `current` keeps full contrast and gets the primary-coloured label;
/// * `next` is bold, tinted, and outlined, so it is findable in one glance;
/// * `marker` uses the outline colour and a different glyph.
///
/// [large] is the elderly variant: the same information, but the row grows to a
/// comfortable touch target (the text itself is already scaled by the shell's
/// `MediaQuery.withClampedTextScaling`).
class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.name,
    required this.at,
    required this.localeCode,
    required this.status,
    this.large = false,
  });

  final PrayerName name;
  final DateTime at;
  final String localeCode;
  final PrayerCardStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final bool isNext = status == PrayerCardStatus.next;
    final bool isCurrent = status == PrayerCardStatus.current;
    final bool isMarker = status == PrayerCardStatus.marker;
    final bool isPast = status == PrayerCardStatus.past;

    // Elderly mode wants maximum contrast, so past rows are only barely dimmed
    // there rather than dropped to a ghost.
    final double opacity = isPast ? (large ? 0.78 : 0.55) : 1;

    final TextStyle? labelStyle = (large
            ? theme.textTheme.headlineSmall
            : theme.textTheme.titleMedium)
        ?.copyWith(
      fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
      color: isMarker
          ? scheme.outline
          : (isCurrent ? scheme.primary : scheme.onSurface),
    );

    final TextStyle? clockStyle = (large
            ? theme.textTheme.headlineSmall
            : theme.textTheme.titleMedium)
        ?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      color: isMarker ? scheme.outline : scheme.onSurface,
    );

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: isNext ? scheme.primaryContainer.withOpacity(0.45) : null,
          border: Border(
            // A thin outline only for the next prayer: one accent, one meaning.
            top: isNext ? BorderSide(color: scheme.primary, width: 1.2) : BorderSide.none,
            bottom: BorderSide(color: theme.dividerColor, width: 0.6),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: large ? 20.w : 14.w,
          vertical: large ? 20.h : 11.h,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isMarker ? Icons.wb_twilight : Icons.mosque_outlined,
              size: large ? 30.sp : 19.sp,
              color: isMarker ? scheme.outline : scheme.primary,
            ),
            SizedBox(width: large ? 16.w : 12.w),
            Expanded(
              child: Text(
                prayerLabel(l10n, name),
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNext || isCurrent)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  isNext ? l10n.nextPrayer : l10n.prayerNow,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(formatClock(at, localeCode), style: clockStyle),
          ],
        ),
      ),
    );
  }
}
