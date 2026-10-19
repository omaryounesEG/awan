import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/midad/data/midad_engine.dart';
import 'package:awan/features/midad/domain/entities/midad_entities.dart';
import 'package:awan/features/midad/presentation/providers/midad_providers.dart';
import 'package:awan/features/quran_tafseer/domain/entities/quran_entities.dart';
import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/quran_tafseer/presentation/screens/quran_reader_screen.dart';
import 'package:awan/l10n/app_localizations.dart';

/// The letters a reader reaches for most: the muqatta'at and the high-frequency
/// ones. One tap is faster than an Arabic keyboard switch.
const List<String> _quickLetters = <String>[
  '\u0627', '\u0644', '\u0645', '\u0646', '\u0631', '\u0628',
  '\u064a', '\u0639', '\u062a', '\u062f', '\u0643', '\u0633',
];

/// Words a reader is most likely to measure first.
const List<String> _quickWords = <String>[
  '\u0627\u0644\u0644\u0647',
  '\u0627\u0644\u0631\u062d\u0645\u0646',
  '\u0627\u0644\u0631\u062d\u064a\u0645',
  '\u064a\u0648\u0645',
  '\u0627\u0644\u0646\u0627\u0633',
  '\u0642\u0644',
  '\u0631\u0628',
  '\u0627\u0644\u0643\u062a\u0627\u0628',
];

/// Thousands separators: a six-digit count read at a glance beats one read
/// twice.
String midadFormat(int n) {
  final String digits = n.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// «المِعداد» — a bench, not a table.
///
/// The reader sets four things (scope, unit, probe, conventions) and every
/// number on the screen answers that one question: the headline count, the
/// share of the scope, the heat map of where it concentrates, and the verses
/// where it is densest. Nothing here is stored, nothing leaves the device.
class MidadScreen extends ConsumerWidget {
  const MidadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<MidadIndex> index = ref.watch(midadIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.midadTitle),
            Text(
              l10n.midadSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.midadHowWeCount,
            icon: const Icon(Icons.rule_outlined),
            onPressed: () => _showMethod(context, ref),
          ),
        ],
      ),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        data: (MidadIndex data) => _Bench(index: data),
      ),
    );
  }
}

class _Bench extends ConsumerWidget {
  const _Bench({required this.index});

  final MidadIndex index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final MidadQuery query = ref.watch(midadQueryProvider);
    final AsyncValue<MidadResult> async = ref.watch(midadResultProvider);
    final MidadResult result = async.valueOrNull ??
        const MidadResult(
          total: 0,
          letters: 0,
          words: 0,
          ayahs: 0,
          bySurah: <int, int>{},
          top: <MidadVerseHit>[],
        );
    final QuranText? text = ref.watch(quranTextProvider).valueOrNull;

