import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Runs Whisper off the UI thread, in an isolate that owns the model.
///
/// The architecture note is blunt about this: a Whisper decode is hundreds of
/// milliseconds of matrix maths, and doing it on the frame thread is how a
/// recitation screen turns into a slideshow. sherpa-onnx is FFI over a C++
/// runtime, so the work runs natively — but the *call* still blocks the isolate
/// that makes it, which is why the recogniser lives in a worker isolate and the
/// UI only ever awaits a Future.
///
/// One isolate, created once, reused for every segment: creating a recogniser
/// loads ~160 MB of weights, which is not something to do per ayat.
class WhisperEngine {
  Isolate? _isolate;
  SendPort? _commands;
  ReceivePort? _replies;
  final Map<int, Completer<RecitationDecode>> _pending =
      <int, Completer<RecitationDecode>>{};
  int _nextId = 1;
  bool _ready = false;

  bool get isReady => _ready;

  /// Loads the three files into the worker. Safe to call twice.
  Future<void> start({
    required String encoder,
    required String decoder,
    required String tokens,
    String language = 'ar',
    int threads = 2,
  }) async {
    if (_ready) return;

    _replies = ReceivePort();
    _isolate = await Isolate.spawn(
      _whisperMain,
      <String, dynamic>{
        'send': _replies!.sendPort,
        'encoder': encoder,
        'decoder': decoder,
        'tokens': tokens,
        'language': language,
        'threads': threads,
      },
      debugName: 'awan-whisper',
    );

    final Completer<void> loaded = Completer<void>();
    StreamSubscription<dynamic>? subscription;
    subscription = _replies!.listen((dynamic message) {
      if (message is Map && message['type'] == 'ready') {
        _commands = message['send'] as SendPort;
        _ready = true;
        if (!loaded.isCompleted) loaded.complete();
        return;
      }
      if (message is Map && message['type'] == 'error' && !loaded.isCompleted) {
        loaded.completeError(StateError(message['message'] as String));
        return;
      }
      if (message is Map && message['type'] == 'result') {
        final Completer<RecitationDecode>? completer =
            _pending.remove(message['id']);
        completer?.complete(
          RecitationDecode(
            text: (message['text'] as String?) ?? '',
            milliseconds: (message['ms'] as int?) ?? 0,
          ),
        );
      }
    });

    await loaded.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => throw StateError('whisper_load_timeout'),
    );
    // Keep listening for results after the load handshake.
    subscription.onDone(() {});
  }

  /// Decodes one segment. The returned Future completes when the worker is done.
  Future<RecitationDecode> decode(List<double> samples) async {
    if (!_ready || _commands == null) {
      throw StateError('whisper_not_ready');
    }
    final int id = _nextId++;
    final Completer<RecitationDecode> completer = Completer<RecitationDecode>();
    _pending[id] = completer;
    _commands!.send(<String, dynamic>{
      'id': id,
      'samples': Float32List.fromList(samples),
    });
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('whisper_decode_timeout');
      },
    );
  }

  Future<void> dispose() async {
    _commands?.send(<String, dynamic>{'cmd': 'quit'});
    _replies?.close();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _ready = false;
  }
}

class RecitationDecode {
  const RecitationDecode({required this.text, required this.milliseconds});
  final String text;
  final int milliseconds;

  List<String> get words => text
      .split(RegExp(r'\s+'))
      .map((String w) => w.trim())
      .where((String w) => w.isNotEmpty)
      .toList();
}

/// The worker. Everything here runs off the UI isolate.
@pragma('vm:entry-point')
void _whisperMain(Map<String, dynamic> args) {
  final SendPort reply = args['send'] as SendPort;
  final ReceivePort commands = ReceivePort();

  sherpa.OfflineRecognizer? recognizer;
  try {
    sherpa.initBindings();
    final sherpa.OfflineRecognizerConfig config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: args['encoder'] as String,
          decoder: args['decoder'] as String,
          language: args['language'] as String? ?? 'ar',
          task: 'transcribe',
          // The tail is padded so the last word of a segment is not clipped by
          // the window: exactly the 0.5 s overlap guard, applied at the model.
          tailPaddings: 1000,
        ),
        tokens: args['tokens'] as String,
        numThreads: args['threads'] as int? ?? 2,
        debug: false,
        provider: 'cpu',
      ),
      feat: const sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
      decodingMethod: 'greedy_search',
    );
    recognizer = sherpa.OfflineRecognizer(config);
  } catch (error) {
    reply.send(<String, dynamic>{'type': 'error', 'message': '$error'});
    commands.close();
    return;
  }

  reply.send(<String, dynamic>{'type': 'ready', 'send': commands.sendPort});

  commands.listen((dynamic message) {
    if (message is! Map) return;
    if (message['cmd'] == 'quit') {
      recognizer?.free();
      commands.close();
      return;
    }
    final int id = message['id'] as int;
    final Float32List samples = message['samples'] as Float32List;
    final Stopwatch watch = Stopwatch()..start();
    try {
      final sherpa.OfflineStream stream = recognizer!.createStream();
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      final String text = recognizer.getResult(stream).text;
      stream.free();
      reply.send(<String, dynamic>{
        'type': 'result',
        'id': id,
        'text': text,
        'ms': watch.elapsedMilliseconds,
      });
    } catch (error) {
      reply.send(<String, dynamic>{
        'type': 'result',
        'id': id,
        'text': '',
        'ms': watch.elapsedMilliseconds,
        'error': '$error',
      });
    }
  });
}
