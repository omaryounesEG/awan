import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/updates/presentation/widgets/update_card.dart';
import 'package:awan/l10n/app_localizations.dart';

/// About: identity, version, and the honest data-source list.
///
/// Every line in the sources card answers one question a reader is entitled to
/// ask: **where did this text come from, and under what licence?** An offline
/// app that ships other people's work has to say whose work it is — and the
/// Islamic content in particular carries obligations, not just courtesies.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<_Source> sources = <_Source>[
      _Source('Quran.com v4', Icons.menu_book_outlined, l10n.srcQuranText),
      _Source('Quran.com v4 · 16', Icons.auto_stories_outlined, l10n.srcTafsir),
      _Source('OpenITI · المكتبة الشاملة', Icons.library_books_outlined, l10n.srcLibrary),
      _Source('الكسائي، متشابهات القرآن', Icons.hub_outlined, l10n.srcMutashabih),
      _Source('adhan-dart', Icons.access_time, l10n.srcAdhan),
      // Kept honest: Aladhan is only a verification path, never the source of
      // the times the app actually shows.
      _Source('Aladhan API', Icons.verified_outlined, l10n.srcAladhanVerify),
      _Source('OpenStreetMap', Icons.place_outlined, l10n.srcOsm),
      if (AppConstants.hasGoogleMapsKey)
        _Source('Google Places', Icons.travel_explore, l10n.srcGooglePlaces),
      _Source('tarteel-ai · Synthesium', Icons.graphic_eq, l10n.srcWhisper),
      _Source('intfloat · multilingual-e5', Icons.psychology_outlined, l10n.srcSemantic),
      _Source('KFGQPC · Amiri · IBM Plex', Icons.text_fields, l10n.srcFonts),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                // The real app mark (dome + crescent on an open book), not a
                // generic icon: the same artwork the launcher and the splash use,
                // so the identity is one thing everywhere.
                Image.asset(
                  'assets/images/logo_lockup.png',
                  width: 190,
                  fit: BoxFit.contain,
                  semanticLabel: l10n.appFullName,
                ),
                const SizedBox(height: 4),
                Text(l10n.appFullName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(l10n.tagline, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.tag),
                  title: Text(l10n.version),
                  trailing: const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(appVersion),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.offline_bolt_outlined),
                  title: Text(l10n.offline),
                  subtitle: Text(l10n.cachedResults),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l10n.privacy),
                  subtitle: Text(l10n.privacyDesc),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.dataSources,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(l10n.dataSourcesDesc,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < sources.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: 1),
                  sources[i],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          // Manual by design: the card does nothing until it is tapped, so an
          // offline-first app does not quietly talk to GitHub on every launch.
          const UpdateCard(),
          // The data list says where the *content* comes from; this says where
          // the *code* does. Flutter generates it from the dependencies, so it
          // cannot fall out of date the way a hand-written list would.
          Card(
            child: ListTile(
              leading: const Icon(Icons.code),
              title: Text(l10n.openSourceLicenses),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appFullName,
                applicationVersion: appVersion,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source(this.name, this.icon, this.detail);

  final String name;
  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(name, textDirection: TextDirection.ltr),
        subtitle: Text(detail),
        isThreeLine: detail.length > 60,
      );
}

/// Kept next to the screen that prints it so the two can never disagree.
/// `test/about_version_test.dart` fails the build if this drifts from
/// `pubspec.yaml` — a version printed inside the app is a claim, and a stale
/// claim is worse than none.
const String appVersion = AppConstants.appVersion;
