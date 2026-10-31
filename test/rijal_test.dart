import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/hadith/domain/entities/narrator.dart';

/// The rijal index is only worth shipping if it is honest about what it knows:
/// every narrator carries the source's category, and «غير محدد» is a real value
/// rather than a silent guess.
void main() {
  late Map<String, dynamic> doc;
  late List<dynamic> rows;

  setUpAll(() {
    final File file = File('assets/hadith/rijal_v1.json.gz');
    expect(file.existsSync(), isTrue);
    doc = jsonDecode(utf8.decode(gzip.decode(file.readAsBytesSync())))
        as Map<String, dynamic>;
    rows = doc['narrators'] as List<dynamic>;
  });

  test('the five categories of the source are all present', () {
    expect(doc['categories'], <String>['صحابي', 'ثقة', 'صدوق', 'ضعيف', 'غير محدد']);
    final Set<int> seen = <int>{
      for (final dynamic row in rows) ((row as List)[1] as num).toInt(),
    };
    expect(seen, <int>{0, 1, 2, 3, 4});
  });

  test('every name is Arabic and carries no blessing formula', () {
    int nonArabic = 0;
    int blessed = 0;
    final RegExp arabic = RegExp(r'[\u0600-\u06FF]');
    for (final dynamic raw in rows) {
      final String name = '${(raw as List)[0]}';
      if (!arabic.hasMatch(name)) nonArabic++;
      if (name.contains('رضي الله') || name.contains('صلى الله')) blessed++;
    }
    expect(nonArabic, 0);
    expect(blessed, 0);
  });

  test('death years are plausible hijri years or zero', () {
    for (final dynamic raw in rows) {
      final int year = ((raw as List)[2] as num).toInt();
      expect(year == 0 || (year > 0 && year < 1600), isTrue,
          reason: 'year $year in ${raw[0]}');
    }
  });

  test('a narrator parses the way the screen reads it', () {
    final Narrator narrator = Narrator.fromJson(<Object?>[
      'مالك بن أنس',
      1,
      179,
      'المدينة المنورة',
    ]);
    expect(narrator.name, 'مالك بن أنس');
    expect(narrator.category, 1);
    expect(narrator.deathYear, 179);
    expect(narrator.place, 'المدينة المنورة');
  });

  test('the index is large enough to be worth searching', () {
    expect(rows.length, greaterThan(23000));
  });
}
