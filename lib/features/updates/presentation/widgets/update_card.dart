import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/updates/domain/entities/update_entities.dart';
import 'package:awan/features/updates/presentation/providers/updates_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The update button: one tap, one question to GitHub, and a plain answer.
///
/// There is no "check on launch" and no polling — the card does nothing until
/// it is asked. That is a battery rule from this project as much as a privacy
/// one, and it is the reason the whole feature is a card and not a service.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final UpdateState state = ref.watch(updateControllerProvider);
    final UpdateController controller = ref.read(updateControllerProvider.notifier);
    final ThemeData theme = Theme.of(context);

    final UpdateCheck? check = state.check;
    final DownloadState dl = state.download;
    final bool available = check?.hasUpdate ?? false;

    // The delta that could take *this* build to the published one, if the
    // release carried one. Null means the button offers the full APK.
    final PatchAsset? delta =
        available ? check!.release!.patchFrom(check.currentVersion) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.system_update_alt),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.updateTitle, style: theme.textTheme.titleMedium),
                ),
                if (state.checking)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: controller.checkNow,
                    child: Text(l10n.updateCheck),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (check == null)
              Text(
                l10n.updateIntro,
                style: theme.textTheme.bodySmall,
              )
            else ...<Widget>[
              _StatusLine(check: check, l10n: l10n),
              if (available) ...<Widget>[
                const SizedBox(height: 8),
                if (dl.phase == DownloadPhase.idle || dl.phase == DownloadPhase.failed) ...<Widget>[
                  if (delta != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l10n.updatePatchHint(delta.sizeLabel),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: () => controller.downloadAndInstall(
                      expectedSha: check.release?.sha256,
                    ),
                    icon: const Icon(Icons.download),
                    label: Text(
                      delta != null
                          ? '${l10n.updateDownload} · ${delta.sizeLabel}'
                          : '${l10n.updateDownload} · ${check.release!.sizeLabel}',
                    ),
                  ),
                ]
                else if (dl.phase == DownloadPhase.downloading ||
                    dl.phase == DownloadPhase.verifying) ...<Widget>[
                  LinearProgressIndicator(value: dl.phase == DownloadPhase.verifying ? null : dl.progress),
                  const SizedBox(height: 6),
                  Text(
                    dl.phase == DownloadPhase.verifying
                        ? l10n.updateVerifying
                        : '${(dl.progress * 100).toStringAsFixed(0)}%  ·  '
                            '${(dl.received / 1048576).toStringAsFixed(1)} MB',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else if (dl.phase == DownloadPhase.ready) ...<Widget>[
                  if (dl.viaPatch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l10n.updatePatchedLocally,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (!dl.verified)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l10n.updateUnverified,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: () => _install(context, ref, controller, dl.path),
                    icon: const Icon(Icons.install_mobile),
                    label: Text(l10n.updateInstall),
                  ),
                ],
              ],
            ],
            if (dl.phase == DownloadPhase.failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  dl.error == 'checksum' ? l10n.updateChecksumFailed : (dl.error ?? ''),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _install(
    BuildContext context,
    WidgetRef ref,
    UpdateController controller,
    String? path,
  ) async {
    if (path == null) return;
    final AppLocalizations l10n = context.l10n;
    final bool allowed = await controller.canInstall();
    if (!allowed) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l10n.updateTitle),
          content: Text(l10n.updateAllowInstall),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.openInstallSettings();
              },
              child: Text(l10n.updateOpenSettings),
            ),
          ],
        ),
      );
      return;
    }
    await controller.install(path);
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.check, required this.l10n});

  final UpdateCheck check;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String text;
    Color? colour;
    switch (check.status) {
      case UpdateStatus.notConfigured:
        text = l10n.updateNoChannel;
        colour = theme.colorScheme.error;
      case UpdateStatus.upToDate:
        // Version strings are Latin and read left-to-right even in an Arabic
        // sentence; without this they render as "23+1.19.1".
        text = '${l10n.updateUpToDate} · ${check.currentVersion.split('+').first}';
      case UpdateStatus.available:
        final AppRelease r = check.release!;
        text = '${l10n.updateAvailable} ${r.version} · ${r.sizeLabel}';
      case UpdateStatus.failed:
        text = switch (check.message) {
          'rate_limited' => l10n.updateRateLimited,
          'no_release' => l10n.updateNoRelease,
          'repo_not_found' => l10n.updateRepoNotFound,
          _ => l10n.updateFailed,
        };
        colour = theme.colorScheme.error;
    }
    return Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: colour));
  }
}
