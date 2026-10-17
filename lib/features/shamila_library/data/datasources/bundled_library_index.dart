import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show ByteData, rootBundle;

/// The catalogue that ships inside the app.
///
/// The index is a few kilobytes — one row per book — while the books themselves
/// are megabytes each. So the index travels with the app and the *books* are
/// what get downloaded on demand: the library screen lists and searches with no
/// network at all, and a phone that moves off the home network still browses.
///
/// The published index still wins when it is reachable; this is the floor, not a
/// cache. Kept behind an interface so the repository can be tested without a
/// Flutter asset bundle.
abstract class BundledLibraryIndex {
  /// The parsed `library_index.json`, or `null` when it cannot be read.
  Future<Map<String, dynamic>?> load();

  /// The app's own archive for [bookId], or `null` when this build does not
  /// carry one.
  ///
  /// Every book the catalogue lists is shipped, so the library is readable with
  /// no network and no source configured at all; the install path only falls
  /// back to a download for a book a *later* index adds.
  Future<Uint8List?> archiveBytes(String bookId);
}

/// Reads [assetPath] out of the app bundle.
class AssetLibraryIndex implements BundledLibraryIndex {
  const AssetLibraryIndex({
    this.assetPath = 'assets/data/library_index.json',
  });

  final String assetPath;

  /// Where the shipped archives live inside the bundle, laid out exactly as the
  /// CDN does (`<id>.sqlite.zip`).
  static const String archivesDir = 'assets/library/books';

  @override
  Future<Uint8List?> archiveBytes(String bookId) async {
    try {
      final ByteData data =
          await rootBundle.load('$archivesDir/$bookId.sqlite.zip');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    try {
      final Object? decoded = jsonDecode(await rootBundle.loadString(assetPath));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      // A missing or malformed asset must not take the screen down: the caller
      // falls back to reporting what it has (or has not) got.
      return null;
    }
  }
}
