import 'dart:math' as math;
import 'dart:typed_data';

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';

/// Finds where one recitation segment ends and the next begins.
///
/// The architecture note is precise about why this matters: a reciter pauses at
/// a verse end or a waqf sign, and Whisper needs the pause to be a boundary, not
/// a random 2-second cut through the middle of a word. So silence is the
/// trigger, with three guards taken from the note:
///
/// * **400 ms of silence** closes a segment;
/// * **5 s of unbroken speech** closes it anyway, keeping **0.5 s of overlap**
///   so the next segment starts inside the previous one and no letter is lost
///   at the seam;
/// * a **minimum of 250 ms of speech** stops a cough or a page turn from
///   producing a segment.
///
/// Written in plain Dart over float samples: the threshold logic is the part
/// that can be wrong, so it is the part that is tested with synthetic audio
/// rather than with a microphone.
class SpeechSegmenter {
  SpeechSegmenter({
    this.sampleRate = 16000,
    this.minSpeech = const Duration(milliseconds: 250),
    this.silenceHang = const Duration(milliseconds: 400),
    this.maxSegment = const Duration(seconds: 5),
    this.overlap = const Duration(milliseconds: 500),
    this.noiseMultiplier = 3.0,
    this.absoluteFloor = 0.006,
  });

  final int sampleRate;
  final Duration minSpeech;
  final Duration silenceHang;
  final Duration maxSegment;
  final Duration overlap;

  /// How far above the room's own noise a frame must sit to count as speech.
  final double noiseMultiplier;

  /// Never treat anything quieter than this as speech, whatever the room.
  final double absoluteFloor;

  int get _silenceFrames => (silenceHang.inMilliseconds * sampleRate / 1000).round();
  int get _minSpeechFrames => (minSpeech.inMilliseconds * sampleRate / 1000).round();
  int get _maxFrames => (maxSegment.inMilliseconds * sampleRate / 1000).round();
  int get _overlapFrames => (overlap.inMilliseconds * sampleRate / 1000).round();

  /// 20 ms frames: long enough for a stable RMS, short enough that a pause is
  /// detected within a syllable.
  int get frameSize => sampleRate ~/ 50;

  final List<double> _buffer = <double>[];
  double _noiseFloor = 0.004;
  int _speechRun = 0;
  int _silenceRun = 0;
  int _framesSeen = 0;

  /// Everything collected since the current segment began, in samples.
  final List<double> _segment = <double>[];

  /// Feeds a chunk of audio and returns the segments it completed.
  List<SpeechSegment> accept(List<double> samples, {Duration? at}) {
    final List<SpeechSegment> finished = <SpeechSegment>[];
    _buffer.addAll(samples);

    while (_buffer.length >= frameSize) {
      final List<double> frame = _buffer.sublist(0, frameSize);
      _buffer.removeRange(0, frameSize);

      final double rms = _rms(frame);
      final bool loud = rms > math.max(absoluteFloor, _noiseFloor * noiseMultiplier);

      // The floor only learns from quiet frames, slowly: a sudden recitation
      // must not raise it and silence itself.
      if (!loud) _noiseFloor = _noiseFloor * 0.98 + rms * 0.02;

      _framesSeen++;
      if (loud) {
        _speechRun += frameSize;
        _silenceRun = 0;
        _segment.addAll(frame);
      } else {
        _silenceRun += frameSize;
        if (_speechRun > 0) _segment.addAll(frame);
      }

      // Unbroken speech: cut at the ceiling, keep the tail for the next one.
      if (_speechRun >= _maxFrames) {
        final segment = _take(_maxFrames, keepOverlap: true, at: at);
        if (segment != null) finished.add(segment);
        continue;
      }

      // A pause after real speech closes the segment.
      if (_speechRun >= _minSpeechFrames && _silenceRun >= _silenceFrames) {
        final segment = _take(_segment.length, keepOverlap: false, at: at);
        if (segment != null) finished.add(segment);
      }

      // Long quiet: reset the counters so the next speech starts clean.
      if (_speechRun == 0 && _silenceRun > _silenceFrames * 4) {
        _silenceRun = 0;
        _segment.clear();
      }
    }
    return finished;
  }

  /// Ends whatever is buffered — used when the user stops the session, so the
  /// last words are not thrown away.
  SpeechSegment? flush({Duration? at}) {
    if (_speechRun < _minSpeechFrames || _segment.isEmpty) {
      _reset();
      return null;
    }
    final segment = _take(_segment.length, keepOverlap: false, at: at);
    return segment;
  }

  SpeechSegment? _take(int count, {required bool keepOverlap, Duration? at}) {
    if (_segment.length < _minSpeechFrames) {
      _reset();
      return null;
    }
    final List<double> samples = _segment.sublist(0, math.min(count, _segment.length));
    final List<double> tail = keepOverlap && samples.length > _overlapFrames
        ? samples.sublist(samples.length - _overlapFrames)
        : <double>[];

    _reset();
    if (tail.isNotEmpty) {
      _segment.addAll(tail);
      _speechRun = tail.length;
    }

    final Duration end = at ?? Duration.zero;
    final Duration start = end - Duration(milliseconds: (samples.length * 1000 / sampleRate).round());
    return SpeechSegment(
      samples: samples,
      startedAt: start.isNegative ? Duration.zero : start,
      endedAt: end,
    );
  }

  void _reset() {
    _segment.clear();
    _speechRun = 0;
    _silenceRun = 0;
  }

  double _rms(List<double> frame) {
    double sum = 0;
    for (final double v in frame) {
      sum += v * v;
    }
    return math.sqrt(sum / frame.length);
  }

  /// Current level, for the waveform the user watches while reciting.
  double get level {
    if (_segment.isEmpty) return 0;
    final int from = math.max(0, _segment.length - frameSize);
    return _rms(_segment.sublist(from));
  }

  /// Exposed for the diagnostics panel: frames seen since the last reset.
  int get framesSeen => _framesSeen;

  /// Whether a segment is long enough to be worth a decode.
  ///
  /// Below about two seconds Whisper does not transcribe, it *invents*: a 1.5 s
  /// tail of al-Fatiha came back as «وَالْمُؤْ» on the device, and the checker
  /// then reported a wrong word to a correctly reciting user. That is the worst
  /// failure mode this feature has — accusing the innocent — so fragments too
  /// short to be trusted are dropped. The 0.5 s overlap means their words were
  /// already heard by the segment before them; a word left pending is a fair
  /// price, a false accusation is not.
  static bool worthDecoding(SpeechSegment segment, {double minSeconds = 2.0}) {
    return segment.seconds >= minSeconds;
  }
}

/// Converts the 16-bit little-endian PCM the microphone delivers into the float
/// samples Whisper expects. Kept here so both the live path and the file path
/// share one conversion.
Float32List pcm16ToFloat(Uint8List bytes) {
  final int count = bytes.length ~/ 2;
  final Float32List out = Float32List(count);
  final ByteData data = ByteData.sublistView(bytes);
  for (int i = 0; i < count; i++) {
    out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}
