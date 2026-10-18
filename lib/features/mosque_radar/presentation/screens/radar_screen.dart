import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

import 'package:awan/core/constants/app_colors.dart';
import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/location/app_location.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/core/utils/maps_launcher.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/features/mosque_radar/domain/entities/user_mosque.dart';
import 'package:awan/features/mosque_radar/presentation/providers/mosque_providers.dart';
import 'package:awan/features/mosque_radar/presentation/widgets/mosque_card.dart';
import 'package:awan/features/mosque_radar/presentation/widgets/radar_map.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Mosques within 2 km, on a map and in a list.
///
/// Two layouts, and the split is deliberate rather than cosmetic:
///
/// * **standard** — map (2 km circle + the five nearest) over a list of cards;
/// * **Elderly Mode** — no map widget at all. A map asks the user to pinch,
///   pan and read tiny pins; the brief's suggestion is exactly right, so the
///   screen collapses to the nearest mosque's name, its walking time, and one
///   very large button that hands the destination to the phone's maps app.
///
/// The map is only *one* of the two presentations of the same data: if it fails
/// to render (no key, no Play services, no tiles) the list is still complete.
class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final AsyncValue<List<MosqueEntity>> mosques =
        ref.watch(nearbyMosquesProvider);
    final AppLocation location = ref.watch(radarLocationProvider);
    final AppSettings settings = ref.watch(settingsProvider);
    // Automatic mode that has never answered still reports Cairo's coordinates;
    // listing Cairo's mosques as "nearby" is worse than saying we do not know.
    final bool known = !settings.locationIsDefault;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mosqueRadar),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.mosqueAddHere,
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: known
                ? () => _addMosqueHere(context, ref, location, l10n)
                : null,
          ),
          IconButton(
            tooltip: l10n.useMyLocation,
            icon: const Icon(Icons.my_location),
            onPressed: () => ref.read(locationActionProvider.notifier).detect(),
          ),
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(nearbyMosquesProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: !known
            ? _LocationUnknown(
                library: l10n,
                onDetect: () =>
                    ref.read(locationActionProvider.notifier).detect(),
              )
            : ui.isElderlyMode
            ? _ElderlyRadar(mosques: mosques, location: location, library: l10n)
            : _StandardRadar(
                mosques: mosques,
                location: location,
                library: l10n,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------- standard

class _StandardRadar extends ConsumerWidget {
  const _StandardRadar({
    required this.mosques,
    required this.location,
    required this.library,
  });

  final AsyncValue<List<MosqueEntity>> mosques;
  final AppLocation location;
  final AppLocalizations library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MosqueEntity>? list = mosques.valueOrNull;
    final LatLng center = LatLng(location.latitude, location.longitude);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 300.h,
          child: Stack(
            children: <Widget>[
              RadarMap(
                center: center,
                mosques: list ?? const <MosqueEntity>[],
                radiusMeters: AppConstants.mosqueRadiusMeters,
              ),
              if (mosques.isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x22000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _Body(
            mosques: mosques,
            location: location,
            library: library,
            scrollable: true,
          ),
        ),
      ],
    );
  }
}

/// Loading / error / empty / list — shared by both layouts.
class _Body extends ConsumerWidget {
  const _Body({
    required this.mosques,
    required this.location,
    required this.library,
    required this.scrollable,
  });

  final AsyncValue<List<MosqueEntity>> mosques;
  final AppLocation location;
  final AppLocalizations library;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? provider = ref.watch(mosqueRepositoryProvider).lastProvider;
    final bool hasKey = ref.watch(placesKeyConfiguredProvider);

    return mosques.when(
      loading: () => scrollable
          ? const SizedBox.shrink()
          : const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _Centered(
        icon: Icons.wifi_off_outlined,
        text: failureText(library, asFailure(error)),
        action: library.retry,
        onAction: () => ref.invalidate(nearbyMosquesProvider),
      ),
      data: (List<MosqueEntity> list) {
        if (list.isEmpty) {
          return _Centered(
            icon: Icons.mosque_outlined,
            text: library.noMosquesFound,
            action: library.retry,
            onAction: () => ref.invalidate(nearbyMosquesProvider),
          );
        }

        final List<Widget> rows = <Widget>[
          _SourceLine(
            provider: provider,
            hasKey: hasKey,
            location: location,
            library: library,
          ),
          for (final MosqueEntity mosque in list)
            MosqueCard(
              mosque: mosque,
              badge: mosque.provider == 'user' ? library.mosqueUserTag : null,
              onDelete: mosque.provider == 'user'
                  ? () => _removeMosque(context, ref, mosque, library)
                  : null,
              onTap: () => MapsLauncher.navigate(
                latitude: mosque.latitude,
                longitude: mosque.longitude,
                label: mosque.name,
              ),
            ),
        ];

        return scrollable
            ? ListView(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
                children: rows,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              );
      },
    );
  }
}

/// Which service answered, and the radius — the honest provenance line.
class _SourceLine extends StatelessWidget {
  const _SourceLine({
    required this.provider,
    required this.hasKey,
    required this.location,
    required this.library,
  });

