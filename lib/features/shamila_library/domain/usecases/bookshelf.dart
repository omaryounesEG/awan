import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';

/// "What have I actually got on this device?"
class GetBookshelf {
  const GetBookshelf(this._repository);

  final LibraryRepository _repository;

  Future<List<BookEntry>> call() => _repository.bookshelf();
}

/// The Discover tab's shelf of categories.
class GetLibraryCategories {
  const GetLibraryCategories(this._repository);

  final LibraryRepository _repository;

  Future<List<({String name, int count})>> call() => _repository.categories();
}

/// Frees the text of a book, keeping its catalogue row (re-downloadable).
class RemoveBook {
  const RemoveBook(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String bookId) => _repository.remove(bookId);
}

/// Remembers where the reader stopped, so the book opens where it closed.
class SaveReadingPosition {
  const SaveReadingPosition(this._repository);

  final LibraryRepository _repository;

  Future<void> call(String bookId, int chapter, double progress) =>
      _repository.savePosition(bookId, chapter, progress);
}
