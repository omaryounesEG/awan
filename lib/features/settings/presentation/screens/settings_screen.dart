import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/error/failures.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/audio_manager_service.dart';
import 'package:awan/core/services/location/app_location.dart';
import 'package:awan/core/services/location/cities.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/settings/settings_controller.dart';
import 'package:awan/core/theme/app_settings_provider.dart';
import 'package:awan/core/utils/clock_shift.dart';
import 'package:awan/core/utils/date_x.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';
import 'package:awan/features/midad/presentation/screens/midad_screen.dart';
import 'package:awan/features/mosque_radar/presentation/screens/radar_screen.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_home_screen.dart';
import 'package:awan/features/shamila_library/presentation/screens/library_home_screen.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/features/settings/presentation/screens/about_screen.dart';
import 'package:awan/features/settings/presentation/screens/adhan_alerts_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Settings — the display half (Step 2).
///
/// Everything that changes how the app *looks* or *reads* lives here: theme,
/// elderly mode, text size, interface language, the hijri offset and the
/// location the engine calculates from. Prayer-parameter and notification
/// tuning arrive with their own steps; this screen already reflects every one
/// of them from the same settings blob, so nothing has to be rebuilt later.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppUiSettings ui = ref.watch(appSettingsProvider);
    final AppSettings settings = ref.watch(settingsProvider);
    final LocationUiState locationState = ref.watch(locationActionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _Section(
            title: l10n.display,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.theme),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<ThemeMode>(
                    segments: <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                        icon: const Icon(Icons.brightness_auto_outlined),
                      ),
                    ],
                    selected: <ThemeMode>{ui.themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<ThemeMode> selection) => ref
                        .read(appSettingsProvider.notifier)
                        .setThemeMode(selection.first),
                  ),
                ),
              ),
              const Divider(height: 22),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.remove_red_eye_outlined),
                title: Text(l10n.elderlyMode),
                subtitle: Text(l10n.elderlyModeDesc),
                value: ui.isElderlyMode,
                onChanged: (bool value) => ref
                    .read(appSettingsProvider.notifier)
                    .setElderlyMode(value),
              ),
              const Divider(height: 22),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.textScale),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${(ui.textScale * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: settings.textScale.clamp(0.85, 1.6),
                      min: 0.85,
                      max: 1.6,
                      divisions: 15,
                      label: '${(settings.textScale * 100).round()}%',
                      onChanged: (double value) => ref
                          .read(settingsControllerProvider.notifier)
                          .setTextScale(value),
                    ),
                  ],
                ),
              ),
              const Divider(height: 22),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.hijriOffset),
                subtitle: Text(
                  settings.hijriOffsetDays == 0
                      ? '0'
                      : '${settings.hijriOffsetDays > 0 ? '+' : ''}'
                          '${settings.hijriOffsetDays}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      onPressed: () => ref
                          .read(settingsControllerProvider.notifier)
                          .setHijriOffset(settings.hijriOffsetDays - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(settingsControllerProvider.notifier)
                          .setHijriOffset(settings.hijriOffsetDays + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.language,
            children: <Widget>[
              SegmentedButton<String>(
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'ar', label: Text(l10n.arabic)),
                  ButtonSegment<String>(value: 'en', label: Text(l10n.english)),
                ],
                selected: <String>{ui.localeCode},
                showSelectedIcon: false,
                onSelectionChanged: (Set<String> selection) => ref
                    .read(settingsControllerProvider.notifier)
                    .setLocale(selection.first),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.location,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(
                  ui.isArabic
                      ? (settings.cityAr.isEmpty
                          ? settings.cityEn
                          : settings.cityAr)
                      : (settings.cityEn.isEmpty
                          ? settings.cityAr
                          : settings.cityEn),
                ),
                subtitle: Text(
                  '${settings.latitude.toStringAsFixed(4)}, '
                  '${settings.longitude.toStringAsFixed(4)} · '
                  '${settings.locationMode == 'auto' ? l10n.locationAuto : l10n.locationManual}',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: locationState.busy
                          ? null
                          : () => _detect(context, ref),
                      icon: locationState.busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(l10n.detectLocation),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickCity(context, ref),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: Text(l10n.cityName),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.timeSection,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text(l10n.daylightSaving),
                subtitle: Text(
                  '${_dstModeLabel(l10n, settings.dstMode)} · '
                  '${_dstDeviceLine(l10n)}',
                ),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onTap: () => _pickDstMode(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.notifications,
            children: <Widget>[
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.adhanNotifications),
                subtitle: Text(l10n.notificationsEnabled),
                value: settings.isAdhanEnabled,
                onChanged: (bool value) =>
                    _setAdhanEnabled(context, ref, value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_off_outlined),
                title: Text(l10n.silentMode),
                subtitle: Text(l10n.silentModeDesc),
                value: settings.isAutoSilentEnabled,
                onChanged: (bool value) =>
                    _setAutoSilent(context, ref, value),
              ),
              // Jumu'ah has its own hour: the khutbah starts at the adhan, so
              // the silence is counted from it rather than from a typed clock.
              if (settings.isAutoSilentEnabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mosque_outlined),
                  title: Text(l10n.jumuahSilentTitle),
                  subtitle: Text(l10n.jumuahSilentHint),
                  trailing: DropdownButton<int>(
                    value: settings.jumuahSilentMinutes,
                    underline: const SizedBox.shrink(),
                    items: const <int>[0, 30, 45, 60, 90]
                        .map(
                          (int minutes) => DropdownMenuItem<int>(
                            value: minutes,
                            child: Text(minutes == 0 ? '—' : '$minutes'),
                          ),
                        )
                        .toList(),
                    onChanged: (int? value) =>
                        _setJumuahSilent(context, ref, value ?? 0),
                  ),
                ),
              // The per-adhan detail lives one tap away: five prayers × (how it
              // alerts you + when it goes quiet) does not belong in a column of
              // switches.
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune),
                title: Text(l10n.adhanAlertPerPrayer),
                subtitle: Text(l10n.adhanAlertHint),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdhanAlertsScreen(),
                  ),
                ),
              ),
              // The hourglass: one switch for both the system notification and
              // the floating card, so the two can never disagree.
              SwitchListTile(
                secondary: const Icon(Icons.hourglass_bottom_outlined),
                title: Text(l10n.prePrayerReminder),
                subtitle: Text(l10n.prePrayerHint),
                value: settings.preAdhanEnabled,
                onChanged: (bool value) =>
                    ref.read(settingsControllerProvider.notifier)
                        .setPreAdhanEnabled(value),
              ),
              if (settings.preAdhanEnabled) ...<Widget>[
                ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(
                      start: 16, end: 16),
                  title: Text(l10n.prePrayerLead),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      children: <Widget>[
                        for (final int minutes in AppConstants.preAdhanChoices)
                          ChoiceChip(
                            label: Text('$minutes'),
                            selected: settings.preAdhanMinutes == minutes,
                            onSelected: (bool _) => ref
                                .read(settingsControllerProvider.notifier)
                                .setPreAdhanMinutes(minutes),
                          ),
                      ],
                    ),
                  ),
                ),
                // The clip itself is chosen on «التنبيهات», beside the adhan's
                // own: two sounds, one screen, auditionable in place. This row
                // only says where, so the two cannot drift apart.
                ListTile(
                  contentPadding:
                      const EdgeInsetsDirectional.only(start: 40, end: 16),
                  leading: Icon(
                    settings.preAdhanSound.audible
                        ? Icons.volume_up_outlined
                        : Icons.volume_off_outlined,
                  ),
                  title: Text(l10n.prePrayerSound),
                  subtitle: Text(l10n.prePrayerSoundHint),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext _) => const AdhanAlertsScreen(),
                    ),
                  ),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.alarm_on_outlined),
                title: Text(l10n.adhanNotifications),
                subtitle: Text(
                  ref.watch(pendingAdhanCountProvider).maybeWhen(
                        data: (int count) =>
                            '${l10n.scheduledCount(count)} · ${l10n.offline}',
                        orElse: () => l10n.offline,
                      ),
                ),
                trailing: TextButton(
                  onPressed: () => _reschedule(context, ref),
                  child: Text(l10n.refresh),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.moreFeatures,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(l10n.quran),
                subtitle: Text('${l10n.surahIndex} · ${l10n.tafsir}'),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const QuranHomeScreen()),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_library_outlined),
                title: Text(l10n.libraryTitle),
                subtitle: Text(l10n.librarySubtitle),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LibraryHomeScreen(),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(l10n.mosqueRadar),
                subtitle: Text(l10n.nearbyMosques),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const RadarScreen(),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calculate_outlined),
                title: Text(l10n.midadTitle),
                subtitle: Text(l10n.midadSubtitle),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const MidadScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.about),
            subtitle: Text(l10n.aboutDesc),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _detect(BuildContext context, WidgetRef ref) async {
    await ref.read(locationActionProvider.notifier).detect();
    if (!context.mounted) return;
    final LocationUiState state = ref.read(locationActionProvider);
    final Failure? failure = state.failure;
    if (failure != null) {
      final AppLocalizations l10n = context.l10n;
      final String message = failure is PermissionFailure
          ? l10n.locationDenied
          : l10n.locationUnavailable;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: l10n.openSettings,
            onPressed: () =>
                ref.read(locationServiceProvider).openLocationSettings(),
          ),
        ),
      );
      return;
    }
    // The engine keys its cache on the coordinates, so refreshing is enough.
    ref.invalidate(monthPrayerTimesProvider);
  }

  Future<void> _pickCity(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final CityPreset? preset = await showModalBottomSheet<CityPreset>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => _CityPicker(l10n: l10n),
    );
    if (preset == null) return;
    await ref.read(locationActionProvider.notifier).chooseCity(
          AppLocation(
            latitude: preset.latitude,
            longitude: preset.longitude,
            cityAr: preset.nameAr,
            cityEn: preset.nameEn,
          ),
          method: preset.method,
        );
    ref.invalidate(monthPrayerTimesProvider);
  }

  /// Summer/winter time. Shown as a sheet with the device's own behaviour spelled
  /// out, because that is the only fact that tells the user whether to touch it.
  Future<void> _pickDstMode(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final String current = ref.read(settingsProvider).dstMode;
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.daylightSaving,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dstNote,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final _DstChoice choice in _dstChoices(l10n))
                RadioListTile<String>(
                  value: choice.mode,
                  groupValue: current,
                  title: Text(choice.title),
                  subtitle: Text(choice.subtitle),
                  onChanged: (String? value) => Navigator.of(sheetContext).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await ref.read(settingsControllerProvider.notifier).setDstMode(picked);
    // Times are cached astronomically; only the shift changed, but the month table
    // and the armed alarms both have to be rebuilt.
    ref.invalidate(monthPrayerTimesProvider);
    if (!context.mounted) return;
    await _reschedule(context, ref);
  }
}

