import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/prayer_engine/presentation/l10n/reminder_wording.dart';

import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/utils/labels.dart';
import 'package:awan/features/prayer_engine/domain/usecases/pre_prayer_due.dart';
import 'package:awan/features/prayer_engine/presentation/providers/prayer_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The hourglass that floats over whatever the reader is looking at, a few
/// minutes before a prayer — and leaves the moment they acknowledge it.
///
/// Why it exists next to the system notification: the notification is the right
/// tool when the phone is in a pocket, and this is the right tool when the app is
/// already open (a system banner over the app you are using is noise). Same
/// setting drives both, so they can never disagree, and neither one is a
/// surprise: this one is dismissed by a single tap, and it also expires by
/// itself at the prayer time.
class PrePrayerBanner extends ConsumerWidget {
  const PrePrayerBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PrePrayerDue? due = ref.watch(prePrayerDueProvider);
    if (due == null) return const SizedBox.shrink();

    final AppSettings settings = ref.watch(settingsProvider);
    final AppLocalizations l10n = context.l10n;
    final String name = prayerLabel(l10n, due.prayer);

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _Hourglass(
            // Re-keying on the occurrence replays the entrance animation for each
            // new reminder instead of mutating the old card in place.
            key: ValueKey<String>(due.key),
            title: prePrayerHeadline(l10n, due.minutesLeft, name),
            subtitle: l10n.reminderPrepare(name),
            sound: settings.preAdhanSound.audible,
            onDismiss: () => ref
                .read(dismissedPrePrayerProvider.notifier)
                .state = <String>{...ref.read(dismissedPrePrayerProvider), due.key},
          ),
        ),
      ),
    );
  }
}

class _Hourglass extends StatefulWidget {
  const _Hourglass({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sound,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final bool sound;
  final VoidCallback onDismiss;

  @override
  State<_Hourglass> createState() => _HourglassState();
}

class _HourglassState extends State<_Hourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.35),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _controller,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(18),
          color: scheme.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            // The whole card is the dismiss target: no hunting for the ✕.
            onTap: widget.onDismiss,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(Icons.hourglass_bottom,
                      size: 26, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            if (widget.sound) ...<Widget>[
                              Icon(Icons.volume_up_outlined,
                                  size: 14, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                widget.subtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Deliberately not an IconButton: the card is mounted above
                  // the navigator (so it can float over any route), where there
                  // is no Overlay ancestor — and a Tooltip without an Overlay
                  // throws instead of drawing. Semantics keeps it announced.
                  Semantics(
                    button: true,
                    label:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    child: InkResponse(
                      onTap: widget.onDismiss,
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