    void setQuery(MidadQuery next) =>
        ref.read(midadQueryProvider.notifier).state = next;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
      children: <Widget>[
        _ScopeSection(
          query: query,
          text: text,
          onScope: (MidadScope scope) => setQuery(query.copyWith(
            scope: scope,
            // A narrow scope with no place is the whole mushaf wearing another
            // name: start at its first unit instead.
            scopeValue: switch (scope) {
              MidadScope.surah => 1,
              MidadScope.juz => 1,
              MidadScope.page => 1,
              MidadScope.hizb => 1,
              _ => null,
            },
            clearScopeValue: const <MidadScope>{
              MidadScope.mushaf,
              MidadScope.meccan,
              MidadScope.medinan,
            }.contains(scope),
          )),
          onValue: (int? value) => setQuery(query.copyWith(scopeValue: value)),
        ),
        SizedBox(height: 12.h),
        _UnitSection(
          query: query,
          onUnit: (MidadUnit unit) => setQuery(query.copyWith(
            unit: unit,
            // A letter probe is meaningless as a word probe: start the new unit
            // from a sane placeholder instead of silently counting nothing.
            probe: unit == MidadUnit.word ? '' : '\u0627',
          )),
        ),
        SizedBox(height: 12.h),
        if (query.unit != MidadUnit.ayahLength)
          _ProbeField(
            key: ValueKey<String>('probe-${query.unit.name}'),
            unit: query.unit,
            initial: query.probe,
            onChanged: (String value) => setQuery(query.copyWith(probe: value)),
          ),
        if (query.unit == MidadUnit.letter ||
            query.unit == MidadUnit.fasila ||
            query.unit == MidadUnit.word) ...<Widget>[
          SizedBox(height: 6.h),
          SizedBox(
            height: 34.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: query.unit == MidadUnit.word
                  ? _quickWords.length
                  : _quickLetters.length,
              separatorBuilder: (_, __) => SizedBox(width: 4.w),
              itemBuilder: (BuildContext context, int i) {
                final String pick = query.unit == MidadUnit.word
                    ? _quickWords[i]
                    : _quickLetters[i];
                return ChoiceChip(
                  label: Text(
                    pick,
                    style: TextStyle(fontSize: 15.sp),
                  ),
                  selected: query.probe == pick,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setQuery(query.copyWith(probe: pick)),
                );
              },
            ),
          ),
        ],
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: <Widget>[
            FilterChip(
              label: Text(l10n.midadSimpleScript),
              selected: query.simpleScript,
              onSelected: (bool value) =>
                  setQuery(query.copyWith(simpleScript: value)),
            ),
            if (query.unit == MidadUnit.word)
              FilterChip(
                label: Text(l10n.midadWordInside),
                selected: query.wordInside,
                onSelected: (bool value) =>
                    setQuery(query.copyWith(wordInside: value)),
              ),
            FilterChip(
              label: Text(l10n.midadBasmala),
              selected: query.includeBasmala,
              // Counting the basmala where it is not a verse is a convention
              // about letters and words; it never adds verses.
              onSelected: query.unit == MidadUnit.letter ||
                      query.unit == MidadUnit.word
                  ? (bool value) =>
                      setQuery(query.copyWith(includeBasmala: value))
                  : null,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        _ResultCard(query: query, result: result),
        SizedBox(height: 18.h),
        Text(l10n.midadHeatmap,
            style: Theme.of(context).textTheme.titleSmall),
        Text(l10n.midadHeatmapHint,
            style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: 8.h),
        _Heatmap(
          result: result,
          onPick: (int surah) => setQuery(
            query.copyWith(scope: MidadScope.surah, scopeValue: surah),
          ),
        ),
        SizedBox(height: 18.h),
        if (result.top.isNotEmpty) ...<Widget>[
          Text(l10n.midadTopVerses,
              style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: 6.h),
          for (final MidadVerseHit hit in result.top)
            _VerseRow(hit: hit, text: text, query: query),
          SizedBox(height: 14.h),
        ],
        Text(l10n.midadInsights,
            style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: 8.h),
        _Insights(insights: index.insights, text: text, l10n: l10n),
      ],
    );
  }
}

/// A controlled field: the query holds the value, the controller holds the
/// caret. Rebuilding the widget must not rewrite what the reader is typing.
class _ProbeField extends StatefulWidget {
  const _ProbeField({
    super.key,
    required this.unit,
    required this.initial,
    required this.onChanged,
  });

  final MidadUnit unit;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_ProbeField> createState() => _ProbeFieldState();
}