  final String? provider;
  final bool hasKey;
  final AppLocation location;
  final AppLocalizations library;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String source = switch (provider) {
      'google' => library.dataFromGoogle,
      'cache' => library.dataFromCache,
      _ => library.dataFromOsm,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.place_outlined, size: 15.sp, color: AppColors.radar),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  '${location.label} • '
                  '${library.searchRadius((AppConstants.mosqueRadiusMeters / 1000).toStringAsFixed(0))}',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            source,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          // Only worth a line when the build has no Google key: it explains why
          // the map is an OpenStreetMap one, in one calm sentence.
          if (!hasKey) ...<Widget>[
            SizedBox(height: 4.h),
            Text(
              library.placesKeyMissing,
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ elderly

/// Elderly Mode: no map, no pins, no pinch-zoom. One name, one time, one button.
class _ElderlyRadar extends ConsumerWidget {
  const _ElderlyRadar({
    required this.mosques,
    required this.location,
    required this.library,
  });

  final AsyncValue<List<MosqueEntity>> mosques;
  final AppLocation location;
  final AppLocalizations library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return mosques.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _Centered(
        icon: Icons.wifi_off_outlined,
        text: failureText(library, asFailure(error)),
        action: library.retry,
        onAction: () => ref.invalidate(nearbyMosquesProvider),
      ),
      data: (List<MosqueEntity> list) {
        if (list.isEmpty) {
          return _Centered(
            icon: Icons.mosque_outlined,
            text: library.noMosquesFound,
            action: library.retry,
            onAction: () => ref.invalidate(nearbyMosquesProvider),
          );
        }

        final MosqueEntity nearest = list.first;
        final TextTheme text = Theme.of(context).textTheme;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                library.nearestMosque,
                textAlign: TextAlign.center,
                style: text.titleLarge,
              ),
              SizedBox(height: 10.h),
              Text(
                nearest.name,
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                library.walkingTime(
                  '${nearest.walkingMinutes} ${library.minutesShort}',
                ),
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              SizedBox(height: 28.h),
              SizedBox(
                height: 96.h,
                child: FilledButton.icon(
                  onPressed: () => MapsLauncher.navigate(
                    latitude: nearest.latitude,
                    longitude: nearest.longitude,
                    label: nearest.name,
                  ),
                  icon: Icon(Icons.directions_walk, size: 34.sp),
                  label: Text(
                    library.navigateToNearest,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                height: 64.h,
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(nearbyMosquesProvider),
                  icon: Icon(Icons.refresh, size: 26.sp),
                  label: Text(library.refresh, style: text.titleMedium),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------------- shared

class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 40.sp, color: AppColors.radar),
              SizedBox(height: 12.h),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (action != null && onAction != null) ...<Widget>[
                SizedBox(height: 14.h),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(action!),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Saves the mosque the reader is standing in.
///
/// The name is optional on purpose: someone who just walked in knows the place
/// but may not feel like typing, and an unnamed pin still does its job — it
/// appears in the list by distance, tagged as theirs, and can be renamed later
/// by deleting and adding again.
Future<void> _addMosqueHere(
  BuildContext context,
  WidgetRef ref,
  AppLocation location,
  AppLocalizations l10n,
) async {
  final TextEditingController controller = TextEditingController();
  final bool? save = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(l10n.mosqueAddHere),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.mosqueAddHint),
          SizedBox(height: 12.h),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.mosqueNameOptional,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );

  if (save != true) return;

  final String name = controller.text.trim();
  final UserMosque mosque = UserMosque(
    id: 'user:${DateTime.now().microsecondsSinceEpoch}',
    name: name.isEmpty ? null : name,
    latitude: location.latitude,
    longitude: location.longitude,
    createdAt: DateTime.now(),
  );

  await ref.read(userMosqueActionsProvider).add(mosque);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(l10n.mosqueAdded)));
}

/// Removes a pin the reader placed. Confirm first: a mosque they added is a
/// place they go to, not a list entry to lose to a stray tap.
Future<void> _removeMosque(
  BuildContext context,
  WidgetRef ref,
  MosqueEntity mosque,
  AppLocalizations l10n,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(l10n.mosqueDelete),
      content: Text(mosque.name),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(userMosqueActionsProvider).remove(mosque.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(l10n.mosqueDeleted)));
}

/// What the radar shows before a real fix exists — and the one button that
/// fixes it, instead of a list of a city the reader may not be in.
class _LocationUnknown extends StatelessWidget {
  const _LocationUnknown({required this.library, required this.onDetect});

  final AppLocalizations library;
  final VoidCallback onDetect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.location_off_outlined,
                size: 48.sp, color: AppColors.radar),
            SizedBox(height: 12.h),
            Text(
              library.locationNotDetected,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onDetect,
              icon: const Icon(Icons.my_location),
              label: Text(library.locationDetectNow),
            ),
          ],
        ),
      ),
    );
  }
}

