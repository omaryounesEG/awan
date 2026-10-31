import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/hadith/presentation/providers/hadith_providers.dart';
import 'package:awan/features/hadith/presentation/screens/matn_relations_screen.dart';
import 'package:awan/features/hadith/presentation/screens/rijal_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// «أدوات الباحث» — the part of the hadith section that is for people who work
/// with hadith, not people looking for one.
///
/// Kept behind its own door so the ordinary reader never meets a takhrij they
/// did not ask for, and the researcher does not have to hunt for it.
class HadithResearchScreen extends ConsumerWidget {
  const HadithResearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithResearchTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Text(l10n.hadithResearchIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          _ResearchCard(
            icon: Icons.hub_outlined,
            title: l10n.hadithResearchMatnTitle,
            body: l10n.hadithResearchMatnBody,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MatnRelationsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ResearchCard(
            icon: Icons.groups_outlined,
            title: l10n.hadithResearchRijalTitle,
            body: l10n.hadithResearchRijalBody,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RijalScreen()),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.hadithResearchNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ResearchCard extends StatelessWidget {
  const _ResearchCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