class _ProbeFieldState extends State<_ProbeField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(covariant _ProbeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent only owns the value when it changes it from outside (a quick
    // letter); during typing the two already agree, so the caret stays put.
    if (widget.initial != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initial,
        selection: TextSelection.collapsed(offset: widget.initial.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.straighten),
        labelText: widget.unit == MidadUnit.word
            ? l10n.midadProbeWordHint
            : l10n.midadProbeLetterHint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ScopeSection extends StatelessWidget {
  const _ScopeSection({
    required this.query,
    required this.text,
    required this.onScope,
    required this.onValue,
  });

  final MidadQuery query;
  final QuranText? text;
  final ValueChanged<MidadScope> onScope;
  final ValueChanged<int?> onValue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<({MidadScope scope, String label})> scopes =
        <({MidadScope scope, String label})>[
      (scope: MidadScope.mushaf, label: l10n.midadScopeMushaf),
      (scope: MidadScope.surah, label: l10n.midadScopeSurah),
      (scope: MidadScope.juz, label: l10n.midadScopeJuz),
      (scope: MidadScope.page, label: l10n.midadScopePage),
      (scope: MidadScope.hizb, label: l10n.midadScopeHizb),
      (scope: MidadScope.meccan, label: l10n.midadScopeMeccan),
      (scope: MidadScope.medinan, label: l10n.midadScopeMedinan),
    ];

    final bool needsValue = query.scope == MidadScope.surah ||
        query.scope == MidadScope.juz ||
        query.scope == MidadScope.page ||
        query.scope == MidadScope.hizb;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 6.w,
          runSpacing: 2.h,
          children: <Widget>[
            for (final ({MidadScope scope, String label}) s in scopes)
              ChoiceChip(
                label: Text(s.label),
                selected: query.scope == s.scope,
                onSelected: (_) => onScope(s.scope),
              ),
          ],
        ),
        if (needsValue) ...<Widget>[
          SizedBox(height: 6.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.tune, size: 18),
              label: Text(_valueLabel(l10n, text)),
              onPressed: () => _pickValue(context),
            ),
          ),
        ],
      ],
    );
  }

  String _valueLabel(AppLocalizations l10n, QuranText? text) {
    final int? v = query.scopeValue;
    switch (query.scope) {
      case MidadScope.surah:
        if (v == null) return l10n.midadPickPlace;
        final QuranText? quran = text;
        final Surah? s = quran == null || v < 1 || v > quran.surahs.length
            ? null
            : quran.surahs[v - 1];
        return '${l10n.midadScopeSurah} $v${s == null ? '' : ' · ${s.nameAr}'}';
      case MidadScope.juz:
        return v == null ? l10n.midadPickPlace : '${l10n.midadScopeJuz} $v';
      case MidadScope.page:
        return v == null ? l10n.midadPickPlace : '${l10n.midadScopePage} $v';
      case MidadScope.hizb:
        return v == null ? l10n.midadPickPlace : '${l10n.midadScopeHizb} $v';
      default:
        return l10n.midadPickPlace;
    }
  }

  Future<void> _pickValue(BuildContext context) async {
    final AppLocalizations l10n = context.l10n;
    final int max;
    switch (query.scope) {
      case MidadScope.surah:
        max = 114;
      case MidadScope.juz:
        max = 30;
      case MidadScope.page:
        max = 604;
      case MidadScope.hizb:
        max = 240;
      default:
        return;
    }
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheet).size.height * 0.7,
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text(l10n.midadPickPlace),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(sheet).pop(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: max,
                  itemBuilder: (BuildContext context, int i) {
                    final int value = i + 1;
                    final QuranText? quran = text;
                    final String name = query.scope == MidadScope.surah &&
                            quran != null &&
                            value <= quran.surahs.length
                        ? quran.surahs[value - 1].nameAr
                        : '';
                    return ListTile(
                      dense: true,
                      title: Text(name.isEmpty ? '$value' : '$value · $name'),
                      selected: query.scopeValue == value,
                      onTap: () => Navigator.of(sheet).pop(value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onValue(picked);
  }
}

class _UnitSection extends StatelessWidget {
  const _UnitSection({required this.query, required this.onUnit});

  final MidadQuery query;
  final ValueChanged<MidadUnit> onUnit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<({MidadUnit unit, String label, IconData icon})> units =
        <({MidadUnit unit, String label, IconData icon})>[
      (unit: MidadUnit.letter, label: l10n.midadUnitLetter, icon: Icons.text_fields),
      (unit: MidadUnit.word, label: l10n.midadUnitWord, icon: Icons.short_text),
      (unit: MidadUnit.ayahLength, label: l10n.midadUnitAyah, icon: Icons.notes),
      (unit: MidadUnit.fasila, label: l10n.midadUnitFasila, icon: Icons.music_note),
    ];
    return Row(
      children: <Widget>[
        for (final ({MidadUnit unit, String label, IconData icon}) u in units) ...<Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: 6.w),
              child: InkWell(
                borderRadius: BorderRadius.circular(10.r),
                onTap: () => onUnit(u.unit),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: query.unit == u.unit
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(u.icon, size: 18.sp),
                      SizedBox(height: 2.h),
                      Text(u.label, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.query, required this.result});

  final MidadQuery query;
  final MidadResult result;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool ayahLength = query.unit == MidadUnit.ayahLength;
    final String headline = ayahLength
        ? result.averageLength.toStringAsFixed(1)
        : midadFormat(result.total);
    final String caption = switch (query.unit) {
      MidadUnit.letter => l10n.midadOfLetters(midadFormat(result.letters)),
      MidadUnit.word => l10n.midadOfWords(midadFormat(result.words)),
      MidadUnit.fasila => l10n.midadOfAyahs(midadFormat(result.ayahs)),
      MidadUnit.ayahLength => l10n.midadOfAyahCount(midadFormat(result.ayahs)),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.midadResult, style: theme.textTheme.labelMedium),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                headline,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(width: 8.w),
              if (!ayahLength)
                Text(
                  query.unit == MidadUnit.fasila
                      ? l10n.midadVerse
                      : l10n.midadCounted,
                  style: theme.textTheme.titleSmall,
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(caption, style: theme.textTheme.bodySmall),
          if (query.unit == MidadUnit.letter && result.letters > 0) ...<Widget>[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: (result.shareOfLetters * 100).clamp(0, 1),
                minHeight: 8.h,
                backgroundColor: theme.colorScheme.surface,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${(result.shareOfLetters * 100).toStringAsFixed(2)}%',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.result, required this.onPick});

  final MidadResult result;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    int max = 0;
    for (final int v in result.bySurah.values) {
      if (v > max) max = v;
    }

    // A Wrap, not a nested GridView: 114 cells inside a scrolling page do not
    // need their own scrollable, and a flat layout keeps every tap honest.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const int columns = 12;
        const double gap = 3;
        final double cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (int surah = 1; surah <= 114; surah++)
              _HeatCell(
                surah: surah,
                count: result.bySurah[surah] ?? 0,
                max: max,
                size: cell,
                theme: theme,
                onTap: () => onPick(surah),
              ),
          ],
        );
      },
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.surah,
    required this.count,
    required this.max,
    required this.size,
    required this.theme,
    required this.onTap,
  });

  final int surah;
  final int count;
  final int max;
  final double size;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double t = max == 0 ? 0 : count / max;
    final Color base = theme.colorScheme.surfaceContainerHighest;
    final Color color =
        count == 0 ? base : Color.lerp(base, theme.colorScheme.primary, 0.25 + 0.75 * t)!;
    final bool dark = count > 0 && t > 0.55;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4.r),
        ),
        alignment: Alignment.center,
        child: Text(
          '$surah',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9.sp,
            color: dark
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _VerseRow extends StatelessWidget {
  const _VerseRow({required this.hit, required this.text, required this.query});

  final MidadVerseHit hit;
  final QuranText? text;
  final MidadQuery query;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Surah? surah =
        text == null || hit.surah > text!.surahs.length ? null : text!.surahs[hit.surah - 1];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18.r,
        child: Text(midadFormat(hit.count),
            style: Theme.of(context).textTheme.labelSmall),
      ),
      title: Text(
        '${surah?.nameAr ?? ''} · ${hit.ayah}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        _snippet(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        tooltip: l10n.midadOpenVerse,
        icon: const Icon(Icons.open_in_new, size: 18),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => QuranReaderScreen(surah: hit.surah, ayah: hit.ayah),
          ),
        ),
      ),
    );
  }

  /// A window around the probe inside the verse, so the row shows *why* it is
  /// in the list rather than starting from «بسم الله».
  String _snippet() {
    final String t = hit.text;
    final String probe = query.probe.trim();
    if (probe.isEmpty) return t;
    final int at = t.indexOf(probe);
    if (at <= 0) return t;
    final int from = at - 20 < 0 ? 0 : at - 20;
    return '…${t.substring(from)}';
  }
}

