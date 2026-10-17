import 'dart:io';
import 'dart:typed_data';

/// Applies an `AWANPCH1` delta (produced by `tools/make_patch.py`) to the APK
/// this app is running from, producing the new APK.
///
/// Why not a store: Android's installer only accepts a whole APK, and stores
/// compute deltas on their own side. Since the release channel is a plain
/// GitHub release, the app rebuilds the APK itself — copying unchanged regions
/// from the installed file and writing changed ones from the patch.
///
/// Everything here is bounded: the old APK is read in chunks, the literal
/// stream is decoded once (usually a few MB), and the output is written
/// sequentially. A 93 MB APK never has to exist twice in memory.
class ChunkPatchException implements Exception {
  const ChunkPatchException(this.message);
  final String message;
  @override
  String toString() => 'ChunkPatchException: $message';
}

/// Facts from the 48-byte header, checked before anything is written.
class PatchInfo {
  const PatchInfo({
    required this.oldSize,
    required this.newSize,
    required this.opCount,
    required this.opsLength,
    required this.literalsLength,
  });

  final int oldSize;
  final int newSize;
  final int opCount;
  final int opsLength;
  final int literalsLength;
}

const int _headerBytes = 48;
const List<int> _magic = <int>[0x41, 0x57, 0x41, 0x4E, 0x50, 0x43, 0x48, 0x31];

PatchInfo readPatchInfo(Uint8List patch) {
  if (patch.length < _headerBytes) {
    throw const ChunkPatchException('patch is shorter than its header');
  }
  for (int i = 0; i < _magic.length; i++) {
    if (patch[i] != _magic[i]) {
      throw const ChunkPatchException('not an AWANPCH1 patch');
    }
  }
  final ByteData h = ByteData.sublistView(patch, 0, _headerBytes);
  final PatchInfo info = PatchInfo(
    oldSize: h.getUint64(8, Endian.little),
    newSize: h.getUint64(16, Endian.little),
    opCount: h.getUint32(24, Endian.little),
    opsLength: h.getUint64(32, Endian.little),
    literalsLength: h.getUint64(40, Endian.little),
  );
  if (info.newSize <= 0 || info.opCount <= 0) {
    throw const ChunkPatchException('patch declares no content');
  }
  if (_headerBytes + info.opsLength + info.literalsLength > patch.length) {
    throw const ChunkPatchException('declared streams exceed the patch size');
  }
  return info;
}

/// Rebuilds [newFile] from [oldFile] + [patch].
///
/// The caller must still verify the result's SHA-256 against the published
/// build: this function proves the bytes add up, not that they are the right
/// ones.
Future<void> applyChunkPatch({
  required File oldFile,
  required Uint8List patch,
  required File newFile,
}) async {
  final PatchInfo info = readPatchInfo(patch);

  const int opsStart = _headerBytes;
  final int litsStart = opsStart + info.opsLength;
  final Uint8List ops = _inflate(patch.sublist(opsStart, litsStart));
  final Uint8List literals = _inflate(patch.sublist(litsStart, litsStart + info.literalsLength));

  if (ops.length != info.opCount * 17) {
    throw const ChunkPatchException('ops stream does not match the declared op count');
  }

  final RandomAccessFile old = await oldFile.open();
  final RandomAccessFile out = await newFile.open(mode: FileMode.write);
  try {
    final int oldLength = await old.length();
    if (oldLength != info.oldSize) {
      throw const ChunkPatchException(
        'patch is for a different build of the app — sizes do not match',
      );
    }

    final ByteData view = ByteData.sublistView(ops);
    int opPos = 0;
    int litPos = 0;
    int written = 0;

    while (opPos < ops.length) {
      final int kind = ops[opPos];
      final int offset = view.getUint64(opPos + 1, Endian.little);
      final int length = view.getUint64(opPos + 9, Endian.little);
      opPos += 17;

      if (length <= 0 || written + length > info.newSize) {
        throw const ChunkPatchException('op writes past the declared new size');
      }

      if (kind == 0) {
        if (offset + length > oldLength) {
          throw const ChunkPatchException('copy reads past the end of the installed APK');
        }
        await old.setPosition(offset);
        final Uint8List block = await old.read(length);
        if (block.length != length) {
          throw const ChunkPatchException('short read from the installed APK');
        }
        await out.writeFrom(block);
      } else if (kind == 1) {
        if (litPos + length > literals.length) {
          throw const ChunkPatchException('literal reads past the end of its stream');
        }
        await out.writeFrom(literals, litPos, litPos + length);
        litPos += length;
      } else {
        throw ChunkPatchException('unknown op kind $kind');
      }
      written += length;
    }

    if (written != info.newSize) {
      throw const ChunkPatchException('rebuilt file is not the declared size');
    }
  } finally {
    await old.close();
    await out.close();
  }
}

Uint8List _inflate(Uint8List bytes) {
  try {
    return Uint8List.fromList(ZLibDecoder().convert(bytes));
  } catch (_) {
    throw const ChunkPatchException('corrupt compressed stream in patch');
  }
}
