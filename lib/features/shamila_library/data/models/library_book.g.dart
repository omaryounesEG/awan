// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_book.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLibraryBookCollection on Isar {
  IsarCollection<LibraryBook> get libraryBooks => this.collection();
}

const LibraryBookSchema = CollectionSchema(
  name: r'LibraryBook',
  id: -5731756253405714433,
  properties: {
    r'author': PropertySchema(
      id: 0,
      name: r'author',
      type: IsarType.string,
    ),
    r'authorDied': PropertySchema(
      id: 1,
      name: r'authorDied',
      type: IsarType.long,
    ),
    r'bookId': PropertySchema(
      id: 2,
      name: r'bookId',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 3,
      name: r'category',
      type: IsarType.string,
    ),
    r'chapters': PropertySchema(
      id: 4,
      name: r'chapters',
      type: IsarType.long,
    ),
    r'chars': PropertySchema(
      id: 5,
      name: r'chars',
      type: IsarType.long,
    ),
    r'chunkBase': PropertySchema(
      id: 6,
      name: r'chunkBase',
      type: IsarType.long,
    ),
    r'downloaded': PropertySchema(
      id: 7,
      name: r'downloaded',
      type: IsarType.bool,
    ),
    r'downloadedAt': PropertySchema(
      id: 8,
      name: r'downloadedAt',
      type: IsarType.dateTime,
    ),
    r'filePath': PropertySchema(
      id: 9,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'lastChapter': PropertySchema(
      id: 10,
      name: r'lastChapter',
      type: IsarType.long,
    ),
    r'lastOpenedAt': PropertySchema(
      id: 11,
      name: r'lastOpenedAt',
      type: IsarType.dateTime,
    ),
    r'progress': PropertySchema(
      id: 12,
      name: r'progress',
      type: IsarType.double,
    ),
    r'searchKey': PropertySchema(
      id: 13,
      name: r'searchKey',
      type: IsarType.string,
    ),
    r'sizeKb': PropertySchema(
      id: 14,
      name: r'sizeKb',
      type: IsarType.long,
    ),
    r'source': PropertySchema(
      id: 15,
      name: r'source',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 16,
      name: r'title',
      type: IsarType.string,
    ),
    r'url': PropertySchema(
      id: 17,
      name: r'url',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 18,
      name: r'version',
      type: IsarType.string,
    )
  },
  estimateSize: _libraryBookEstimateSize,
  serialize: _libraryBookSerialize,
  deserialize: _libraryBookDeserialize,
  deserializeProp: _libraryBookDeserializeProp,
  idName: r'id',
  indexes: {
    r'bookId': IndexSchema(
      id: 3567540928881766442,
      name: r'bookId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'bookId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'downloaded': IndexSchema(
      id: -2573774225040300307,
      name: r'downloaded',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'downloaded',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'lastOpenedAt': IndexSchema(
      id: -3498580983902171062,
      name: r'lastOpenedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastOpenedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'searchKey': IndexSchema(
      id: -1673253136872295656,
      name: r'searchKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'searchKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _libraryBookGetId,
  getLinks: _libraryBookGetLinks,
  attach: _libraryBookAttach,
  version: '3.1.0+1',
);

int _libraryBookEstimateSize(
  LibraryBook object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.author.length * 3;
  bytesCount += 3 + object.bookId.length * 3;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.filePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.searchKey.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.url.length * 3;
  {
    final value = object.version;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _libraryBookSerialize(
  LibraryBook object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.author);
  writer.writeLong(offsets[1], object.authorDied);
  writer.writeString(offsets[2], object.bookId);
  writer.writeString(offsets[3], object.category);
  writer.writeLong(offsets[4], object.chapters);
  writer.writeLong(offsets[5], object.chars);
  writer.writeLong(offsets[6], object.chunkBase);
  writer.writeBool(offsets[7], object.downloaded);
  writer.writeDateTime(offsets[8], object.downloadedAt);
  writer.writeString(offsets[9], object.filePath);
  writer.writeLong(offsets[10], object.lastChapter);
  writer.writeDateTime(offsets[11], object.lastOpenedAt);
  writer.writeDouble(offsets[12], object.progress);
  writer.writeString(offsets[13], object.searchKey);
  writer.writeLong(offsets[14], object.sizeKb);
  writer.writeString(offsets[15], object.source);
  writer.writeString(offsets[16], object.title);
  writer.writeString(offsets[17], object.url);
  writer.writeString(offsets[18], object.version);
}

LibraryBook _libraryBookDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LibraryBook();
  object.author = reader.readString(offsets[0]);
  object.authorDied = reader.readLongOrNull(offsets[1]);
  object.bookId = reader.readString(offsets[2]);
  object.category = reader.readStringOrNull(offsets[3]);
  object.chapters = reader.readLong(offsets[4]);
  object.chars = reader.readLong(offsets[5]);
  object.chunkBase = reader.readLong(offsets[6]);
  object.downloaded = reader.readBool(offsets[7]);
  object.downloadedAt = reader.readDateTimeOrNull(offsets[8]);
  object.filePath = reader.readStringOrNull(offsets[9]);
  object.id = id;
  object.lastChapter = reader.readLong(offsets[10]);
  object.lastOpenedAt = reader.readDateTimeOrNull(offsets[11]);
  object.progress = reader.readDouble(offsets[12]);
  object.searchKey = reader.readString(offsets[13]);
  object.sizeKb = reader.readLong(offsets[14]);
  object.source = reader.readString(offsets[15]);
  object.title = reader.readString(offsets[16]);
  object.url = reader.readString(offsets[17]);
  object.version = reader.readStringOrNull(offsets[18]);
  return object;
}

P _libraryBookDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _libraryBookGetId(LibraryBook object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _libraryBookGetLinks(LibraryBook object) {
  return [];
}

void _libraryBookAttach(
    IsarCollection<dynamic> col, Id id, LibraryBook object) {
  object.id = id;
}

extension LibraryBookByIndex on IsarCollection<LibraryBook> {
  Future<LibraryBook?> getByBookId(String bookId) {
    return getByIndex(r'bookId', [bookId]);
  }

  LibraryBook? getByBookIdSync(String bookId) {
    return getByIndexSync(r'bookId', [bookId]);
  }

  Future<bool> deleteByBookId(String bookId) {
    return deleteByIndex(r'bookId', [bookId]);
  }

  bool deleteByBookIdSync(String bookId) {
    return deleteByIndexSync(r'bookId', [bookId]);
  }

  Future<List<LibraryBook?>> getAllByBookId(List<String> bookIdValues) {
    final values = bookIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'bookId', values);
  }

  List<LibraryBook?> getAllByBookIdSync(List<String> bookIdValues) {
    final values = bookIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'bookId', values);
  }

  Future<int> deleteAllByBookId(List<String> bookIdValues) {
    final values = bookIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'bookId', values);
  }

  int deleteAllByBookIdSync(List<String> bookIdValues) {
    final values = bookIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'bookId', values);
  }

  Future<Id> putByBookId(LibraryBook object) {
    return putByIndex(r'bookId', object);
  }

  Id putByBookIdSync(LibraryBook object, {bool saveLinks = true}) {
    return putByIndexSync(r'bookId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBookId(List<LibraryBook> objects) {
    return putAllByIndex(r'bookId', objects);
  }

  List<Id> putAllByBookIdSync(List<LibraryBook> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'bookId', objects, saveLinks: saveLinks);
  }
}

extension LibraryBookQueryWhereSort
    on QueryBuilder<LibraryBook, LibraryBook, QWhere> {
  QueryBuilder<LibraryBook, LibraryBook, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhere> anyDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'downloaded'),
      );
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhere> anyLastOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastOpenedAt'),
      );
    });
  }
}

