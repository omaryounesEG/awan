import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/constants/app_colors.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/prayer_engine/domain/entities/qibla_direction.dart';
import 'package:awan/features/prayer_engine/domain/usecases/solar_position.dart';
import 'package:awan/features/prayer_engine/presentation/providers/qibla_providers.dart';
import 'package:awan/features/prayer_engine/presentation/widgets/qibla_compass.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The qibla, with the live compass when the hardware has one.
///
/// Three honest states instead of one optimistic one:
///
/// * **bearing only** — pure trigonometry from the saved coordinates, always
///   available, in airplane mode, on the first frame (the dial is drawn north-up
///   and labelled as such rather than pretending to know which way you face);
/// * **live** — the native heading stream, corrected from magnetic to true north,
///   drives the card and the +/-2 degrees alignment feedback;
/// * **no sensor** — one sentence, no spinning dial, no invented heading.
///
/// The heading stream is `autoDispose`: leaving this screen cancels it, and the
/// native `onCancel` powers the sensor down — visible as a `[AwanSensors]` line in
/// logcat, not just a claim in a comment.
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final QiblaReading reading = ref.watch(qiblaProvider);
    final String city = ui.isArabic
        ? ref.watch(settingsProvider).cityAr
        : ref.watch(settingsProvider).cityEn;

    final double scale = ui.isElderlyMode ? 1.25 : 1.0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.qibla)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (city.isNotEmpty)
                Center(
                  child: Text(
                    city,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              SizedBox(height: 8.h),
              if (reading.direction == null)
                _Message(text: l10n.locationUnavailable)
              else ...<Widget>[
                QiblaCompass(
                  bearing: reading.direction!.bearingDegrees,
                  heading: reading.heading,
                  isAligned: reading.isAligned,
                  scale: scale,
                  semanticsLabel: l10n.qibla,
                ),
                SizedBox(height: 16.h),
                _StatusLine(reading: reading, library: l10n),
                SizedBox(height: 14.h),
                _Metrics(
                  reading: reading,
                  library: l10n,
                  isElderly: ui.isElderlyMode,
                ),
                SizedBox(height: 14.h),
                _SunCard(
                  bearing: reading.direction!.bearingDegrees,
                  latitude: ref.watch(settingsProvider).latitude,
                  longitude: ref.watch(settingsProvider).longitude,
                  library: l10n,
                  isElderly: ui.isElderlyMode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The one sentence the user actually needs, in the calmest possible voice.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.reading, required this.library});

  final QiblaReading reading;
  final AppLocalizations library;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ok = isDark ? AppColors.oliveDark : AppColors.oliveLight;

    late final String text;
    late final Color colour;
    late final IconData icon;

    if (reading.sensorError != null) {
      text = failureText(library, reading.sensorError!);
      colour = Theme.of(context).colorScheme.onSurfaceVariant;
      icon = Icons.explore_off_outlined;
    } else if (reading.isAligned) {
      text = library.qiblaAligned;
      colour = ok;
      icon = Icons.check_circle_outline;
    } else if (reading.heading == null) {
      text = library.compassCalibration;
      colour = Theme.of(context).colorScheme.onSurfaceVariant;
      icon = Icons.screen_rotation_outlined;
    } else {
      final double delta = Geo.shortestAngleDelta(
        reading.direction!.bearingDegrees,
        reading.heading!,
      );
      final int degrees = delta.abs().round();
      text = delta >= 0
          ? library.turnRight(degrees)
          : library.turnLeft(degrees);
      colour = Theme.of(context).colorScheme.primary;
      icon = delta >= 0 ? Icons.turn_right : Icons.turn_left;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: colour, size: 22.sp),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colour, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Bearing, distance to Makkah and the magnetic correction — small and honest.
class _Metrics extends StatelessWidget {
  const _Metrics({
    required this.reading,
    required this.library,
    required this.isElderly,
  });

  final QiblaReading reading;
  final AppLocalizations library;
  final bool isElderly;

  @override
  Widget build(BuildContext context) {
    final QiblaDirection direction = reading.direction!;
    final TextTheme text = Theme.of(context).textTheme;
    final double? declination = reading.declination;

    return Column(
      children: <Widget>[
        Text(
          library.qiblaDegrees(direction.bearingDegrees.toStringAsFixed(1)),
          style: (isElderly ? text.headlineMedium : text.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        Text(
          library.toMakkah(direction.distanceKm.round().toString()),
          style: text.bodyMedium,
        ),
        SizedBox(height: 4.h),
        Text(
          reading.heading == null
              ? library.bearingFromTrueNorth
              : library.liveCompass,
          style: text.bodySmall,
        ),
        if (declination != null && declination.abs() > 0.05) ...<Widget>[
          SizedBox(height: 4.h),
          Text(
            library.declinationCorrection(declination.toStringAsFixed(1)),
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Text(text, textAlign: TextAlign.center),
      );
}


/// 「محاذاة الشمس」 — the qibla from astronomy, not from a magnetometer.
///
/// The PDF's point: a compass in a car, near metal, or on a cheap phone can be
/// ten degrees out and never say so. The sun cannot lie, and its bearing is
/// computed here from the clock and the coordinates alone — no network, no
/// sensor, nothing to calibrate. When the sun stands within a few degrees of the
/// qibla, the user's own shadow becomes the pointer.
class _SunCard extends StatefulWidget {
  const _SunCard({
    required this.bearing,
    required this.latitude,
    required this.longitude,
    required this.library,
    required this.isElderly,
  });

  final double bearing;
  final double latitude;
  final double longitude;
  final AppLocalizations library;
  final bool isElderly;

  @override
  State<_SunCard> createState() => _SunCardState();
}

class _SunCardState extends State<_SunCard> {
  Timer? _ticker;
  SolarPosition _sun = const SolarPositionCalculator()(
    instant: DateTime.now(),
    latitude: 30.0444,
    longitude: 31.2357,
  );

  @override
  void initState() {
    super.initState();
    _refresh();
    // One tick a minute: the sun moves 0.25° a minute, and a timer that only
    // exists while this screen is open costs nothing when it closes.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refresh() {
    final SolarPosition next = const SolarPositionCalculator()(
      instant: DateTime.now(),
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    if (mounted) setState(() => _sun = next);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double offset = _sun.offsetFrom(widget.bearing);
    final bool near = _sun.isUp && offset <= 12;
    final bool now = _sun.isUp && offset <= 4;

    final String sentence = !_sun.isUp
        ? widget.library.sunAlignNight
        : now
            ? widget.library.sunAlignNow
            : near
                ? widget.library.sunAlignNear
                : widget.library.sunAlignFar(offset.round().toString());

    final Color tint = now
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.wb_sunny_outlined, color: tint, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.library.sunAlignTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: widget.isElderly ? 15.sp : 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  sentence,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: widget.isElderly ? 18.sp : 15.sp,
                    height: 1.5,
                    color: tint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
