// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quran_mark.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQuranMarkCollection on Isar {
  IsarCollection<QuranMark> get quranMarks => this.collection();
}

const QuranMarkSchema = CollectionSchema(
  name: r'QuranMark',
  id: 8711215060514559145,
  properties: {
    r'ayah': PropertySchema(
      id: 0,
      name: r'ayah',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'kind': PropertySchema(
      id: 2,
      name: r'kind',
      type: IsarType.string,
    ),
    r'note': PropertySchema(
      id: 3,
      name: r'note',
      type: IsarType.string,
    ),
    r'surah': PropertySchema(
      id: 4,
      name: r'surah',
      type: IsarType.long,
    )
  },
  estimateSize: _quranMarkEstimateSize,
  serialize: _quranMarkSerialize,
  deserialize: _quranMarkDeserialize,
  deserializeProp: _quranMarkDeserializeProp,
  idName: r'id',
  indexes: {
    r'surah': IndexSchema(
      id: 2384701842067459490,
      name: r'surah',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'surah',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'kind': IndexSchema(
      id: 1484550194077596484,
      name: r'kind',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'kind',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _quranMarkGetId,
  getLinks: _quranMarkGetLinks,
  attach: _quranMarkAttach,
  version: '3.1.0+1',
);

int _quranMarkEstimateSize(
  QuranMark object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.kind.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _quranMarkSerialize(
  QuranMark object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.ayah);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.kind);
  writer.writeString(offsets[3], object.note);
  writer.writeLong(offsets[4], object.surah);
}

QuranMark _quranMarkDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QuranMark();
  object.ayah = reader.readLong(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.kind = reader.readString(offsets[2]);
  object.note = reader.readStringOrNull(offsets[3]);
  object.surah = reader.readLong(offsets[4]);
  return object;
}

P _quranMarkDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _quranMarkGetId(QuranMark object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _quranMarkGetLinks(QuranMark object) {
  return [];
}

void _quranMarkAttach(IsarCollection<dynamic> col, Id id, QuranMark object) {
  object.id = id;
}

extension QuranMarkQueryWhereSort
    on QueryBuilder<QuranMark, QuranMark, QWhere> {
  QueryBuilder<QuranMark, QuranMark, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhere> anySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'surah'),
      );
    });
  }
}

extension QuranMarkQueryWhere
    on QueryBuilder<QuranMark, QuranMark, QWhereClause> {
  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> surahEqualTo(
      int surah) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'surah',
        value: [surah],
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> surahNotEqualTo(
      int surah) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [],
              upper: [surah],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [surah],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [surah],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [],
              upper: [surah],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> surahGreaterThan(
    int surah, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surah',
        lower: [surah],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> surahLessThan(
    int surah, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surah',
        lower: [],
        upper: [surah],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> surahBetween(
    int lowerSurah,
    int upperSurah, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surah',
        lower: [lowerSurah],
        includeLower: includeLower,
        upper: [upperSurah],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> kindEqualTo(
      String kind) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kind',
        value: [kind],
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterWhereClause> kindNotEqualTo(
      String kind) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [],
              upper: [kind],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [kind],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [kind],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [],
              upper: [kind],
              includeUpper: false,
            ));
      }
    });
  }
}

extension QuranMarkQueryFilter
    on QueryBuilder<QuranMark, QuranMark, QFilterCondition> {
  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> ayahEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ayah',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> ayahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ayah',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> ayahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ayah',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> ayahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ayah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kind',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kind',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> surahEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surah',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> surahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surah',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> surahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surah',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterFilterCondition> surahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension QuranMarkQueryObject
    on QueryBuilder<QuranMark, QuranMark, QFilterCondition> {}

extension QuranMarkQueryLinks
    on QueryBuilder<QuranMark, QuranMark, QFilterCondition> {}

extension QuranMarkQuerySortBy on QueryBuilder<QuranMark, QuranMark, QSortBy> {
  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortBySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> sortBySurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.desc);
    });
  }
}

extension QuranMarkQuerySortThenBy
    on QueryBuilder<QuranMark, QuranMark, QSortThenBy> {
  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenBySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.asc);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QAfterSortBy> thenBySurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.desc);
    });
  }
}

extension QuranMarkQueryWhereDistinct
    on QueryBuilder<QuranMark, QuranMark, QDistinct> {
  QueryBuilder<QuranMark, QuranMark, QDistinct> distinctByAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayah');
    });
  }

  QueryBuilder<QuranMark, QuranMark, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<QuranMark, QuranMark, QDistinct> distinctByKind(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuranMark, QuranMark, QDistinct> distinctBySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surah');
    });
  }
}

extension QuranMarkQueryProperty
    on QueryBuilder<QuranMark, QuranMark, QQueryProperty> {
  QueryBuilder<QuranMark, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QuranMark, int, QQueryOperations> ayahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayah');
    });
  }

  QueryBuilder<QuranMark, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<QuranMark, String, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<QuranMark, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<QuranMark, int, QQueryOperations> surahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surah');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReadingPositionCollection on Isar {
  IsarCollection<ReadingPosition> get readingPositions => this.collection();
}

