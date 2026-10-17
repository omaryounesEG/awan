import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:awan/features/recitation/data/datasources/mushaf_source.dart';
import 'package:awan/features/recitation/data/datasources/quran_word_database.dart';
import 'package:awan/features/recitation/data/datasources/recitation_audio.dart';
import 'package:awan/features/recitation/data/datasources/recitation_model_installer.dart';
import 'package:awan/features/recitation/data/datasources/wav_clip.dart';
import 'package:awan/features/recitation/data/datasources/whisper_engine.dart';
import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/domain/usecases/align_recitation.dart';
import 'package:awan/features/recitation/domain/usecases/speech_segmenter.dart';

enum RecitationPhase { idle, preparing, listening, thinking, error, complete }

/// What the screen draws, in one immutable object.
class RecitationSnapshot {
  const RecitationSnapshot({
    required this.phase,
    this.alignment,
    this.level = 0,
    this.latency = Duration.zero,
    this.heard,
    this.error,
    this.progress = 0,
    this.ayahText,
    this.surahName,
  });

  final RecitationPhase phase;
  final AyahAlignment? alignment;
  final double level;
  final Duration latency;

  /// The last transcript, shown verbatim so the user can judge the checker.
  final String? heard;
  final String? error;
  final double progress;
  final String? ayahText;
  final String? surahName;

  RecitationSnapshot copyWith({
    RecitationPhase? phase,
    AyahAlignment? alignment,
    double? level,
    Duration? latency,
    String? heard,
    String? error,
    double? progress,
    String? ayahText,
    String? surahName,
  }) {
    return RecitationSnapshot(
      phase: phase ?? this.phase,
      alignment: alignment ?? this.alignment,
      level: level ?? this.level,
      latency: latency ?? this.latency,
      heard: heard ?? this.heard,
      error: error ?? this.error,
      progress: progress ?? this.progress,
      ayahText: ayahText ?? this.ayahText,
      surahName: surahName ?? this.surahName,
    );
  }
}

/// Ties the five layers together: microphone → segmenter → Whisper → mushaf →
/// alignment, and publishes one snapshot per step.
///
/// The two rules that keep it honest:
/// * **the queue is serial** — one decode at a time, so a fast reciter cannot
///   pile up segments and melt the device;
/// * **the cursor belongs to the session, not to the recogniser** — a segment
///   that fails to decode leaves the cursor exactly where it was.
class RecitationRepository {
  RecitationRepository({
    QuranWordDatabase? database,
    MushafSource? mushaf,
    WhisperEngine? engine,
    RecitationAudio? audio,
    RecitationModelInstaller? installer,
    AlignRecitation? aligner,
    SpeechSegmenter Function()? segmenter,
  })  : database = database ?? QuranWordDatabase(),
 mushaf = mushaf ?? MushafSource(),
        engine = engine ?? WhisperEngine(),
        audio = audio ?? RecitationAudio(),
        installer = installer ?? RecitationModelInstaller(),
        aligner = aligner ?? const AlignRecitation(),
        _segmenterFactory = segmenter ?? (() => SpeechSegmenter());

  final QuranWordDatabase database;

  /// The verse text as the session reads it: the asset, parsed once. The
  /// SQLite tables are built in the background for word-level search, not on
  /// the path of the first recitation.
  final MushafSource mushaf;
  final WhisperEngine engine;
  final RecitationAudio audio;
  final RecitationModelInstaller installer;
  final AlignRecitation aligner;
  final SpeechSegmenter Function() _segmenterFactory;

  final StreamController<RecitationSnapshot> _controller =
      StreamController<RecitationSnapshot>.broadcast();

  Stream<RecitationSnapshot> get snapshots => _controller.stream;

  RecitationSnapshot _state = const RecitationSnapshot(phase: RecitationPhase.idle);
  RecitationSnapshot get state => _state;

  SpeechSegmenter _segmenter = SpeechSegmenter();
  StreamSubscription<Float32List>? _mic;
  final List<SpeechSegment> _queue = <SpeechSegment>[];
  bool _draining = false;
  bool _disposed = false;

  AyahAlignment? _session;
  String? _ayahText;
  String? _surahName;

  void _emit(RecitationSnapshot next) {
    _state = next;
    if (!_disposed && !_controller.isClosed) _controller.add(next);
  }

  /// Prepares the model (if installed), the database, and the verse.
  Future<void> prepare({required int surah, required int ayah, String? surahName}) async {
    _emit(_state.copyWith(phase: RecitationPhase.preparing, progress: 0));
    try {
      final List<RecitationWord> words = await mushaf.words(surah, ayah);
      _ayahText = await mushaf.ayahText(surah, ayah);
      // The word database is for searching, not for reciting: fill it while the
      // reader is already reading instead of making them wait for it.
      unawaited(
        database.ensureBuilt().catchError((Object _) => 0),
      );
      _surahName = surahName;
      _session = AyahAlignment(surah: surah, ayah: ayah, words: words);

      if (await installer.isInstalled()) {
        final Map<String, String> files = await installer.paths();
        await engine.start(
          encoder: files['base-ar-quran-encoder.int8.onnx']!,
          decoder: files['base-ar-quran-decoder.int8.onnx']!,
          tokens: files['base-ar-quran-tokens.txt']!,
        );
      }

      _emit(RecitationSnapshot(
        phase: RecitationPhase.idle,
        alignment: _session,
        progress: 1,
        ayahText: _ayahText,
        surahName: _surahName,
      ));
    } catch (error) {
      _emit(_state.copyWith(phase: RecitationPhase.error, error: 'prepare_failed: $error'));
    }
  }

