import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/knowledge_graph/data/models/mutashabih_node.dart';
import 'package:awan/features/mosque_radar/data/models/mosque_cache_entry.dart';
import 'package:awan/features/prayer_engine/data/models/cached_prayer_day.dart';
import 'package:awan/features/quran_tafseer/data/models/quran_mark.dart';
import 'package:awan/features/quran_tafseer/data/models/tafsir_package_entry.dart';
import 'package:awan/features/shamila_library/data/models/book_chunk.dart';
import 'package:awan/features/shamila_library/data/models/library_book.dart';

/// Owns the single Isar instance.
///
/// Opened once from `main()` and handed to the widget tree through a Riverpod
/// override, so no widget ever awaits a database open.
///
/// Isar is a *single* database per app, which is why the schema list — and only
/// the schema list — lives here while each `@collection` class stays inside the
/// feature that owns it. Collections are addressed through
/// `isar.collection<T>()`, so no generated accessor name (and no pluralisation
/// surprise) leaks into the rest of the code.
class IsarService {
  IsarService._(this.isar);

  final Isar isar;

  static Future<IsarService> open() async {
    final Isar isar = await Isar.open(
      <CollectionSchema<dynamic>>[
        CachedPrayerDaySchema,
        MosqueCacheEntrySchema,
        QuranMarkSchema,
        ReadingPositionSchema,
        LibraryBookSchema,
        LibrarySyncStampSchema,
        BookChunkRowSchema,
        TafsirPackageEntrySchema,
        MutashabihNodeSchema,
      ],
      directory: (await getApplicationDocumentsDirectory()).path,
      name: AppConstants.isarDbName,
      inspector: false,
    );
    return IsarService._(isar);
  }

  Future<void> close() => isar.close();

  // ------------------------------------------------------------- collections
  IsarCollection<T> collection<T extends Object>() => isar.collection<T>();

  // ------------------------------------------------------------- maintenance
  /// Drops mosque cells that outlived the cache window (48 h by default).
  Future<int> pruneMosqueCache({Duration ttl = AppConstants.mosqueCacheTtl}) {
    final DateTime cutoff = DateTime.now().subtract(ttl);
    return isar.writeTxn(
      () => isar
          .collection<MosqueCacheEntry>()
          .filter()
          .fetchedAtLessThan(cutoff)
          .deleteAll(),
    );
  }

  /// Keeps the prayer cache bounded (a rolling year is plenty).
  Future<int> prunePrayerCache({int keepDays = 400}) {
    final DateTime cutoff = DateTime.now().subtract(Duration(days: keepDays));
    return isar.writeTxn(
      () => isar
          .collection<CachedPrayerDay>()
          .filter()
          .dateLessThan(cutoff)
          .deleteAll(),
    );
  }
}