const ReadingPositionSchema = CollectionSchema(
  name: r'ReadingPosition',
  id: -5555304648089438970,
  properties: {
    r'ayah': PropertySchema(
      id: 0,
      name: r'ayah',
      type: IsarType.long,
    ),
    r'surah': PropertySchema(
      id: 1,
      name: r'surah',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 2,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _readingPositionEstimateSize,
  serialize: _readingPositionSerialize,
  deserialize: _readingPositionDeserialize,
  deserializeProp: _readingPositionDeserializeProp,
  idName: r'id',
  indexes: {
    r'surah': IndexSchema(
      id: 2384701842067459490,
      name: r'surah',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'surah',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _readingPositionGetId,
  getLinks: _readingPositionGetLinks,
  attach: _readingPositionAttach,
  version: '3.1.0+1',
);

int _readingPositionEstimateSize(
  ReadingPosition object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _readingPositionSerialize(
  ReadingPosition object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.ayah);
  writer.writeLong(offsets[1], object.surah);
  writer.writeDateTime(offsets[2], object.updatedAt);
}

ReadingPosition _readingPositionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReadingPosition();
  object.ayah = reader.readLong(offsets[0]);
  object.id = id;
  object.surah = reader.readLong(offsets[1]);
  object.updatedAt = reader.readDateTime(offsets[2]);
  return object;
}

P _readingPositionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _readingPositionGetId(ReadingPosition object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _readingPositionGetLinks(ReadingPosition object) {
  return [];
}

void _readingPositionAttach(
    IsarCollection<dynamic> col, Id id, ReadingPosition object) {
  object.id = id;
}

extension ReadingPositionByIndex on IsarCollection<ReadingPosition> {
  Future<ReadingPosition?> getBySurah(int surah) {
    return getByIndex(r'surah', [surah]);
  }

  ReadingPosition? getBySurahSync(int surah) {
    return getByIndexSync(r'surah', [surah]);
  }

  Future<bool> deleteBySurah(int surah) {
    return deleteByIndex(r'surah', [surah]);
  }

  bool deleteBySurahSync(int surah) {
    return deleteByIndexSync(r'surah', [surah]);
  }

  Future<List<ReadingPosition?>> getAllBySurah(List<int> surahValues) {
    final values = surahValues.map((e) => [e]).toList();
    return getAllByIndex(r'surah', values);
  }

  List<ReadingPosition?> getAllBySurahSync(List<int> surahValues) {
    final values = surahValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'surah', values);
  }

  Future<int> deleteAllBySurah(List<int> surahValues) {
    final values = surahValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'surah', values);
  }

  int deleteAllBySurahSync(List<int> surahValues) {
    final values = surahValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'surah', values);
  }

  Future<Id> putBySurah(ReadingPosition object) {
    return putByIndex(r'surah', object);
  }

  Id putBySurahSync(ReadingPosition object, {bool saveLinks = true}) {
    return putByIndexSync(r'surah', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySurah(List<ReadingPosition> objects) {
    return putAllByIndex(r'surah', objects);
  }

  List<Id> putAllBySurahSync(List<ReadingPosition> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'surah', objects, saveLinks: saveLinks);
  }
}

extension ReadingPositionQueryWhereSort
    on QueryBuilder<ReadingPosition, ReadingPosition, QWhere> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhere> anySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'surah'),
      );
    });
  }
}

extension ReadingPositionQueryWhere
    on QueryBuilder<ReadingPosition, ReadingPosition, QWhereClause> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      surahEqualTo(int surah) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'surah',
        value: [surah],
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      surahNotEqualTo(int surah) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [],
              upper: [surah],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [surah],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [surah],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surah',
              lower: [],
              upper: [surah],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      surahGreaterThan(
    int surah, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surah',
        lower: [surah],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      surahLessThan(
    int surah, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surah',
        lower: [],
        upper: [surah],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      surahBetween(
    int lowerSurah,
    int upperSurah, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surah',
        lower: [lowerSurah],
        includeLower: includeLower,
        upper: [upperSurah],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ReadingPositionQueryFilter
    on QueryBuilder<ReadingPosition, ReadingPosition, QFilterCondition> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      ayahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ayah',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      ayahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ayah',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      ayahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ayah',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      ayahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ayah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      surahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surah',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      surahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surah',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      surahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surah',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      surahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ReadingPositionQueryObject
    on QueryBuilder<ReadingPosition, ReadingPosition, QFilterCondition> {}

extension ReadingPositionQueryLinks
    on QueryBuilder<ReadingPosition, ReadingPosition, QFilterCondition> {}

extension ReadingPositionQuerySortBy
    on QueryBuilder<ReadingPosition, ReadingPosition, QSortBy> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> sortByAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> sortBySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortBySurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ReadingPositionQuerySortThenBy
    on QueryBuilder<ReadingPosition, ReadingPosition, QSortThenBy> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> thenByAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayah', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> thenBySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenBySurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surah', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ReadingPositionQueryWhereDistinct
    on QueryBuilder<ReadingPosition, ReadingPosition, QDistinct> {
  QueryBuilder<ReadingPosition, ReadingPosition, QDistinct> distinctByAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayah');
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QDistinct> distinctBySurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surah');
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ReadingPositionQueryProperty
    on QueryBuilder<ReadingPosition, ReadingPosition, QQueryProperty> {
  QueryBuilder<ReadingPosition, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReadingPosition, int, QQueryOperations> ayahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayah');
    });
  }

  QueryBuilder<ReadingPosition, int, QQueryOperations> surahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surah');
    });
  }

  QueryBuilder<ReadingPosition, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
