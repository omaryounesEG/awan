// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tafsir_package_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTafsirPackageEntryCollection on Isar {
  IsarCollection<TafsirPackageEntry> get tafsirPackageEntrys =>
      this.collection();
}

const TafsirPackageEntrySchema = CollectionSchema(
  name: r'TafsirPackageEntry',
  id: 3579984716878944490,
  properties: {
    r'author': PropertySchema(
      id: 0,
      name: r'author',
      type: IsarType.string,
    ),
    r'bundled': PropertySchema(
      id: 1,
      name: r'bundled',
      type: IsarType.bool,
    ),
    r'filePath': PropertySchema(
      id: 2,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'installed': PropertySchema(
      id: 3,
      name: r'installed',
      type: IsarType.bool,
    ),
    r'installedAt': PropertySchema(
      id: 4,
      name: r'installedAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'sizeKb': PropertySchema(
      id: 6,
      name: r'sizeKb',
      type: IsarType.long,
    ),
    r'slug': PropertySchema(
      id: 7,
      name: r'slug',
      type: IsarType.string,
    ),
    r'tafsirId': PropertySchema(
      id: 8,
      name: r'tafsirId',
      type: IsarType.long,
    )
  },
  estimateSize: _tafsirPackageEntryEstimateSize,
  serialize: _tafsirPackageEntrySerialize,
  deserialize: _tafsirPackageEntryDeserialize,
  deserializeProp: _tafsirPackageEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'tafsirId': IndexSchema(
      id: -1754068716982948909,
      name: r'tafsirId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'tafsirId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'installed': IndexSchema(
      id: -2396502518995561215,
      name: r'installed',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'installed',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _tafsirPackageEntryGetId,
  getLinks: _tafsirPackageEntryGetLinks,
  attach: _tafsirPackageEntryAttach,
  version: '3.1.0+1',
);

int _tafsirPackageEntryEstimateSize(
  TafsirPackageEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.author.length * 3;
  {
    final value = object.filePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.slug.length * 3;
  return bytesCount;
}

void _tafsirPackageEntrySerialize(
  TafsirPackageEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.author);
  writer.writeBool(offsets[1], object.bundled);
  writer.writeString(offsets[2], object.filePath);
  writer.writeBool(offsets[3], object.installed);
  writer.writeDateTime(offsets[4], object.installedAt);
  writer.writeString(offsets[5], object.name);
  writer.writeLong(offsets[6], object.sizeKb);
  writer.writeString(offsets[7], object.slug);
  writer.writeLong(offsets[8], object.tafsirId);
}

TafsirPackageEntry _tafsirPackageEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TafsirPackageEntry();
  object.author = reader.readString(offsets[0]);
  object.bundled = reader.readBool(offsets[1]);
  object.filePath = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.installed = reader.readBool(offsets[3]);
  object.installedAt = reader.readDateTimeOrNull(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.sizeKb = reader.readLong(offsets[6]);
  object.slug = reader.readString(offsets[7]);
  object.tafsirId = reader.readLong(offsets[8]);
  return object;
}

P _tafsirPackageEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _tafsirPackageEntryGetId(TafsirPackageEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _tafsirPackageEntryGetLinks(
    TafsirPackageEntry object) {
  return [];
}

void _tafsirPackageEntryAttach(
    IsarCollection<dynamic> col, Id id, TafsirPackageEntry object) {
  object.id = id;
}

extension TafsirPackageEntryByIndex on IsarCollection<TafsirPackageEntry> {
  Future<TafsirPackageEntry?> getByTafsirId(int tafsirId) {
    return getByIndex(r'tafsirId', [tafsirId]);
  }

  TafsirPackageEntry? getByTafsirIdSync(int tafsirId) {
    return getByIndexSync(r'tafsirId', [tafsirId]);
  }

  Future<bool> deleteByTafsirId(int tafsirId) {
    return deleteByIndex(r'tafsirId', [tafsirId]);
  }

  bool deleteByTafsirIdSync(int tafsirId) {
    return deleteByIndexSync(r'tafsirId', [tafsirId]);
  }

  Future<List<TafsirPackageEntry?>> getAllByTafsirId(List<int> tafsirIdValues) {
    final values = tafsirIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'tafsirId', values);
  }

  List<TafsirPackageEntry?> getAllByTafsirIdSync(List<int> tafsirIdValues) {
    final values = tafsirIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'tafsirId', values);
  }

  Future<int> deleteAllByTafsirId(List<int> tafsirIdValues) {
    final values = tafsirIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'tafsirId', values);
  }

  int deleteAllByTafsirIdSync(List<int> tafsirIdValues) {
    final values = tafsirIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'tafsirId', values);
  }

  Future<Id> putByTafsirId(TafsirPackageEntry object) {
    return putByIndex(r'tafsirId', object);
  }

  Id putByTafsirIdSync(TafsirPackageEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'tafsirId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTafsirId(List<TafsirPackageEntry> objects) {
    return putAllByIndex(r'tafsirId', objects);
  }

  List<Id> putAllByTafsirIdSync(List<TafsirPackageEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'tafsirId', objects, saveLinks: saveLinks);
  }
}

