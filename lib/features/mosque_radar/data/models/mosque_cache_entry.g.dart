// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mosque_cache_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMosqueCacheEntryCollection on Isar {
  IsarCollection<MosqueCacheEntry> get mosqueCacheEntrys => this.collection();
}

const MosqueCacheEntrySchema = CollectionSchema(
  name: r'MosqueCacheEntry',
  id: -6253006577969001669,
  properties: {
    r'cellKey': PropertySchema(
      id: 0,
      name: r'cellKey',
      type: IsarType.string,
    ),
    r'fetchedAt': PropertySchema(
      id: 1,
      name: r'fetchedAt',
      type: IsarType.dateTime,
    ),
    r'latitude': PropertySchema(
      id: 2,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 3,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'payload': PropertySchema(
      id: 4,
      name: r'payload',
      type: IsarType.string,
    ),
    r'provider': PropertySchema(
      id: 5,
      name: r'provider',
      type: IsarType.string,
    )
  },
  estimateSize: _mosqueCacheEntryEstimateSize,
  serialize: _mosqueCacheEntrySerialize,
  deserialize: _mosqueCacheEntryDeserialize,
  deserializeProp: _mosqueCacheEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'cellKey': IndexSchema(
      id: 7544825199794913376,
      name: r'cellKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'cellKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _mosqueCacheEntryGetId,
  getLinks: _mosqueCacheEntryGetLinks,
  attach: _mosqueCacheEntryAttach,
  version: '3.1.0+1',
);

int _mosqueCacheEntryEstimateSize(
  MosqueCacheEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cellKey.length * 3;
  bytesCount += 3 + object.payload.length * 3;
  bytesCount += 3 + object.provider.length * 3;
  return bytesCount;
}

void _mosqueCacheEntrySerialize(
  MosqueCacheEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cellKey);
  writer.writeDateTime(offsets[1], object.fetchedAt);
  writer.writeDouble(offsets[2], object.latitude);
  writer.writeDouble(offsets[3], object.longitude);
  writer.writeString(offsets[4], object.payload);
  writer.writeString(offsets[5], object.provider);
}

MosqueCacheEntry _mosqueCacheEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MosqueCacheEntry();
  object.cellKey = reader.readString(offsets[0]);
  object.fetchedAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.latitude = reader.readDouble(offsets[2]);
  object.longitude = reader.readDouble(offsets[3]);
  object.payload = reader.readString(offsets[4]);
  object.provider = reader.readString(offsets[5]);
  return object;
}

P _mosqueCacheEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mosqueCacheEntryGetId(MosqueCacheEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mosqueCacheEntryGetLinks(MosqueCacheEntry object) {
  return [];
}

void _mosqueCacheEntryAttach(
    IsarCollection<dynamic> col, Id id, MosqueCacheEntry object) {
  object.id = id;
}

extension MosqueCacheEntryByIndex on IsarCollection<MosqueCacheEntry> {
  Future<MosqueCacheEntry?> getByCellKey(String cellKey) {
    return getByIndex(r'cellKey', [cellKey]);
  }

  MosqueCacheEntry? getByCellKeySync(String cellKey) {
    return getByIndexSync(r'cellKey', [cellKey]);
  }

  Future<bool> deleteByCellKey(String cellKey) {
    return deleteByIndex(r'cellKey', [cellKey]);
  }

  bool deleteByCellKeySync(String cellKey) {
    return deleteByIndexSync(r'cellKey', [cellKey]);
  }

  Future<List<MosqueCacheEntry?>> getAllByCellKey(List<String> cellKeyValues) {
    final values = cellKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'cellKey', values);
  }

  List<MosqueCacheEntry?> getAllByCellKeySync(List<String> cellKeyValues) {
    final values = cellKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'cellKey', values);
  }

  Future<int> deleteAllByCellKey(List<String> cellKeyValues) {
    final values = cellKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'cellKey', values);
  }

  int deleteAllByCellKeySync(List<String> cellKeyValues) {
    final values = cellKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'cellKey', values);
  }

  Future<Id> putByCellKey(MosqueCacheEntry object) {
    return putByIndex(r'cellKey', object);
  }

  Id putByCellKeySync(MosqueCacheEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'cellKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCellKey(List<MosqueCacheEntry> objects) {
    return putAllByIndex(r'cellKey', objects);
  }

  List<Id> putAllByCellKeySync(List<MosqueCacheEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'cellKey', objects, saveLinks: saveLinks);
  }
}

extension MosqueCacheEntryQueryWhereSort
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QWhere> {
  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MosqueCacheEntryQueryWhere
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QWhereClause> {
  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhereClause>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhereClause>
      cellKeyEqualTo(String cellKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cellKey',
        value: [cellKey],
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterWhereClause>
      cellKeyNotEqualTo(String cellKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cellKey',
              lower: [],
              upper: [cellKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cellKey',
              lower: [cellKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cellKey',
              lower: [cellKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cellKey',
              lower: [],
              upper: [cellKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MosqueCacheEntryQueryFilter
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QFilterCondition> {
  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cellKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cellKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cellKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cellKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cellKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cellKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cellKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cellKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cellKey',
        value: '',
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      cellKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cellKey',
        value: '',
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      fetchedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      fetchedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      fetchedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      fetchedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fetchedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
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

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payload',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payload',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'provider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'provider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'provider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'provider',
        value: '',
      ));
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterFilterCondition>
      providerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'provider',
        value: '',
      ));
    });
  }
}

extension MosqueCacheEntryQueryObject
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QFilterCondition> {}

extension MosqueCacheEntryQueryLinks
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QFilterCondition> {}

extension MosqueCacheEntryQuerySortBy
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QSortBy> {
  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByCellKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellKey', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByCellKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellKey', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      sortByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }
}

extension MosqueCacheEntryQuerySortThenBy
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QSortThenBy> {
  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByCellKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellKey', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByCellKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cellKey', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.asc);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QAfterSortBy>
      thenByProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'provider', Sort.desc);
    });
  }
}

extension MosqueCacheEntryQueryWhereDistinct
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QDistinct> {
  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QDistinct> distinctByCellKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cellKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QDistinct>
      distinctByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fetchedAt');
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QDistinct>
      distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QDistinct>
      distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QDistinct> distinctByPayload(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payload', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QDistinct>
      distinctByProvider({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'provider', caseSensitive: caseSensitive);
    });
  }
}

extension MosqueCacheEntryQueryProperty
    on QueryBuilder<MosqueCacheEntry, MosqueCacheEntry, QQueryProperty> {
  QueryBuilder<MosqueCacheEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MosqueCacheEntry, String, QQueryOperations> cellKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cellKey');
    });
  }

  QueryBuilder<MosqueCacheEntry, DateTime, QQueryOperations>
      fetchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fetchedAt');
    });
  }

  QueryBuilder<MosqueCacheEntry, double, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<MosqueCacheEntry, double, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<MosqueCacheEntry, String, QQueryOperations> payloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payload');
    });
  }

  QueryBuilder<MosqueCacheEntry, String, QQueryOperations> providerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'provider');
    });
  }
}
