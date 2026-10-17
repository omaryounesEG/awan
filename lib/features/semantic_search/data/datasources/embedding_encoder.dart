import 'dart:typed_data';

import 'package:flutter/services.dart';

/// The ONNX graph, through the app's own Kotlin channel.
///
/// A plain method channel rather than an ONNX plugin: the plugin's current
/// releases need Dart 3.7 and this project is pinned to the Flutter 3.24
/// toolchain, and the native side is 80 lines of `OrtSession` anyway.
class EmbeddingEncoder {
  const EmbeddingEncoder();

  static const MethodChannel _channel = MethodChannel('awan/semantic');

  /// Whether the model file is present and a session could be built.
  Future<({bool ready, int bytes, String? error})> status() async {
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('status');
      return (
        ready: raw?['ready'] == true,
        bytes: (raw?['bytes'] as num?)?.toInt() ?? 0,
        error: raw?['error'] as String?,
      );
    } on PlatformException catch (error) {
      return (ready: false, bytes: 0, error: error.message);
    } on MissingPluginException {
      return (ready: false, bytes: 0, error: 'no-platform');
    }
  }

  /// Copies the bundled model out of the APK (first run) and opens a session.
  Future<({bool ready, int bytes, String? error})> prepare() async {
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMethod<Map<Object?, Object?>>('prepare');
      return (
        ready: raw?['ready'] == true,
        bytes: (raw?['bytes'] as num?)?.toInt() ?? 0,
        error: raw?['error'] as String?,
      );
    } on PlatformException catch (error) {
      return (ready: false, bytes: 0, error: error.message);
    } on MissingPluginException {
      return (ready: false, bytes: 0, error: 'no-platform');
    }
  }

  /// A normalised 384-float sentence vector, or null when the model is absent.
  Future<Float64List?> encode(List<int> ids, List<int> mask) async {
    try {
      final List<Object?>? raw = await _channel.invokeMethod<List<Object?>>(
        'encode',
        <String, Object?>{'ids': ids, 'mask': mask},
      );
      if (raw == null) return null;
      final Float64List vector = Float64List(raw.length);
      for (int i = 0; i < raw.length; i++) {
        vector[i] = (raw[i] as num).toDouble();
      }
      return vector;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
