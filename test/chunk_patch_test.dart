import 'dart:io';
import 'dart:typed_data';

import 'package:awan/features/updates/data/datasources/chunk_patch.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fixtures are produced by the same `tools/make_patch.py` the release
/// script calls, so what passes here is exactly what ships.
void main() {
  final Directory fixtures = Directory('test/fixtures');
  Uint8List patchBytes() => File('${fixtures.path}/1.0.0__1.0.1.patch').readAsBytesSync();

  test('rebuilds the new file byte for byte', () async {
    final File out = File('${fixtures.path}/.out.bin');
    if (out.existsSync()) out.deleteSync();

    await applyChunkPatch(
      oldFile: File('${fixtures.path}/old.bin'),
      patch: patchBytes(),
      newFile: out,
    );

    expect(out.readAsBytesSync(), File('${fixtures.path}/new.bin').readAsBytesSync());
    out.deleteSync();
  });

  test('a patch cut from another build is refused before writing', () async {
    final File other = File('${fixtures.path}/.other_old.bin');
    other.writeAsBytesSync(List<int>.filled(9999, 7));
    final File out = File('${fixtures.path}/.out2.bin');

    await expectLater(
      applyChunkPatch(oldFile: other, patch: patchBytes(), newFile: out),
      throwsA(isA<ChunkPatchException>()),
    );

    other.deleteSync();
    if (out.existsSync()) out.deleteSync();
  });

  test('something that is not a patch is refused', () async {
    final Uint8List garbage = Uint8List.fromList(List<int>.generate(64, (int i) => i));
    expect(() => readPatchInfo(garbage), throwsA(isA<ChunkPatchException>()));
  });

  test('a truncated patch is refused instead of half-applied', () async {
    final Uint8List full = patchBytes();
    final Uint8List cut = full.sublist(0, 60);
    expect(() => readPatchInfo(cut), throwsA(isA<ChunkPatchException>()));
  });

  test('an empty patch is refused', () async {
    expect(() => readPatchInfo(Uint8List(0)), throwsA(isA<ChunkPatchException>()));
  });
}