/// One entry of the summer/winter-time picker.
class _DstChoice {
  const _DstChoice(this.mode, this.title, this.subtitle);

  final String mode;
  final String title;
  final String subtitle;
}

List<_DstChoice> _dstChoices(AppLocalizations l10n) => <_DstChoice>[
      _DstChoice(kDstModeAuto, l10n.dstAuto, l10n.dstAutoDesc),
      _DstChoice(kDstModePlusOne, l10n.dstPlusOne, l10n.dstPlusOneDesc),
      _DstChoice(kDstModeMinusOne, l10n.dstMinusOne, l10n.dstMinusOneDesc),
    ];

String _dstModeLabel(AppLocalizations l10n, String mode) {
  switch (mode) {
    case kDstModePlusOne:
      return l10n.dstPlusOne;
    case kDstModeMinusOne:
      return l10n.dstMinusOne;
    default:
      return l10n.dstAuto;
  }
}

/// What the device is doing right now — the fact that decides whether the user
/// needs this setting at all.
String _dstDeviceLine(AppLocalizations l10n) {
  final String offset = formatUtcOffset(deviceUtcOffsetMinutes());
  if (!deviceObservesDst()) return '${l10n.dstDeviceFixed} · $offset';
  return '${deviceIsOnSummerTime() ? l10n.dstDeviceOnSummer : l10n.dstDeviceStandard}'
      ' · $offset';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );
}

