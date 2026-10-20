import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:awan/core/utils/extensions.dart';
import 'package:awan/features/adhkar/data/adhkar_audio_service.dart';
import 'package:awan/features/adhkar/domain/entities/adhkar_item.dart';
import 'package:awan/features/adhkar/presentation/providers/adhkar_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Car mode: the phone is on a mount, the reader is listening, and the only two
/// things worth touching are «التالي» and «إيقاف».
///
/// A dhikr that ends moves to the next one on its own and is recorded as
/// finished — that is why the session is passed in: listening *is* doing.
class AdhkarPlayerScreen extends ConsumerStatefulWidget {
  const AdhkarPlayerScreen({
    super.key,
    required this.session,
    this.startIndex = 0,
  });

  final AdhkarSession session;
  final int startIndex;

  @override
  ConsumerState<AdhkarPlayerScreen> createState() => _AdhkarPlayerScreenState();
}

class _AdhkarPlayerScreenState extends ConsumerState<AdhkarPlayerScreen> {
  late int _index = widget.startIndex;
  AdhkarAudioEvent _event = const AdhkarAudioEvent(state: 'idle');
  StreamSubscription<AdhkarAudioEvent>? _sub;
  bool _auto = true;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(adhkarAudioServiceProvider).events.listen(_onEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrent());
  }

  @override
  void dispose() {
    _sub?.cancel();
    ref.read(adhkarAudioServiceProvider).stop();
    super.dispose();
  }

  void _onEvent(AdhkarAudioEvent event) {
    if (!mounted) return;
    setState(() => _event = event);
    if (event.state == 'completed' && _auto) _next(complete: true);
  }

  Future<void> _playCurrent() async {
    final AdhkarChapter? chapter = ref.read(adhkarChapterProvider).valueOrNull;
    if (chapter == null || chapter.items.isEmpty) return;
    final AdhkarItem item = chapter.items[_index.clamp(0, chapter.items.length - 1)];
    final String? local =
        await ref.read(adhkarRepositoryProvider).localAudio(item.id);
    if (!mounted) return;
    await ref.read(adhkarAudioServiceProvider).play(
          local ?? item.audioUrl,
          title: item.textFor(Localizations.localeOf(context).languageCode),
        );
  }

  Future<void> _next({bool complete = false}) async {
    final AdhkarChapter? chapter = ref.read(adhkarChapterProvider).valueOrNull;
    if (chapter == null) return;
    final AdhkarItem current = chapter.items[_index];
    if (complete) {
      await ref.read(adhkarActionsProvider).complete(widget.session, current);
    }
    if (_index + 1 >= chapter.items.length) {
      await ref.read(adhkarAudioServiceProvider).stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adhkarPlayerFinished)),
      );
      return;
    }
    setState(() => _index++);
    await _playCurrent();
  }

  void _previous() {
    if (_index == 0) return;
    setState(() => _index--);
    _playCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AdhkarChapter? chapter = ref.watch(adhkarChapterProvider).valueOrNull;
    final bool loading = chapter == null;
    final List<AdhkarItem> items = chapter?.items ?? const <AdhkarItem>[];
    final AdhkarItem? item =
        items.isEmpty ? null : items[_index.clamp(0, items.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == AdhkarSession.morning
            ? l10n.adhkarMorning
            : l10n.adhkarEvening),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.adhkarCarMode,
            icon: const Icon(Icons.directions_car_outlined),
            onPressed: () => setState(() => _auto = !_auto),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: Column(
                  children: <Widget>[
                    // The index is a number pair inside an RTL paragraph, so
                    // it is wrapped LTR or "1 / 24" renders as "24 / 1".
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${_index + 1} / ${items.length}',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            item?.textFor(
                                  Localizations.localeOf(context).languageCode,
                                ) ??
                                '',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(height: 1.9),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (_event.duration > Duration.zero)
                      LinearProgressIndicator(
                        value: (_event.position.inMilliseconds /
                                _event.duration.inMilliseconds)
                            .clamp(0, 1),
                        minHeight: 6.h,
                      )
                    else
                      SizedBox(height: 6.h),
                    SizedBox(height: 14.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        IconButton.filledTonal(
                          iconSize: 34.sp,
                          onPressed: _previous,
                          icon: const Icon(Icons.skip_previous),
                        ),
                        IconButton.filled(
                          iconSize: 52.sp,
                          padding: EdgeInsets.all(14.w),
                          onPressed: () {
                            if (_event.playing) {
                              ref.read(adhkarAudioServiceProvider).pause();
                            } else if (_event.state == 'paused') {
                              ref.read(adhkarAudioServiceProvider).resume();
                            } else {
                              _playCurrent();
                            }
                          },
                          icon: Icon(
                            _event.playing
                                ? Icons.pause
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        IconButton.filledTonal(
                          iconSize: 34.sp,
                          onPressed: () => _next(complete: true),
                          icon: const Icon(Icons.skip_next),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          _auto ? Icons.autorenew : Icons.touch_app_outlined,
                          size: 15.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _auto ? l10n.adhkarAutoNextOn : l10n.adhkarAutoNextOff,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
