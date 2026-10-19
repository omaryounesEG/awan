import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/location/app_location.dart';
import 'package:awan/core/utils/extensions.dart';
import 'package:awan/core/utils/geo.dart';
import 'package:awan/features/mosque_radar/data/mosque_fence_service.dart';
import 'package:awan/features/mosque_radar/domain/entities/user_mosque.dart';
import 'package:awan/features/mosque_radar/presentation/providers/mosque_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «مسجدي» — one tap, one fence, and the phone knows where it is.
///
/// This is the honest answer to "the radar shows Al-Azhar instead of the mosque
/// I am standing in": public maps do not know the small mosque, and indoors the
/// fix is only good to 10–30 m. So the reader records the spot themselves, while
/// standing in it. No map to pan, no pin to place 30 m off.
class MyMosqueCard extends ConsumerStatefulWidget {
  const MyMosqueCard({super.key});

  @override
  ConsumerState<MyMosqueCard> createState() => _MyMosqueCardState();
}

class _MyMosqueCardState extends ConsumerState<MyMosqueCard> {
  MosqueFenceCheck? _check;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<UserMosque>> mine = ref.watch(userMosquesProvider);
    final AppLocation location = ref.watch(locationProvider);
    final bool enabled = ref.watch(mosqueFenceEnabledProvider).valueOrNull ?? false;
    // Watching the sync provider is what pushes the list to the native side.
    ref.watch(mosqueFenceSyncProvider);

    final List<UserMosque> mosques = mine.valueOrNull ?? const <UserMosque>[];

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.my_location, size: 18.sp),
              SizedBox(width: 6.w),
              Text(l10n.mosqueFenceTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (mosques.isNotEmpty)
                Switch.adaptive(
                  value: enabled,
                  onChanged: _busy ? null : (bool value) => _toggle(value),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            enabled && mosques.isNotEmpty
                ? l10n.mosqueFenceSubtitleOn
                : l10n.mosqueFenceSubtitle,
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 10.h),
          if (mosques.isEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(l10n.mosqueFenceRegister),
                onPressed: _busy ? null : () => _register(location),
              ),
            )
          else ...<Widget>[
            for (final UserMosque mosque in mosques) _row(mosque, location, l10n),
            SizedBox(height: 8.h),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: Text(l10n.mosqueFenceAddAnother),
                    onPressed: _busy ? null : () => _register(location),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: Text(l10n.mosqueFenceCheck),
                    onPressed: _busy ? null : _runCheck,
                  ),
                ),
              ],
            ),
            if (_check != null) ...<Widget>[
              SizedBox(height: 8.h),
              _checkLine(_check!, l10n, theme),
            ],
            SizedBox(height: 6.h),
            Text(
              l10n.mosqueFenceFallbackNote,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.mosqueFenceNeedsBackground,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (mosques.isEmpty) ...<Widget>[
            SizedBox(height: 8.h),
            Text(
              l10n.mosqueFenceRegisterHint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(UserMosque mosque, AppLocation location, AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);
    final double distance = Geo.distanceMeters(
      fromLatitude: location.latitude,
      fromLongitude: location.longitude,
      toLatitude: mosque.latitude,
      toLongitude: mosque.longitude,
    );
    final bool inside = distance <= mosque.radiusMeters;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: <Widget>[
          Icon(inside ? Icons.check_circle : Icons.circle_outlined,
              size: 18.sp,
              color: inside
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  mosque.name ?? l10n.mosqueFenceUnnamed,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${l10n.mosqueFenceRadiusLabel(mosque.radiusMeters.round())} · '
                  '${distance < 1000 ? l10n.mosqueFenceDistanceMeters(distance.round()) : l10n.mosqueFenceDistanceKm((distance / 1000).toStringAsFixed(1))}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.mosqueFenceDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: _busy ? null : () => _delete(mosque),
          ),
        ],
      ),
    );
  }

  Widget _checkLine(
      MosqueFenceCheck check, AppLocalizations l10n, ThemeData theme) {
    final bool ok = check.isInside;
    final String text = !check.known
        ? l10n.mosqueFenceUnknown
        : ok
            ? l10n.mosqueFenceInsideNow
            : l10n.mosqueFenceOutsideNow(
                (check.distanceMeters ?? 0).round());
    return Row(
      children: <Widget>[
        Icon(ok ? Icons.check_circle : Icons.error_outline,
            size: 16.sp,
            color: ok ? theme.colorScheme.primary : theme.colorScheme.error),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(text, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }

  Future<void> _runCheck() async {
    setState(() => _busy = true);
    // Refresh the app's own fix too, so the distance in the row agrees with the
    // verdict below it instead of trailing behind by a walk.
    ref.read(locationActionProvider.notifier).detect();
    final MosqueFenceCheck result =
        await ref.read(mosqueFenceServiceProvider).check();
    if (!mounted) return;
    setState(() {
      _check = result;
      _busy = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    if (value) {
      // The check runs from an alarm while the app is closed: without
      // «allow all the time» it can never see where the phone is.
      final PermissionStatus status = await Permission.locationAlways.status;
      if (!status.isGranted) {
        await Permission.locationAlways.request();
      }
    }
    await ref.read(mosqueFenceServiceProvider).setEnabled(value);
    ref.invalidate(mosqueFenceEnabledProvider);
    ref.invalidate(mosqueFenceSyncProvider);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _delete(UserMosque mosque) async {
    setState(() => _busy = true);
    await ref.read(userMosqueActionsProvider).remove(mosque.id);
    ref.invalidate(mosqueFenceSyncProvider);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _register(AppLocation location) async {
    final AppLocalizations l10n = context.l10n;
    if (!location.fromDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mosqueFenceNeedLocation)),
      );
      return;
    }

    final TextEditingController name = TextEditingController();
    double radius = UserMosque.defaultRadiusMeters;
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(l10n.mosqueFenceRegister),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.mosqueFenceRegisterHint,
                  style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: 10.h),
              TextField(
                controller: name,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.mosqueFenceNameHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              SizedBox(height: 12.h),
              Text(l10n.mosqueFenceRadius, style: Theme.of(context).textTheme.labelMedium),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 6.w,
                children: <Widget>[
                  for (final double choice in UserMosque.radiusChoices)
                    ChoiceChip(
                      label: Text('${choice.round()} ${l10n.mosqueFenceMeterUnit}'),
                      selected: radius == choice,
                      onSelected: (_) => setDialogState(() => radius = choice),
                    ),
                ],
              ),
              if (location.accuracyMeters != null) ...<Widget>[
                SizedBox(height: 8.h),
                Text(
                  l10n.mosqueFenceAccuracy(location.accuracyMeters!.round()),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (save != true) return;

    final UserMosque mosque = UserMosque(
      id: 'user:${DateTime.now().microsecondsSinceEpoch}',
      latitude: location.latitude,
      longitude: location.longitude,
      createdAt: DateTime.now(),
      name: name.text.trim().isEmpty ? null : name.text.trim(),
      accuracyMeters: location.accuracyMeters ?? 0,
      radiusMeters: radius,
    );
    await ref.read(userMosqueActionsProvider).add(mosque);
    // Registering is the moment the reader wants the feature, so it is on.
    await ref.read(mosqueFenceServiceProvider).setEnabled(true);
    ref.invalidate(mosqueFenceEnabledProvider);
    ref.invalidate(mosqueFenceSyncProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mosqueFenceSaved)),
    );
  }
}