class _Insights extends StatelessWidget {
  const _Insights({required this.insights, required this.text, required this.l10n});

  final MidadInsights insights;
  final QuranText? text;
  final AppLocalizations l10n;

  String _verseLabel(MidadVerseHit hit) {
    final Surah? surah = text == null || hit.surah > text!.surahs.length
        ? null
        : text!.surahs[hit.surah - 1];
    return '${surah?.nameAr ?? ''} ${hit.ayah}';
  }

  @override
  Widget build(BuildContext context) {
    final List<({String title, String value, String detail})> cards =
        <({String title, String value, String detail})>[
      (
        title: l10n.midadInsightTopLetter,
        value: insights.topLetter,
        detail: midadFormat(insights.topLetterCount),
      ),
      (
        title: l10n.midadInsightHapax,
        value: midadFormat(insights.hapaxWords),
        detail: insights.hapaxSamples.join(' · '),
      ),
      (
        title: l10n.midadInsightRarest,
        value: insights.rarestLetter,
        detail: '${insights.rarestLetterSurahs}',
      ),
      (
        title: l10n.midadInsightLongest,
        value: _verseLabel(insights.longestAyah),
        detail: midadFormat(insights.longestAyah.count),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 8.w) / 2;
        return Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: <Widget>[
            for (final ({String title, String value, String detail}) c in cards)
              SizedBox(
                width: width,
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(c.title,
                          style: Theme.of(context).textTheme.labelSmall),
                      SizedBox(height: 4.h),
                      Text(
                        c.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        c.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _showMethod(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = context.l10n;
  final MidadIndex index = await ref.read(midadIndexProvider.future);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheet) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.midadHowWeCount,
                style: Theme.of(sheet).textTheme.titleMedium),
            SizedBox(height: 10.h),
            Text(l10n.midadHowBody,
                style: Theme.of(sheet).textTheme.bodySmall),
            SizedBox(height: 14.h),
            Text(
              '${l10n.midadLettersTotal}: ${midadFormat(index.insights.totalLetters)}  ·  '
              '${l10n.midadWordsTotal}: ${midadFormat(index.insights.totalWords)}',
              style: Theme.of(sheet).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    ),
  );
}