extension LibraryBookQueryWhere
    on QueryBuilder<LibraryBook, LibraryBook, QWhereClause> {
  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> idBetween(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> bookIdEqualTo(
      String bookId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'bookId',
        value: [bookId],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> bookIdNotEqualTo(
      String bookId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [],
              upper: [bookId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [bookId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [bookId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookId',
              lower: [],
              upper: [bookId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> titleEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> titleNotEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> downloadedEqualTo(
      bool downloaded) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'downloaded',
        value: [downloaded],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause>
      downloadedNotEqualTo(bool downloaded) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'downloaded',
              lower: [],
              upper: [downloaded],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'downloaded',
              lower: [downloaded],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'downloaded',
              lower: [downloaded],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'downloaded',
              lower: [],
              upper: [downloaded],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause>
      lastOpenedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastOpenedAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause>
      lastOpenedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> lastOpenedAtEqualTo(
      DateTime? lastOpenedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastOpenedAt',
        value: [lastOpenedAt],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause>
      lastOpenedAtNotEqualTo(DateTime? lastOpenedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedAt',
              lower: [],
              upper: [lastOpenedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedAt',
              lower: [lastOpenedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedAt',
              lower: [lastOpenedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedAt',
              lower: [],
              upper: [lastOpenedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause>
      lastOpenedAtGreaterThan(
    DateTime? lastOpenedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedAt',
        lower: [lastOpenedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause>
      lastOpenedAtLessThan(
    DateTime? lastOpenedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedAt',
        lower: [],
        upper: [lastOpenedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> lastOpenedAtBetween(
    DateTime? lowerLastOpenedAt,
    DateTime? upperLastOpenedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedAt',
        lower: [lowerLastOpenedAt],
        includeLower: includeLower,
        upper: [upperLastOpenedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> searchKeyEqualTo(
      String searchKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'searchKey',
        value: [searchKey],
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterWhereClause> searchKeyNotEqualTo(
      String searchKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchKey',
              lower: [],
              upper: [searchKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchKey',
              lower: [searchKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchKey',
              lower: [searchKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'searchKey',
              lower: [],
              upper: [searchKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LibraryBookQueryFilter
    on QueryBuilder<LibraryBook, LibraryBook, QFilterCondition> {
  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> authorEqualTo(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> authorLessThan(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> authorBetween(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> authorEndsWith(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> authorContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> authorMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'author',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorDiedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'authorDied',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorDiedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'authorDied',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorDiedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authorDied',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorDiedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'authorDied',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorDiedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'authorDied',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      authorDiedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'authorDied',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> bookIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      bookIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> bookIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> bookIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      bookIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> bookIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> bookIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bookId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> bookIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bookId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      bookIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookId',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      bookIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bookId',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> categoryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> chaptersEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapters',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      chaptersGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chapters',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      chaptersLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chapters',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> chaptersBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chapters',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> charsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chars',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      charsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chars',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> charsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chars',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> charsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chars',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      chunkBaseEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chunkBase',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      chunkBaseGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chunkBase',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      chunkBaseLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chunkBase',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      chunkBaseBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chunkBase',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      downloadedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      downloadedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'downloadedAt',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      downloadedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'downloadedAt',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      downloadedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      downloadedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      downloadedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      downloadedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      filePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      filePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> filePathEqualTo(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> filePathBetween(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> filePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastChapterEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastChapter',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastChapterGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastChapter',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastChapterLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastChapter',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastChapterBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastChapter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastOpenedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastOpenedAt',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastOpenedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastOpenedAt',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastOpenedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastOpenedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastOpenedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastOpenedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastOpenedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastOpenedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      lastOpenedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastOpenedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> progressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      progressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      progressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> progressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'searchKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'searchKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'searchKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'searchKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'searchKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'searchKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'searchKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'searchKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'searchKey',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      searchKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'searchKey',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sizeKbEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sizeKb',
        value: value,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sizeKbLessThan(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sizeKbBetween(
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

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sourceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> sourceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      versionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'version',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      versionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'version',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> versionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      versionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> versionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> versionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      versionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> versionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> versionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition> versionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'version',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      versionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: '',
      ));
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterFilterCondition>
      versionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'version',
        value: '',
      ));
    });
  }
}

extension LibraryBookQueryObject
    on QueryBuilder<LibraryBook, LibraryBook, QFilterCondition> {}

extension LibraryBookQueryLinks
    on QueryBuilder<LibraryBook, LibraryBook, QFilterCondition> {}

extension LibraryBookQuerySortBy
    on QueryBuilder<LibraryBook, LibraryBook, QSortBy> {
  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByAuthorDied() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorDied', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByAuthorDiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorDied', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapters', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByChaptersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapters', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByChars() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chars', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByCharsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chars', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByChunkBase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkBase', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByChunkBaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkBase', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByDownloadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy>
      sortByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByLastChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChapter', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByLastChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChapter', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByLastOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy>
      sortByLastOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortBySearchKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchKey', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortBySearchKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchKey', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortBySizeKb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortBySizeKbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension LibraryBookQuerySortThenBy
    on QueryBuilder<LibraryBook, LibraryBook, QSortThenBy> {
  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByAuthorDied() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorDied', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByAuthorDiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorDied', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByBookId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByBookIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookId', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapters', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByChaptersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapters', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByChars() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chars', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByCharsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chars', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByChunkBase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkBase', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByChunkBaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chunkBase', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByDownloadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy>
      thenByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByLastChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChapter', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByLastChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastChapter', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByLastOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy>
      thenByLastOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedAt', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenBySearchKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchKey', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenBySearchKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'searchKey', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenBySizeKb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenBySizeKbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeKb', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension LibraryBookQueryWhereDistinct
    on QueryBuilder<LibraryBook, LibraryBook, QDistinct> {
  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByAuthor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'author', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByAuthorDied() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authorDied');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByBookId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapters');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByChars() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chars');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByChunkBase() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chunkBase');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloaded');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadedAt');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByFilePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByLastChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastChapter');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByLastOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastOpenedAt');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctBySearchKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'searchKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctBySizeKb() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sizeKb');
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LibraryBook, LibraryBook, QDistinct> distinctByVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version', caseSensitive: caseSensitive);
    });
  }
}

extension LibraryBookQueryProperty
    on QueryBuilder<LibraryBook, LibraryBook, QQueryProperty> {
  QueryBuilder<LibraryBook, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LibraryBook, String, QQueryOperations> authorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'author');
    });
  }

  QueryBuilder<LibraryBook, int?, QQueryOperations> authorDiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authorDied');
    });
  }

  QueryBuilder<LibraryBook, String, QQueryOperations> bookIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookId');
    });
  }

  QueryBuilder<LibraryBook, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<LibraryBook, int, QQueryOperations> chaptersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapters');
    });
  }

  QueryBuilder<LibraryBook, int, QQueryOperations> charsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chars');
    });
  }

  QueryBuilder<LibraryBook, int, QQueryOperations> chunkBaseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chunkBase');
    });
  }

  QueryBuilder<LibraryBook, bool, QQueryOperations> downloadedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloaded');
    });
  }

  QueryBuilder<LibraryBook, DateTime?, QQueryOperations>
      downloadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadedAt');
    });
  }

  QueryBuilder<LibraryBook, String?, QQueryOperations> filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<LibraryBook, int, QQueryOperations> lastChapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastChapter');
    });
  }

  QueryBuilder<LibraryBook, DateTime?, QQueryOperations>
      lastOpenedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastOpenedAt');
    });
  }

  QueryBuilder<LibraryBook, double, QQueryOperations> progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<LibraryBook, String, QQueryOperations> searchKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'searchKey');
    });
  }

  QueryBuilder<LibraryBook, int, QQueryOperations> sizeKbProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sizeKb');
    });
  }

  QueryBuilder<LibraryBook, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<LibraryBook, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<LibraryBook, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<LibraryBook, String?, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLibrarySyncStampCollection on Isar {
  IsarCollection<LibrarySyncStamp> get librarySyncStamps => this.collection();
}

