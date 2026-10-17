import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:awan/features/recitation/domain/entities/recitation_entities.dart';
import 'package:awan/features/recitation/domain/usecases/quran_text.dart';

/// The mushaf, word by word, in SQLite.
///
/// Built once from the Uthmani text the app already ships (`assets/data/
/// quran_uthmani.json`), then read by word index — the architecture note's
/// requirement, and the reason the cursor can be a number instead of a search.
///
/// The table stores the three things the checker compares: the display word,
/// its consonant skeleton, and its per-letter marks. They are computed at build
/// time, not at recitation time, so a segment costs one indexed query.
class QuranWordDatabase {
  QuranWordDatabase({this.path});

  /// Test seam: an in-memory database path.
  final String? path;

  Database? _db;
  static const int _schemaVersion = 1;

  Database get _database {
    final Database? db = _db;
    if (db == null) throw StateError('quran_database_not_open');
    return db;
  }

  bool get isOpen => _db != null;

  Future<Database> open() async {
    if (_db != null) return _db!;
    final String file = path ?? p.join(await getDatabasesPath(), 'awan_quran.db');
    _db = await openDatabase(file, version: _schemaVersion);
    return _db!;
  }

  /// Builds the word tables if they are missing. Returns the number of words.
  Future<int> ensureBuilt({void Function(double progress)? onProgress}) async {
    final Database db = await open();
    final List<Map<String, Object?>> existing = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
      <Object?>['table', 'words'],
    );
    if (existing.isNotEmpty) {
      final List<Map<String, Object?>> count =
          await db.rawQuery('SELECT COUNT(*) AS c FROM words');
      return (count.first['c'] as int?) ?? 0;
    }

    final String raw = await rootBundle.loadString('assets/data/quran_uthmani.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, dynamic> ayat = data['ayahs'] as Map<String, dynamic>;
    final List<dynamic> surahs = (data['surahs'] as List<dynamic>?) ?? <dynamic>[];

    await db.execute('''
      CREATE TABLE IF NOT EXISTS surahs(
        id INTEGER PRIMARY KEY, name_ar TEXT, name_en TEXT, ayah_count INTEGER)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayat(
        surah INTEGER, ayah INTEGER, text TEXT, PRIMARY KEY(surah, ayah))
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words(
        surah INTEGER, ayah INTEGER, widx INTEGER,
        uthmani TEXT, skeleton TEXT, marks TEXT,
        PRIMARY KEY(surah, ayah, widx))
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS words_by_ayah ON words(surah, ayah)');

    await db.transaction((Transaction txn) async {
      for (final dynamic entry in surahs) {
        final Map<String, dynamic> s = entry as Map<String, dynamic>;
        await txn.insert('surahs', <String, Object?>{
          'id': s['id'],
          'name_ar': s['name_ar'],
          'name_en': s['name_en'],
          'ayah_count': s['ayah_count'],
        });
      }

      int done = 0;
      final int total = ayat.values.fold<int>(
        0,
        (int sum, dynamic list) => sum + (list as List<dynamic>).length,
      );

      for (final MapEntry<String, dynamic> surahEntry in ayat.entries) {
        final int surah = int.parse(surahEntry.key);
        final List<dynamic> list = surahEntry.value as List<dynamic>;
        for (int a = 0; a < list.length; a++) {
          final String text = (list[a] as String).trim();
          await txn.insert('ayat', <String, Object?>{
            'surah': surah,
            'ayah': a + 1,
            'text': text,
          });
          final List<String> words = QuranText.words(text);
          final List<Map<String, Object?>> rows = <Map<String, Object?>>[
            for (int i = 0; i < words.length; i++)
              <String, Object?>{
                'surah': surah,
                'ayah': a + 1,
                'widx': i,
                'uthmani': words[i],
                'skeleton': QuranText.skeleton(words[i]),
                'marks': QuranText.marks(words[i]).join('|'),
              },
          ];
          final Batch batch = txn.batch();
          for (final Map<String, Object?> row in rows) {
            batch.insert('words', row);
          }
          await batch.commit(noResult: true);
          done++;
          if (done % 200 == 0) onProgress?.call(done / total);
        }
      }
      onProgress?.call(1);
    });

    final List<Map<String, Object?>> count =
        await db.rawQuery('SELECT COUNT(*) AS c FROM words');
    return (count.first['c'] as int?) ?? 0;
  }

  Future<List<RecitationWord>> wordsOf(int surah, int ayah) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'words',
      where: 'surah = ? AND ayah = ?',
      whereArgs: <Object?>[surah, ayah],
      orderBy: 'widx ASC',
    );
    return <RecitationWord>[
      for (final Map<String, Object?> row in rows)
        RecitationWord(
          index: row['widx'] as int,
          uthmani: row['uthmani'] as String,
          consonants: row['skeleton'] as String,
          marks: (row['marks'] as String).split('|'),
        ),
    ];
  }

  Future<String?> ayahText(int surah, int ayah) async {
    final List<Map<String, Object?>> rows = await _database.query(
      'ayat',
      columns: <String>['text'],
      where: 'surah = ? AND ayah = ?',
      whereArgs: <Object?>[surah, ayah],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['text'] as String?;
  }

  Future<List<SurahRow>> surahs() async {
    final List<Map<String, Object?>> rows =
        await _database.query('surahs', orderBy: 'id ASC');
    return <SurahRow>[
      for (final Map<String, Object?> row in rows)
        SurahRow(
          id: row['id'] as int,
          nameAr: row['name_ar'] as String? ?? '',
          nameEn: row['name_en'] as String? ?? '',
          ayahCount: row['ayah_count'] as int? ?? 0,
        ),
    ];
  }

  /// The previous ayah's text — the architecture note's `initial_prompt`
  /// material. sherpa-onnx does not expose Whisper's prompt, so it is used to
  /// prime the *aligner* instead: the checker knows where the reciter is and
  /// refuses to jump to a similar verse elsewhere in the Qur'an.
  Future<String?> contextBefore(int surah, int ayah) async {
    if (ayah > 1) return ayahText(surah, ayah - 1);
    if (surah > 1) {
      final List<Map<String, Object?>> rows = await _database.rawQuery(
        'SELECT text FROM ayat WHERE surah = ? ORDER BY ayah DESC LIMIT 1',
        <Object?>[surah - 1],
      );
      return rows.isEmpty ? null : rows.first['text'] as String?;
    }
    return null;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

class SurahRow {
  const SurahRow({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.ayahCount,
  });
  final int id;
  final String nameAr;
  final String nameEn;
  final int ayahCount;
}