// ------------------------------------------------------- notification actions
//
// The switches *are* the scheduler: there is no separate "save" step and no
// background job, because the whole month is handed to the OS in one call.

/// Arms the adhan for the next month, or cancels every pending one.
Future<void> _setAdhanEnabled(
  BuildContext context,
  WidgetRef ref,
  bool value,
) async {
  final AppLocalizations l10n = context.l10n;
  final SettingsController controller =
      ref.read(settingsControllerProvider.notifier);
  final PrayerRepository repository = ref.read(prayerRepositoryProvider);

  if (value) {
    final bool granted =
        await ref.read(notificationServiceProvider).requestPermissions();
    if (!granted) {
      // Leave the switch off: without permission nothing would ever be heard,
      // and a switch that lies is worse than one that refuses.
      if (context.mounted) _toast(context, l10n.notificationsDenied);
      return;
    }
  }

  await controller.setNotificationsEnabled(value);

  if (!value) {
    await repository.cancelNotifications();
    ref.invalidate(pendingAdhanCountProvider);
    if (context.mounted) _toast(context, l10n.adhanCancelled);
    return;
  }

  final int armed = await repository.scheduleNotifications(
    days: AppConstants.notificationDaysAhead,
  );
  ref.invalidate(pendingAdhanCountProvider);
  if (context.mounted) _toast(context, l10n.adhanScheduled(armed));
}