const LibrarySyncStampSchema = CollectionSchema(
  name: r'LibrarySyncStamp',
  id: -7966502862493434828,
  properties: {
    r'added': PropertySchema(
      id: 0,
      name: r'added',
      type: IsarType.long,
    ),
    r'at': PropertySchema(
      id: 1,
      name: r'at',
      type: IsarType.dateTime,
    ),
    r'books': PropertySchema(
      id: 2,
      name: r'books',
      type: IsarType.long,
    ),
    r'updated': PropertySchema(
      id: 3,
      name: r'updated',
      type: IsarType.long,
    )
  },
  estimateSize: _librarySyncStampEstimateSize,
  serialize: _librarySyncStampSerialize,
  deserialize: _librarySyncStampDeserialize,
  deserializeProp: _librarySyncStampDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _librarySyncStampGetId,
  getLinks: _librarySyncStampGetLinks,
  attach: _librarySyncStampAttach,
  version: '3.1.0+1',
);

int _librarySyncStampEstimateSize(
  LibrarySyncStamp object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _librarySyncStampSerialize(
  LibrarySyncStamp object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.added);
  writer.writeDateTime(offsets[1], object.at);
  writer.writeLong(offsets[2], object.books);
  writer.writeLong(offsets[3], object.updated);
}

LibrarySyncStamp _librarySyncStampDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LibrarySyncStamp();
  object.added = reader.readLong(offsets[0]);
  object.at = reader.readDateTime(offsets[1]);
  object.books = reader.readLong(offsets[2]);
  object.id = id;
  object.updated = reader.readLong(offsets[3]);
  return object;
}

