import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/audio_manager_service.dart';
import 'package:awan/core/services/sound_preview_service.dart';
import 'package:awan/core/settings/adhan_preferences.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/entities/scheduled_adhan.dart';
import 'package:awan/core/settings/settings_controller.dart';
import 'package:awan/features/prayer_engine/domain/repositories/prayer_repository.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «التنبيهات» — one adhan at a time.
///
/// Five prayers are not one setting: Fajr at 4am and Asr at 4pm are different
/// events in a household. Each row chooses how its adhan announces itself, and
/// when the ringer goes quiet around it. Everything here re-arms the schedule on
/// save, so a change is real rather than a stored wish.
class AdhanAlertsScreen extends ConsumerWidget {
  const AdhanAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppSettings settings = ref.watch(settingsProvider);
    final AdhanPreferences prefs = settings.adhanPreferences;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
        children: <Widget>[
          Text(
            l10n.adhanAlertHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 10.h),
          for (final PrayerName prayer in PrayerName.obligatory)
            _PrayerAlertCard(
              prayer: prayer,
              title: _prayerName(l10n, prayer),
              mode: prefs.alertModeFor(prayer.key),
              silentEnabled: settings.silentModeEnabled,
              startMinutes: prefs.silentStartFor(prayer.key),
              durationMinutes: prefs.silentDurationFor(prayer.key),
              onMode: (AdhanAlertMode mode) =>
                  _setMode(context, ref, prayer, mode),
              onWindow: (int? start, int? minutes) =>
                  _setWindow(context, ref, prayer, start, minutes),
              onSilentMaster: (bool value) => _setSilentMaster(context, ref, value),
            ),
          SizedBox(height: 14.h),
          _SoundPicker(
            title: l10n.adhanSoundTitle,
            hint: l10n.adhanSoundHint,
            selected: settings.adhanSound,
            onSelected: (AdhanSound sound) => _setAdhanSound(context, ref, sound),
          ),
          SizedBox(height: 14.h),
          _SoundPicker(
            title: l10n.preAdhanSoundTitle,
            hint: l10n.preAdhanSoundHint,
            selected: settings.preAdhanSound,
            onSelected: (AdhanSound sound) =>
                _setPreAdhanSound(context, ref, sound),
          ),
          SizedBox(height: 14.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.lockScreenAllDay,
            onChanged: (bool value) => _setLockScreen(context, ref, value),
            title: Row(
              children: <Widget>[
                Icon(Icons.lock_clock, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(child: Text(l10n.lockScreenAllDayLabel)),
              ],
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                l10n.lockScreenAllDayHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.timer_outlined, size: 20.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      l10n.lockScreenCountdown,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A new clip only takes effect on the next plan, so the schedule is re-armed
  /// right away — the reader hears the change at the next adhan, not tomorrow.
  Future<void> _setAdhanSound(
    BuildContext context,
    WidgetRef ref,
    AdhanSound sound,
  ) async {
    await ref.read(settingsControllerProvider.notifier).setAdhanSound(sound);
    await _rearm(ref);
  }

  Future<void> _setPreAdhanSound(
    BuildContext context,
    WidgetRef ref,
    AdhanSound sound,
  ) async {
    await ref.read(settingsControllerProvider.notifier).setPreAdhanSound(sound);
    await _rearm(ref);
  }

  /// The card is posted, not scheduled, so the new state is applied by the
  /// re-plan that follows — which is also what re-reads the setting.
  Future<void> _setLockScreen(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setLockScreenAllDay(value);
    await _rearm(ref);
  }

  String _prayerName(AppLocalizations l10n, PrayerName prayer) =>
      switch (prayer) {
        PrayerName.sunrise => l10n.sunrise,
        PrayerName.fajr => l10n.fajr,
        PrayerName.dhuhr => l10n.dhuhr,
        PrayerName.asr => l10n.asr,
        PrayerName.maghrib => l10n.maghrib,
        PrayerName.isha => l10n.isha,
      };

  /// Saves the mode *and* re-arms: the channels a notification uses are chosen
  /// when it is scheduled, so a fresh plan is what makes the choice take effect.
  Future<void> _setMode(
    BuildContext context,
    WidgetRef ref,
    PrayerName prayer,
    AdhanAlertMode mode,
  ) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setAdhanAlertMode(prayer.key, mode);
    await _rearm(ref);
  }

  Future<void> _setWindow(
    BuildContext context,
    WidgetRef ref,
    PrayerName prayer,
    int? start,
    int? minutes,
  ) async {
    await ref.read(settingsControllerProvider.notifier).setAdhanSilentWindow(
          prayer.key,
          startMinutes: start,
          minutes: minutes,
        );
    await _rearm(ref);
  }

  /// The master switch for auto-silent, with the one permission Android insists a
  /// human grants.
  Future<void> _setSilentMaster(
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.silentNeedsPolicy)),
        );
      }
      await audio.openPolicySettings();
      if (!context.mounted || !await audio.hasPolicyAccess()) {
        return;
      }
    }

    await controller.setSilentMode(value);
    if (!value) {
      await audio.cancelWindows();
      // Windows that will never fire must not keep the phone silent.
      await audio.releaseRinger();
      return;
    }
    await repository.scheduleSilence(
      days: AppConstants.notificationDaysAhead,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.silentSaved)),
      );
    }
  }

  Future<void> _rearm(WidgetRef ref) async {
    final PrayerRepository repository = ref.read(prayerRepositoryProvider);
    await repository.scheduleNotifications(
      days: AppConstants.notificationDaysAhead,
    );
    await repository.scheduleSilence(
      days: AppConstants.notificationDaysAhead,
    );
  }
}

