// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutashabih_node.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMutashabihNodeCollection on Isar {
  IsarCollection<MutashabihNode> get mutashabihNodes => this.collection();
}

const MutashabihNodeSchema = CollectionSchema(
  name: r'MutashabihNode',
  id: 6967500085474118023,
  properties: {
    r'sourceAbsoluteId': PropertySchema(
      id: 0,
      name: r'sourceAbsoluteId',
      type: IsarType.long,
    ),
    r'sourceAyahNumber': PropertySchema(
      id: 1,
      name: r'sourceAyahNumber',
      type: IsarType.long,
    ),
    r'sourceSurahNumber': PropertySchema(
      id: 2,
      name: r'sourceSurahNumber',
      type: IsarType.long,
    ),
    r'sourceText': PropertySchema(
      id: 3,
      name: r'sourceText',
      type: IsarType.string,
    ),
    r'targets': PropertySchema(
      id: 4,
      name: r'targets',
      type: IsarType.objectList,
      target: r'MutashabihTarget',
    )
  },
  estimateSize: _mutashabihNodeEstimateSize,
  serialize: _mutashabihNodeSerialize,
  deserialize: _mutashabihNodeDeserialize,
  deserializeProp: _mutashabihNodeDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'MutashabihTarget': MutashabihTargetSchema},
  getId: _mutashabihNodeGetId,
  getLinks: _mutashabihNodeGetLinks,
  attach: _mutashabihNodeAttach,
  version: '3.1.0+1',
);

int _mutashabihNodeEstimateSize(
  MutashabihNode object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.sourceText.length * 3;
  bytesCount += 3 + object.targets.length * 3;
  {
    final offsets = allOffsets[MutashabihTarget]!;
    for (var i = 0; i < object.targets.length; i++) {
      final value = object.targets[i];
      bytesCount +=
          MutashabihTargetSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _mutashabihNodeSerialize(
  MutashabihNode object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.sourceAbsoluteId);
  writer.writeLong(offsets[1], object.sourceAyahNumber);
  writer.writeLong(offsets[2], object.sourceSurahNumber);
  writer.writeString(offsets[3], object.sourceText);
  writer.writeObjectList<MutashabihTarget>(
    offsets[4],
    allOffsets,
    MutashabihTargetSchema.serialize,
    object.targets,
  );
}

MutashabihNode _mutashabihNodeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MutashabihNode();
  object.sourceAbsoluteId = reader.readLong(offsets[0]);
  object.sourceAyahNumber = reader.readLong(offsets[1]);
  object.sourceSurahNumber = reader.readLong(offsets[2]);
  object.sourceText = reader.readString(offsets[3]);
  object.targets = reader.readObjectList<MutashabihTarget>(
        offsets[4],
        MutashabihTargetSchema.deserialize,
        allOffsets,
        MutashabihTarget(),
      ) ??
      [];
  return object;
}

P _mutashabihNodeDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readObjectList<MutashabihTarget>(
            offset,
            MutashabihTargetSchema.deserialize,
            allOffsets,
            MutashabihTarget(),
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mutashabihNodeGetId(MutashabihNode object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mutashabihNodeGetLinks(MutashabihNode object) {
  return [];
}

void _mutashabihNodeAttach(
    IsarCollection<dynamic> col, Id id, MutashabihNode object) {}

extension MutashabihNodeQueryWhereSort
    on QueryBuilder<MutashabihNode, MutashabihNode, QWhere> {
  QueryBuilder<MutashabihNode, MutashabihNode, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MutashabihNodeQueryWhere
    on QueryBuilder<MutashabihNode, MutashabihNode, QWhereClause> {
  QueryBuilder<MutashabihNode, MutashabihNode, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterWhereClause> idBetween(
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
}

extension MutashabihNodeQueryFilter
    on QueryBuilder<MutashabihNode, MutashabihNode, QFilterCondition> {
  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
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

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
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

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAbsoluteIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceAbsoluteId',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAbsoluteIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceAbsoluteId',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAbsoluteIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceAbsoluteId',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAbsoluteIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceAbsoluteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAyahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceAyahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAyahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceAyahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAyahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceAyahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceAyahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceAyahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceSurahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceSurahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceSurahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceSurahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceSurahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceSurahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceSurahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceSurahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceText',
        value: '',
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      sourceTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceText',
        value: '',
      ));
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      targetsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targets',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      targetsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targets',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      targetsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targets',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      targetsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targets',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      targetsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targets',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      targetsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targets',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension MutashabihNodeQueryObject
    on QueryBuilder<MutashabihNode, MutashabihNode, QFilterCondition> {
  QueryBuilder<MutashabihNode, MutashabihNode, QAfterFilterCondition>
      targetsElement(FilterQuery<MutashabihTarget> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'targets');
    });
  }
}

extension MutashabihNodeQueryLinks
    on QueryBuilder<MutashabihNode, MutashabihNode, QFilterCondition> {}

extension MutashabihNodeQuerySortBy
    on QueryBuilder<MutashabihNode, MutashabihNode, QSortBy> {
  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceAbsoluteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAbsoluteId', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceAbsoluteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAbsoluteId', Sort.desc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAyahNumber', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAyahNumber', Sort.desc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceSurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSurahNumber', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceSurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSurahNumber', Sort.desc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      sortBySourceTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.desc);
    });
  }
}

