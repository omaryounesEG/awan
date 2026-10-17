import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/features/shamila_library/data/datasources/library_remote_datasource.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Where the library fetches from.
///
/// The library is static files, so "the server" is one URL — and which URL is a
/// deployment decision (a CDN, a mirror, or a laptop on the same Wi-Fi while the
/// catalogue is being filled). Making it a setting rather than a compile-time
/// constant means a build does not have to be re-made to point somewhere else.
Future<void> showLibrarySourceSheet(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = context.l10n;
  final TextEditingController controller = TextEditingController(
    text: ref.read(settingsProvider).libraryCdnBaseUrl,
  );
  String? error;

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return AlertDialog(
          title: Text(l10n.librarySource),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: l10n.librarySourceHint,
                  errorText: error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.libraryRemoveHint,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.libraryCancel),
            ),
            FilledButton(
              onPressed: () async {
                final String value = controller.text.trim();
                if (!isFetchable(value)) {
                  setState(() => error = l10n.librarySourceInvalid);
                  return;
                }
                await ref
                    .read(settingsControllerProvider.notifier)
                    .setLibraryCdnBaseUrl(value);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.librarySourceSaved)),
                  );
                }
              },
              child: Text(l10n.librarySync),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
}

/// Shared failure → text mapping: a failure the reader can act on says what
/// failed, one they cannot says it in plain words.
String libraryFailureText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.libraryOfflineCached,
      ServerFailure() => l10n.librarySyncFailed,
      ParseFailure() => l10n.librarySyncFailed,
      CacheFailure() => l10n.librarySyncFailed,
      _ => l10n.librarySyncFailed,
    };
