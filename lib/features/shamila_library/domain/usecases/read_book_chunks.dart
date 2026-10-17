import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';

/// "Give me the next screenful of this book."
///
/// Paged on purpose: a large book is thousands of chunks, and asking Isar for
/// all of them to draw the first screen is how a reader stutters on open.
class ReadBookChunks {
  const ReadBookChunks(this._repository);

  final LibraryRepository _repository;

  Future<List<BookChunk>> call(
    String bookId, {
    int from = 0,
    int count = 40,
  }) =>
      _repository.chunks(bookId, from: from, count: count);
}