extension MutashabihNodeQuerySortThenBy
    on QueryBuilder<MutashabihNode, MutashabihNode, QSortThenBy> {
  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceAbsoluteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAbsoluteId', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceAbsoluteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAbsoluteId', Sort.desc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAyahNumber', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceAyahNumber', Sort.desc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceSurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSurahNumber', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceSurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceSurahNumber', Sort.desc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.asc);
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QAfterSortBy>
      thenBySourceTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.desc);
    });
  }
}

extension MutashabihNodeQueryWhereDistinct
    on QueryBuilder<MutashabihNode, MutashabihNode, QDistinct> {
  QueryBuilder<MutashabihNode, MutashabihNode, QDistinct>
      distinctBySourceAbsoluteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceAbsoluteId');
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QDistinct>
      distinctBySourceAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceAyahNumber');
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QDistinct>
      distinctBySourceSurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceSurahNumber');
    });
  }

  QueryBuilder<MutashabihNode, MutashabihNode, QDistinct> distinctBySourceText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceText', caseSensitive: caseSensitive);
    });
  }
}

extension MutashabihNodeQueryProperty
    on QueryBuilder<MutashabihNode, MutashabihNode, QQueryProperty> {
  QueryBuilder<MutashabihNode, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MutashabihNode, int, QQueryOperations>
      sourceAbsoluteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceAbsoluteId');
    });
  }

  QueryBuilder<MutashabihNode, int, QQueryOperations>
      sourceAyahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceAyahNumber');
    });
  }

  QueryBuilder<MutashabihNode, int, QQueryOperations>
      sourceSurahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceSurahNumber');
    });
  }

  QueryBuilder<MutashabihNode, String, QQueryOperations> sourceTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceText');
    });
  }

  QueryBuilder<MutashabihNode, List<MutashabihTarget>, QQueryOperations>
      targetsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targets');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MutashabihTargetSchema = Schema(
  name: r'MutashabihTarget',
  id: 8878234025361602951,
  properties: {
    r'ruleText': PropertySchema(
      id: 0,
      name: r'ruleText',
      type: IsarType.string,
    ),
    r'targetAbsoluteId': PropertySchema(
      id: 1,
      name: r'targetAbsoluteId',
      type: IsarType.long,
    ),
    r'targetAyahNumber': PropertySchema(
      id: 2,
      name: r'targetAyahNumber',
      type: IsarType.long,
    ),
    r'targetSurahNumber': PropertySchema(
      id: 3,
      name: r'targetSurahNumber',
      type: IsarType.long,
    ),
    r'targetText': PropertySchema(
      id: 4,
      name: r'targetText',
      type: IsarType.string,
    )
  },
  estimateSize: _mutashabihTargetEstimateSize,
  serialize: _mutashabihTargetSerialize,
  deserialize: _mutashabihTargetDeserialize,
  deserializeProp: _mutashabihTargetDeserializeProp,
);

int _mutashabihTargetEstimateSize(
  MutashabihTarget object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.ruleText.length * 3;
  bytesCount += 3 + object.targetText.length * 3;
  return bytesCount;
}

void _mutashabihTargetSerialize(
  MutashabihTarget object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.ruleText);
  writer.writeLong(offsets[1], object.targetAbsoluteId);
  writer.writeLong(offsets[2], object.targetAyahNumber);
  writer.writeLong(offsets[3], object.targetSurahNumber);
  writer.writeString(offsets[4], object.targetText);
}

MutashabihTarget _mutashabihTargetDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MutashabihTarget();
  object.ruleText = reader.readString(offsets[0]);
  object.targetAbsoluteId = reader.readLong(offsets[1]);
  object.targetAyahNumber = reader.readLong(offsets[2]);
  object.targetSurahNumber = reader.readLong(offsets[3]);
  object.targetText = reader.readString(offsets[4]);
  return object;
}

P _mutashabihTargetDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MutashabihTargetQueryFilter
    on QueryBuilder<MutashabihTarget, MutashabihTarget, QFilterCondition> {
  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ruleText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ruleText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ruleText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ruleText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ruleText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ruleText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ruleText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleText',
        value: '',
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      ruleTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ruleText',
        value: '',
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAbsoluteIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetAbsoluteId',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAbsoluteIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetAbsoluteId',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAbsoluteIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetAbsoluteId',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAbsoluteIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetAbsoluteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAyahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetAyahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAyahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetAyahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAyahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetAyahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetAyahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetAyahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetSurahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetSurahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetSurahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetSurahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetSurahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetSurahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetSurahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetSurahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetText',
        value: '',
      ));
    });
  }

  QueryBuilder<MutashabihTarget, MutashabihTarget, QAfterFilterCondition>
      targetTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetText',
        value: '',
      ));
    });
  }
}

extension MutashabihTargetQueryObject
    on QueryBuilder<MutashabihTarget, MutashabihTarget, QFilterCondition> {}