class _PrayerAlertCard extends StatelessWidget {
  const _PrayerAlertCard({
    required this.prayer,
    required this.title,
    required this.mode,
    required this.silentEnabled,
    required this.startMinutes,
    required this.durationMinutes,
    required this.onMode,
    required this.onWindow,
    required this.onSilentMaster,
  });

  final PrayerName prayer;
  final String title;
  final AdhanAlertMode mode;
  final bool silentEnabled;
  final int startMinutes;
  final int durationMinutes;
  final ValueChanged<AdhanAlertMode> onMode;
  final void Function(int? start, int? minutes) onWindow;
  final ValueChanged<bool> onSilentMaster;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.access_time, size: 18.sp, color: theme.colorScheme.outline),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AdhanAlertMode>(
                segments: <ButtonSegment<AdhanAlertMode>>[
                  ButtonSegment<AdhanAlertMode>(
                    value: AdhanAlertMode.quiet,
                    label: Text(l10n.adhanAlertQuiet),
                    icon: Icon(Icons.notifications_none, size: 18.sp),
                  ),
                  ButtonSegment<AdhanAlertMode>(
                    value: AdhanAlertMode.vibrate,
                    label: Text(l10n.adhanAlertVibrate),
                    icon: Icon(Icons.vibration, size: 18.sp),
                  ),
                  ButtonSegment<AdhanAlertMode>(
                    value: AdhanAlertMode.tone,
                    label: Text(l10n.adhanAlertTone),
                    icon: Icon(Icons.notifications_active, size: 18.sp),
                  ),
                ],
                selected: <AdhanAlertMode>{mode},
                showSelectedIcon: false,
                onSelectionChanged: (Set<AdhanAlertMode> value) =>
                    onMode(value.first),
              ),
            ),
            SizedBox(height: 6.h),
            if (!silentEnabled)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => onSilentMaster(true),
                  icon: Icon(Icons.volume_off, size: 18.sp),
                  label: Text(l10n.silentMode),
                ),
              )
            else ...<Widget>[
              Divider(height: 18.h),
              Row(
                children: <Widget>[
                  Icon(Icons.volume_off, size: 18.sp, color: theme.colorScheme.outline),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(l10n.silentStartsLabel, style: theme.textTheme.bodySmall)),
                  DropdownButton<int>(
                    value: startMinutes,
                    underline: const SizedBox.shrink(),
                    items: <DropdownMenuItem<int>>[
                      for (final int choice in AdhanPreferences.silentStartChoices)
                        DropdownMenuItem<int>(
                          value: choice,
                          child: Text(
                            choice == 0
                                ? l10n.silentStartsAtAdhan
                                : l10n.silentStartsAfter(choice),
                          ),
                        ),
                    ],
                    onChanged: (int? value) => onWindow(value, null),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  SizedBox(width: 26.w),
                  Expanded(child: Text(l10n.silentLastsLabel, style: theme.textTheme.bodySmall)),
                  DropdownButton<int>(
                    value: durationMinutes,
                    underline: const SizedBox.shrink(),
                    items: <DropdownMenuItem<int>>[
                      for (final int choice in AdhanPreferences.silentMinutesChoices)
                        DropdownMenuItem<int>(
                          value: choice,
                          child: Text(l10n.silentLastsFor(choice)),
                        ),
                    ],
                    onChanged: (int? value) => onWindow(null, value),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row of choices for one alert's sound, each one auditionable in place.
///
/// Auditioning is the point: a clip can only be judged by hearing it, so every
/// option carries its own play button and the preview stops the moment another is
/// started, the sheet is closed, or the clip ends.
class _SoundPicker extends ConsumerStatefulWidget {
  const _SoundPicker({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final String hint;
  final AdhanSound selected;
  final ValueChanged<AdhanSound> onSelected;

  @override
  ConsumerState<_SoundPicker> createState() => _SoundPickerState();
}

class _SoundPickerState extends ConsumerState<_SoundPicker> {
  AdhanSound? _playing;

  @override
  void dispose() {
    if (_playing != null) {
      ref.read(soundPreviewServiceProvider).stop();
    }
    super.dispose();
  }

  Future<void> _toggle(AdhanSound sound) async {
    final SoundPreviewService service = ref.read(soundPreviewServiceProvider);
    if (_playing == sound) {
      await service.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    setState(() => _playing = sound);
    await service.play(sound);
    // A round trip is enough to know the clip started; when it finishes on its
    // own the native side has already released the player, so the button simply
    // stops showing as active on the next rebuild.
  }

  String _label(AppLocalizations l10n, AdhanSound sound) => switch (sound) {
        AdhanSound.system => l10n.soundSystem,
        AdhanSound.silent => l10n.soundSilent,
        AdhanSound.takbir => l10n.soundTakbir,
        AdhanSound.call => l10n.soundCall,
        AdhanSound.adhan => l10n.soundAdhan,
        AdhanSound.ring => l10n.soundRing,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 2.h),
            Text(widget.hint, style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: 4.h),
            for (final AdhanSound sound in <AdhanSound>[
              AdhanSound.system,
              ...AdhanSound.bundled,
              AdhanSound.silent,
            ])
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Radio<AdhanSound>(
                  value: sound,
                  groupValue: widget.selected,
                  onChanged: (AdhanSound? value) {
                    if (value != null) widget.onSelected(value);
                  },
                ),
                title: Text(_label(l10n, sound)),
                trailing: sound == AdhanSound.silent
                    ? null
                    : IconButton(
                        tooltip: _playing == sound
                            ? l10n.soundStop
                            : l10n.soundPreview,
                        icon: Icon(
                          _playing == sound
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline,
                        ),
                        onPressed: () => _toggle(sound),
                      ),
                onTap: () => widget.onSelected(sound),
              ),
          ],
        ),
      ),
    );
  }
}
