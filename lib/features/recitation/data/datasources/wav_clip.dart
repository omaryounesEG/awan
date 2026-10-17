import 'dart:io';
import 'dart:typed_data';

/// A minimal RIFF/WAVE reader — just enough to replay a 16 kHz mono clip
/// through the checker on a device that has no microphone.
///
/// It exists because the honest way to test a speech feature without a human
/// in front of the phone is to feed it a known recording, and the WAV byte
/// layout is small enough that a dependency would cost more than it saves.
class WavClip {
  const WavClip({required this.samples, required this.sampleRate, required this.channels});

  final Float32List samples;
  final int sampleRate;
  final int channels;

  bool get isWhisperReady => sampleRate == 16000 && channels == 1;

  static WavClip read(File file) {
    final ByteData data = ByteData.sublistView(file.readAsBytesSync());
    if (String.fromCharCodes(data.buffer.asUint8List(0, 4)) != 'RIFF') {
      throw const FormatException('not a RIFF file');
    }
    if (String.fromCharCodes(data.buffer.asUint8List(8, 4)) != 'WAVE') {
      throw const FormatException('not a WAVE file');
    }

    int offset = 12;
    int sampleRate = 16000;
    int channels = 1;
    int bitsPerSample = 16;
    int dataStart = -1;
    int dataLength = 0;

    while (offset + 8 <= data.lengthInBytes) {
      final String id = String.fromCharCodes(
        data.buffer.asUint8List(data.offsetInBytes + offset, 4),
      );
      final int size = data.getUint32(offset + 4, Endian.little);

      if (id == 'fmt ') {
        channels = data.getUint16(offset + 10, Endian.little);
        sampleRate = data.getUint32(offset + 12, Endian.little);
        bitsPerSample = data.getUint16(offset + 22, Endian.little);
      } else if (id == 'data') {
        dataStart = offset + 8;
        dataLength = size;
        break;
      }
      offset += 8 + size + (size.isOdd ? 1 : 0);
    }

    if (dataStart < 0) throw const FormatException('no data chunk');
    if (bitsPerSample != 16) {
      throw FormatException('expected 16-bit PCM, found $bitsPerSample-bit');
    }

    final int count = dataLength ~/ 2;
    final Float32List samples = Float32List(count);
    for (int i = 0; i < count; i++) {
      samples[i] = data.getInt16(dataStart + i * 2, Endian.little) / 32768.0;
    }
    return WavClip(samples: samples, sampleRate: sampleRate, channels: channels);
  }
}
