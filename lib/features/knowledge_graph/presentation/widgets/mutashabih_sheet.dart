import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/features/knowledge_graph/domain/entities/mutashabih_entities.dart';
import 'package:awan/features/knowledge_graph/presentation/providers/knowledge_graph_providers.dart';
import 'package:awan/features/knowledge_graph/presentation/screens/graph_screen.dart';
import 'package:awan/features/knowledge_graph/presentation/widgets/mutashabih_node_views.dart';
import 'package:awan/features/quran_tafseer/presentation/quran_appearance.dart';
import 'package:awan/l10n/app_localizations.dart';

/// What a tapped target node says.
///
/// The ayah itself is the headline — it is the thing the reader wants to read
/// and compare — and the rule (الضابط) sits directly under it as the answer to
/// "why are these two together?". The ayah is drawn in the reader's own Mushaf
/// font and palette so it looks like the Quran everywhere else in the app.
Future<void> showMutashabihSheet({
  required BuildContext context,
  required MutashabihTargetEntry target,
  required QuranAppearance appearance,
  required String Function(int surah, int ayah) labelFor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) => _MutashabihSheetBody(
      target: target,
      appearance: appearance,
      labelFor: labelFor,
    ),
  );
}

class _MutashabihSheetBody extends ConsumerWidget {
  const _MutashabihSheetBody({
    required this.target,
    required this.appearance,
    required this.labelFor,
  });

  final MutashabihTargetEntry target;
  final QuranAppearance appearance;
  final String Function(int surah, int ayah) labelFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    // Only offer the jump when the corpus actually has a graph for that ayah:
    // a primary-key lookup, so asking is cheaper than a dead button.
    final AsyncValue<MutashabihNodeEntry?> asNode =
        ref.watch(similaritiesProvider(target.targetAbsoluteId));
    final bool hasOwnGraph = (asNode.valueOrNull?.targetCount ?? 0) > 0;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(20.w, 4.h, 20.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: const BoxDecoration(
                      color: kMutashabihTargetColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    labelFor(target.targetSurahNumber, target.targetAyahNumber),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // The similar ayah, in the Mushaf face the reader chose.
              Text(
                target.targetText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appearance.font.family,
                  fontFamilyFallback: kQuranFallback,
                  fontSize: 24.sp,
                  height: 2.0,
                  color: appearance.palette.text,
                ),
              ),
              SizedBox(height: 18.h),

              // The rule (الضابط) — the reason this pair is on the graph.
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: appearance.palette.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: appearance.palette.accent.withOpacity(0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.rule_folder_outlined,
                            size: 18.sp, color: appearance.palette.accent),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.graphRuleLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: appearance.palette.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.graphRuleHint,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: appearance.palette.dim),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      target.ruleText,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ),

              if (hasOwnGraph) ...<Widget>[
                SizedBox(height: 16.h),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GraphScreen(
                          absoluteAyahId: target.targetAbsoluteId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.hub_outlined),
                  label: Text(l10n.graphOpenTarget),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