extension TafsirPackageEntryQueryWhereSort
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QWhere> {
  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhere>
      anyTafsirId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'tafsirId'),
      );
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhere>
      anyInstalled() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'installed'),
      );
    });
  }
}

extension TafsirPackageEntryQueryWhere
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QWhereClause> {
  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
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

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      tafsirIdEqualTo(int tafsirId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tafsirId',
        value: [tafsirId],
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      tafsirIdNotEqualTo(int tafsirId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tafsirId',
              lower: [],
              upper: [tafsirId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tafsirId',
              lower: [tafsirId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tafsirId',
              lower: [tafsirId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tafsirId',
              lower: [],
              upper: [tafsirId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      tafsirIdGreaterThan(
    int tafsirId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tafsirId',
        lower: [tafsirId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      tafsirIdLessThan(
    int tafsirId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tafsirId',
        lower: [],
        upper: [tafsirId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      tafsirIdBetween(
    int lowerTafsirId,
    int upperTafsirId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tafsirId',
        lower: [lowerTafsirId],
        includeLower: includeLower,
        upper: [upperTafsirId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      installedEqualTo(bool installed) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'installed',
        value: [installed],
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterWhereClause>
      installedNotEqualTo(bool installed) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'installed',
              lower: [],
              upper: [installed],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'installed',
              lower: [installed],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'installed',
              lower: [installed],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'installed',
              lower: [],
              upper: [installed],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TafsirPackageEntryQueryFilter
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QFilterCondition> {
  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'author',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'author',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      authorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      bundledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bundled',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
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

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
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

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
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

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      installedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'installed',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      installedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'installedAt',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      installedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'installedAt',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      installedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'installedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      installedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'installedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      installedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'installedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      installedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'installedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      sizeKbEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sizeKb',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      sizeKbGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sizeKb',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      sizeKbLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sizeKb',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      sizeKbBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sizeKb',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slug',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      slugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      tafsirIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tafsirId',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      tafsirIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tafsirId',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      tafsirIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tafsirId',
        value: value,
      ));
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterFilterCondition>
      tafsirIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tafsirId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TafsirPackageEntryQueryObject
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QFilterCondition> {}

extension TafsirPackageEntryQueryLinks
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QFilterCondition> {}

extension TafsirPackageEntryQuerySortBy
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QSortBy> {
  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByBundled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bundled', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByBundledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bundled', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByInstalled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installed', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByInstalledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installed', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByInstalledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByInstalledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortBySizeKb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortBySizeKbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByTafsirId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tafsirId', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      sortByTafsirIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tafsirId', Sort.desc);
    });
  }
}

extension TafsirPackageEntryQuerySortThenBy
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QSortThenBy> {
  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByBundled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bundled', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByBundledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bundled', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByInstalled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installed', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByInstalledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installed', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByInstalledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByInstalledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'installedAt', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenBySizeKb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenBySizeKbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByTafsirId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tafsirId', Sort.asc);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QAfterSortBy>
      thenByTafsirIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tafsirId', Sort.desc);
    });
  }
}

extension TafsirPackageEntryQueryWhereDistinct
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct> {
  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctByAuthor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'author', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctByBundled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bundled');
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctByFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctByInstalled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'installed');
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctByInstalledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'installedAt');
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctBySizeKb() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sizeKb');
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctBySlug({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QDistinct>
      distinctByTafsirId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tafsirId');
    });
  }
}

extension TafsirPackageEntryQueryProperty
    on QueryBuilder<TafsirPackageEntry, TafsirPackageEntry, QQueryProperty> {
  QueryBuilder<TafsirPackageEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TafsirPackageEntry, String, QQueryOperations> authorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'author');
    });
  }

  QueryBuilder<TafsirPackageEntry, bool, QQueryOperations> bundledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bundled');
    });
  }

  QueryBuilder<TafsirPackageEntry, String?, QQueryOperations>
      filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<TafsirPackageEntry, bool, QQueryOperations> installedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installed');
    });
  }

  QueryBuilder<TafsirPackageEntry, DateTime?, QQueryOperations>
      installedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'installedAt');
    });
  }

  QueryBuilder<TafsirPackageEntry, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<TafsirPackageEntry, int, QQueryOperations> sizeKbProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sizeKb');
    });
  }

  QueryBuilder<TafsirPackageEntry, String, QQueryOperations> slugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slug');
    });
  }

  QueryBuilder<TafsirPackageEntry, int, QQueryOperations> tafsirIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tafsirId');
    });
  }
}