P _librarySyncStampDeserializeProp<P>(
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
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _librarySyncStampGetId(LibrarySyncStamp object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _librarySyncStampGetLinks(LibrarySyncStamp object) {
  return [];
}

void _librarySyncStampAttach(
    IsarCollection<dynamic> col, Id id, LibrarySyncStamp object) {
  object.id = id;
}

extension LibrarySyncStampQueryWhereSort
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QWhere> {
  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LibrarySyncStampQueryWhere
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QWhereClause> {
  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterWhereClause>
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

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterWhereClause> idBetween(
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

extension LibrarySyncStampQueryFilter
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QFilterCondition> {
  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      addedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'added',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      addedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'added',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      addedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'added',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      addedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'added',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      atEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'at',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      atGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'at',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      atLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'at',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      atBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'at',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      booksEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'books',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      booksGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'books',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      booksLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'books',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      booksBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'books',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
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

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
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

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
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

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      updatedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updated',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      updatedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updated',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      updatedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updated',
        value: value,
      ));
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterFilterCondition>
      updatedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LibrarySyncStampQueryObject
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QFilterCondition> {}

extension LibrarySyncStampQueryLinks
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QFilterCondition> {}

extension LibrarySyncStampQuerySortBy
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QSortBy> {
  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy> sortByAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'added', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      sortByAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'added', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy> sortByAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      sortByAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy> sortByBooks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'books', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      sortByBooksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'books', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      sortByUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      sortByUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated', Sort.desc);
    });
  }
}

extension LibrarySyncStampQuerySortThenBy
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QSortThenBy> {
  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy> thenByAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'added', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      thenByAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'added', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy> thenByAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      thenByAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'at', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy> thenByBooks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'books', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      thenByBooksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'books', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      thenByUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated', Sort.asc);
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QAfterSortBy>
      thenByUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated', Sort.desc);
    });
  }
}

extension LibrarySyncStampQueryWhereDistinct
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QDistinct> {
  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QDistinct>
      distinctByAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'added');
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QDistinct> distinctByAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'at');
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QDistinct>
      distinctByBooks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'books');
    });
  }

  QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QDistinct>
      distinctByUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updated');
    });
  }
}

extension LibrarySyncStampQueryProperty
    on QueryBuilder<LibrarySyncStamp, LibrarySyncStamp, QQueryProperty> {
  QueryBuilder<LibrarySyncStamp, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LibrarySyncStamp, int, QQueryOperations> addedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'added');
    });
  }

  QueryBuilder<LibrarySyncStamp, DateTime, QQueryOperations> atProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'at');
    });
  }

  QueryBuilder<LibrarySyncStamp, int, QQueryOperations> booksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'books');
    });
  }

  QueryBuilder<LibrarySyncStamp, int, QQueryOperations> updatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updated');
    });
  }
}
