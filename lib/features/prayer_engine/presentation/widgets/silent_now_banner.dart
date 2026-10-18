import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/constants/app_colors.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Says out loud what the auto-silent feature just did to the phone.
///
/// The automation is performed by `AlarmManager` while the app is closed, so
/// the reader gets no feedback at all: the phone simply stops ringing for half
/// an hour and nothing on screen ever mentions it. This banner is that
/// missing sentence — *the phone is silent now, because of prayer time, and it
/// will come back at 14:35* — with the one action that makes it stop early.
///
/// It reads the same settings the scheduler wrote, so it cannot disagree with
/// the alarms: both are derived from the prayer times and the per-prayer
/// silence window.
class SilentNowBanner extends ConsumerStatefulWidget {
  const SilentNowBanner({super.key});

  @override
  ConsumerState<SilentNowBanner> createState() => _SilentNowBannerState();
}

class _SilentNowBannerState extends ConsumerState<SilentNowBanner> {
  Timer? _ticker;
  String? _ringer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The ringer is OS state the app cannot be notified about; asking twice a
    // minute is cheap and keeps a system-side change visible here.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final String mode = await ref.read(audioManagerServiceProvider).currentMode();
    if (!mounted) return;
    if (mode != _ringer) setState(() => _ringer = mode);
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    if (!settings.silentModeEnabled && settings.jumuahSilentMinutes == 0) {
      return const SizedBox.shrink();
    }

    final DayPrayerTimes? day = ref
        .watch(dayPrayerTimesProvider(ref.watch(todayProvider)))
        .valueOrNull;
    if (day == null) return const SizedBox.shrink();

    final DateTime now = ref.watch(nowProvider);
    final DateTime? until = _windowEnd(now, day, settings);
    if (until == null) return const SizedBox.shrink();
    // Silent, vibrate or normal: only claim silence when the phone really is
    // silent and it is our window that made it so.
    if (_ringer != 'silent') return const SizedBox.shrink();

    final AppLocalizations l10n = AppLocalizations.of(context);
    final String clock = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(until));

    return Material(
      color: AppColors.radar.withOpacity(0.12),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 8.w, 10.h),
        child: Row(
          children: <Widget>[
            Icon(Icons.volume_off_outlined, size: 20.sp, color: AppColors.radar),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.silentNowTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    l10n.silentNowBody(clock),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await ref.read(audioManagerServiceProvider).setNormalMode();
                      await _refresh();
                      if (!context.mounted) return;
                      setState(() => _busy = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.silentNowRestored)),
                      );
                    },
              child: Text(l10n.silentNowRestore),
            ),
          ],
        ),
      ),
    );
  }

  /// The end of the silence window `now` falls inside, or null.
  DateTime? _windowEnd(DateTime now, DayPrayerTimes day, AppSettings s) {
    for (final PrayerName prayer in PrayerName.obligatory) {
      if (!s.isPrayerEnabled(prayer.key)) continue;
      final DateTime at = day.timeOf(prayer);
      final int starts = s.adhanPreferences.silentStartFor(prayer.key);
      final int lasts = s.adhanPreferences.silentDurationFor(prayer.key);
      if (lasts <= 0) continue;
      final DateTime from = at.add(Duration(minutes: starts));
      final DateTime to = from.add(Duration(minutes: lasts));
      if (!now.isBefore(from) && now.isBefore(to)) return to;
    }

    if (day.date.weekday == DateTime.friday && s.fridayModeEnabled) {
      final (int, int) start = _minutes(s.fridayStart);
      final (int, int) end = _minutes(s.fridayEnd);
      final DateTime from = DateTime(
          day.date.year, day.date.month, day.date.day, start.$1, start.$2);
      final DateTime to = DateTime(
          day.date.year, day.date.month, day.date.day, end.$1, end.$2);
      if (!now.isBefore(from) && now.isBefore(to)) return to;
    }
    return null;
  }

  (int, int) _minutes(String clock) {
    final List<String> parts = clock.split(':');
    final int hour = int.tryParse(parts.first) ?? 0;
    final int minute =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return (hour, minute);
  }
}