  /// Opens the microphone. No model, no listening: the UI decides what to tell
  /// the user rather than showing a silent screen that pretends to work.
  Future<void> listen() async {
    if (_session == null) return;
    if (!engine.isReady) {
      _emit(_state.copyWith(phase: RecitationPhase.error, error: 'model_missing'));
      return;
    }
    if (!await audio.hasPermission()) {
      _emit(_state.copyWith(phase: RecitationPhase.error, error: 'mic_denied'));
      return;
    }

    _segmenter = _segmenterFactory();
    final Stream<Float32List> mic = await audio.start();
    _emit(_state.copyWith(phase: RecitationPhase.listening, error: null));
    _mic = mic.listen((Float32List chunk) {
      final List<SpeechSegment> finished = _segmenter.accept(chunk);
      _emit(_state.copyWith(level: _segmenter.level.clamp(0, 1)));
      for (final SpeechSegment segment in finished) {
        _queue.add(segment);
      }
      unawaited(_drain());
    });
  }

  Future<void> stop() async {
    await _mic?.cancel();
    _mic = null;
    final SpeechSegment? last = _segmenter.flush();
    if (last != null) _queue.add(last);
    await _drain();
    _emit(_state.copyWith(phase: RecitationPhase.idle, level: 0));
  }

  /// Feeds a WAV clip through the exact same path as the microphone. Used by
  /// the demo screen and by the on-device verification run.
  Future<void> feed(File wav, {bool realTime = false}) async {
    if (_session == null || !engine.isReady) return;
    final WavClip clip = WavClip.read(wav);
    if (!clip.isWhisperReady) {
      _emit(_state.copyWith(
        phase: RecitationPhase.error,
        error: 'wav_needs_16k_mono (got ${clip.sampleRate}Hz/${clip.channels}ch)',
      ));
      return;
    }
    _segmenter = _segmenterFactory();
    _emit(_state.copyWith(phase: RecitationPhase.listening));

    const int chunk = 3200; // 200 ms
    for (int i = 0; i < clip.samples.length; i += chunk) {
      final int end = (i + chunk).clamp(0, clip.samples.length);
      final Float32List piece = Float32List.sublistView(clip.samples, i, end);
      for (final SpeechSegment segment in _segmenter.accept(piece)) {
        _queue.add(segment);
      }
      if (realTime) await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    final SpeechSegment? tail = _segmenter.flush();
    if (tail != null) _queue.add(tail);
    await _drain();
    _emit(_state.copyWith(phase: RecitationPhase.idle, level: 0));
  }

  /// Runs the bundled ayah through the whole pipeline — the demo button, and
  /// how the pipeline is verified without a human at the microphone.
  Future<void> feedSample() async {
    final ByteData data = await rootBundle.load('assets/recitation/sample.wav');
    final Directory dir = await getTemporaryDirectory();
    final File file = File(p.join(dir.path, 'awan_sample.wav'));
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    await feed(file);
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final SpeechSegment segment = _queue.removeAt(0);
        if (!SpeechSegmenter.worthDecoding(segment)) continue;
        _emit(_state.copyWith(phase: RecitationPhase.thinking));
        final Stopwatch watch = Stopwatch()..start();
        final RecitationDecode decode = await engine.decode(segment.samples);
        if (decode.words.isEmpty) {
          _emit(_state.copyWith(phase: RecitationPhase.listening));
          continue;
        }
        final AyahAlignment next = aligner(
          session: _session!,
          heard: decode.words,
        );
        _session = next;
        _emit(_state.copyWith(
          phase: next.isComplete ? RecitationPhase.complete : RecitationPhase.listening,
          alignment: next,
          latency: Duration(milliseconds: decode.milliseconds),
          heard: decode.text,
          error: null,
        ));
        watch.stop();
      }
    } catch (error) {
      _emit(_state.copyWith(phase: RecitationPhase.error, error: 'decode_failed: $error'));
    } finally {
      _draining = false;
    }
  }

  /// Moves to the next ayah of the surah (called when one is finished).
  Future<void> gotoAyah(int surah, int ayah, {String? surahName}) async {
    await stop();
    await prepare(surah: surah, ayah: ayah, surahName: surahName);
  }

  Future<int> installModel({
    required List<ModelSource> sources,
    void Function(double progress)? onProgress,
    void Function(ModelSource source)? onSource,
  }) async {
    await installer.install(
      sources: sources,
      onProgress: (double p) {
        onProgress?.call(p);
        _emit(_state.copyWith(phase: RecitationPhase.preparing, progress: p));
      },
      onSource: onSource,
    );
    return installer.installedBytes();
  }

  Future<void> dispose() async {
    _disposed = true;
    await audio.dispose();
    await engine.dispose();
    await database.close();
    await _controller.close();
  }
}
