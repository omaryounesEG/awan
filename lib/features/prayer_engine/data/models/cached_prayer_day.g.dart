// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_prayer_day.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedPrayerDayCollection on Isar {
  IsarCollection<CachedPrayerDay> get cachedPrayerDays => this.collection();
}

const CachedPrayerDaySchema = CollectionSchema(
  name: r'CachedPrayerDay',
  id: -1702846815702757953,
  properties: {
    r'computedAt': PropertySchema(
      id: 0,
      name: r'computedAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'key': PropertySchema(
      id: 2,
      name: r'key',
      type: IsarType.string,
    ),
    r'latitude': PropertySchema(
      id: 3,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 4,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'madhab': PropertySchema(
      id: 5,
      name: r'madhab',
      type: IsarType.string,
    ),
    r'method': PropertySchema(
      id: 6,
      name: r'method',
      type: IsarType.string,
    ),
    r'times': PropertySchema(
      id: 7,
      name: r'times',
      type: IsarType.longList,
    ),
    r'verifiedDiffMinutes': PropertySchema(
      id: 8,
      name: r'verifiedDiffMinutes',
      type: IsarType.long,
    )
  },
  estimateSize: _cachedPrayerDayEstimateSize,
  serialize: _cachedPrayerDaySerialize,
  deserialize: _cachedPrayerDayDeserialize,
  deserializeProp: _cachedPrayerDayDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedPrayerDayGetId,
  getLinks: _cachedPrayerDayGetLinks,
  attach: _cachedPrayerDayAttach,
  version: '3.1.0+1',
);

int _cachedPrayerDayEstimateSize(
  CachedPrayerDay object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.madhab.length * 3;
  bytesCount += 3 + object.method.length * 3;
  bytesCount += 3 + object.times.length * 8;
  return bytesCount;
}

void _cachedPrayerDaySerialize(
  CachedPrayerDay object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.computedAt);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeString(offsets[2], object.key);
  writer.writeDouble(offsets[3], object.latitude);
  writer.writeDouble(offsets[4], object.longitude);
  writer.writeString(offsets[5], object.madhab);
  writer.writeString(offsets[6], object.method);
  writer.writeLongList(offsets[7], object.times);
  writer.writeLong(offsets[8], object.verifiedDiffMinutes);
}

CachedPrayerDay _cachedPrayerDayDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedPrayerDay();
  object.computedAt = reader.readDateTime(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.id = id;
  object.key = reader.readString(offsets[2]);
  object.latitude = reader.readDouble(offsets[3]);
  object.longitude = reader.readDouble(offsets[4]);
  object.madhab = reader.readString(offsets[5]);
  object.method = reader.readString(offsets[6]);
  object.times = reader.readLongList(offsets[7]) ?? [];
  object.verifiedDiffMinutes = reader.readLongOrNull(offsets[8]);
  return object;
}

P _cachedPrayerDayDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongList(offset) ?? []) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedPrayerDayGetId(CachedPrayerDay object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedPrayerDayGetLinks(CachedPrayerDay object) {
  return [];
}

void _cachedPrayerDayAttach(
    IsarCollection<dynamic> col, Id id, CachedPrayerDay object) {
  object.id = id;
}

extension CachedPrayerDayByIndex on IsarCollection<CachedPrayerDay> {
  Future<CachedPrayerDay?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  CachedPrayerDay? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<CachedPrayerDay?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<CachedPrayerDay?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(CachedPrayerDay object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(CachedPrayerDay object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<CachedPrayerDay> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<CachedPrayerDay> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension CachedPrayerDayQueryWhereSort
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QWhere> {
  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension CachedPrayerDayQueryWhere
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QWhereClause> {
  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause>
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

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause> keyEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause>
      keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedPrayerDayQueryFilter
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QFilterCondition> {
  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      computedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'computedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      computedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'computedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      computedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'computedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      computedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'computedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
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

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
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

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
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

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      latitudeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      latitudeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      latitudeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      latitudeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      longitudeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      longitudeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      longitudeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      longitudeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'madhab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'madhab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'madhab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'madhab',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'madhab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'madhab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'madhab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'madhab',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'madhab',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      madhabIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'madhab',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'method',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'method',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      methodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'times',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'times',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'times',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'times',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      timesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      verifiedDiffMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'verifiedDiffMinutes',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      verifiedDiffMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'verifiedDiffMinutes',
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      verifiedDiffMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verifiedDiffMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      verifiedDiffMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verifiedDiffMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      verifiedDiffMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verifiedDiffMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterFilterCondition>
      verifiedDiffMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verifiedDiffMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedPrayerDayQueryObject
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QFilterCondition> {}

extension CachedPrayerDayQueryLinks
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QFilterCondition> {}

extension CachedPrayerDayQuerySortBy
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QSortBy> {
  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByComputedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByComputedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> sortByMadhab() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'madhab', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByMadhabDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'madhab', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> sortByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByVerifiedDiffMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedDiffMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      sortByVerifiedDiffMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedDiffMinutes', Sort.desc);
    });
  }
}

extension CachedPrayerDayQuerySortThenBy
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QSortThenBy> {
  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByComputedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByComputedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'computedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> thenByMadhab() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'madhab', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByMadhabDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'madhab', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy> thenByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByVerifiedDiffMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedDiffMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QAfterSortBy>
      thenByVerifiedDiffMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedDiffMinutes', Sort.desc);
    });
  }
}

extension CachedPrayerDayQueryWhereDistinct
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct> {
  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct>
      distinctByComputedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'computedAt');
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct>
      distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct>
      distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct> distinctByMadhab(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'madhab', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct> distinctByMethod(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'method', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct> distinctByTimes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'times');
    });
  }

  QueryBuilder<CachedPrayerDay, CachedPrayerDay, QDistinct>
      distinctByVerifiedDiffMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verifiedDiffMinutes');
    });
  }
}

extension CachedPrayerDayQueryProperty
    on QueryBuilder<CachedPrayerDay, CachedPrayerDay, QQueryProperty> {
  QueryBuilder<CachedPrayerDay, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedPrayerDay, DateTime, QQueryOperations>
      computedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'computedAt');
    });
  }

  QueryBuilder<CachedPrayerDay, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<CachedPrayerDay, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<CachedPrayerDay, double, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<CachedPrayerDay, double, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<CachedPrayerDay, String, QQueryOperations> madhabProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'madhab');
    });
  }

  QueryBuilder<CachedPrayerDay, String, QQueryOperations> methodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'method');
    });
  }

  QueryBuilder<CachedPrayerDay, List<int>, QQueryOperations> timesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'times');
    });
  }

  QueryBuilder<CachedPrayerDay, int?, QQueryOperations>
      verifiedDiffMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verifiedDiffMinutes');
    });
  }
}
