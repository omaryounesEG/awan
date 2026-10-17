import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/presentation/providers/knowledge_graph_providers.dart';
import 'package:awan/features/knowledge_graph/presentation/screens/graph_screen.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/mutashabih_node_views.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The Mutashabihat graph on the home screen.
///
/// Its subtitle is the corpus, counted: after the first open it can say how
/// many ayat and links are on the device, which is the one thing a shortcut
/// into a diagram can usefully promise.
class MutashabihatShortcutCard extends ConsumerWidget {
  const MutashabihatShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<MutashabihatSeedReport> seed =
        ref.watch(mutashabihatSeedProvider);
    final MutashabihatSeedReport? report = seed.valueOrNull;

    final String subtitle = report == null || report.nodes == 0
        ? l10n.graphShortcutEmpty
        : l10n.graphShortcutReady(report.nodes, report.targets);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const GraphScreen(
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kMutashabihSourceColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub_outlined, color: kMutashabihSourceColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.graphTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
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