/// Arms the mute/unmute windows around each prayer (Android only).
/// Arms the Jumu'ah window and keeps it in step with the plan.
Future<void> _setJumuahSilent(
  BuildContext context,
  WidgetRef ref,
  int minutes,
) async {
  await ref
      .read(settingsControllerProvider.notifier)
      .setJumuahSilentMinutes(minutes);
  final PrayerRepository repository = ref.read(prayerRepositoryProvider);
  await repository.scheduleSilence(days: AppConstants.notificationDaysAhead);
}

Future<void> _setAutoSilent(
  BuildContext context,
  WidgetRef ref,
  bool value,
) async {
  final AppLocalizations l10n = context.l10n;
  final AudioManagerService audio = ref.read(audioManagerServiceProvider);
  final SettingsController controller =
      ref.read(settingsControllerProvider.notifier);
  final PrayerRepository repository = ref.read(prayerRepositoryProvider);

  if (value && !await audio.hasPolicyAccess()) {
    // Do-Not-Disturb access can only be granted by the user, so ask for it and
    // say why; if it stays refused, the switch stays off.
    if (context.mounted) _toast(context, l10n.silentNeedsPolicy);
    await audio.openPolicySettings();
    if (!context.mounted || !await audio.hasPolicyAccess()) return;
  }

  await controller.setSilentMode(value);

  if (!value) {
    await audio.cancelWindows();
    await audio.releaseRinger();
    return;
  }

  final int windows = await repository.scheduleSilence(
    days: AppConstants.notificationDaysAhead,
  );
  if (context.mounted) _toast(context, l10n.silentScheduled(windows));
}

/// Re-arms both schedules — needed after the location, method or madhab change,
/// because every future instant is now a different instant.
Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = context.l10n;
  final AppSettings settings = ref.read(settingsProvider);
  final PrayerRepository repository = ref.read(prayerRepositoryProvider);

  final int armed = settings.isAdhanEnabled
      ? await repository.scheduleNotifications(
          days: AppConstants.notificationDaysAhead,
        )
      : 0;
  if (settings.isAutoSilentEnabled) {
    await repository.scheduleSilence(days: AppConstants.notificationDaysAhead);
  }
  ref.invalidate(pendingAdhanCountProvider);
  if (context.mounted) _toast(context, l10n.adhanScheduled(armed));
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String q = _query.trim();
    final List<CityPreset> matches = q.isEmpty
        ? kCityPresets
        : kCityPresets
            .where((CityPreset c) =>
                c.nameAr.contains(q) ||
                c.nameEn.toLowerCase().contains(q.toLowerCase()) ||
                c.countryAr.contains(q) ||
                c.countryEn.toLowerCase().contains(q.toLowerCase()))
            .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: widget.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: matches.isEmpty
                ? Center(child: Text(widget.l10n.noResults))
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CityPreset city = matches[index];
                      return ListTile(
                        leading: const Icon(Icons.location_city_outlined),
                        title: Text(city.nameAr),
                        subtitle: Text('${city.nameEn} · ${city.countryAr}'),
                        onTap: () => Navigator.of(context).pop(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Kept for the step that adds a "reset everything" action; the date helper is
/// used by the same screen's footer.
String settingsFooterSubtitle(DateTime now, String localeCode) =>
    '${gregorianLabel(now, localeCode)} · '
    '${hijriLabel(now, localeCode: localeCode)}';
