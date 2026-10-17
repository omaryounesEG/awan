import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';

/// "Which books match what I typed?"
///
/// Always local: the index lives in Isar, so typing never waits for a network
/// round-trip and keeps working with the radio off.
class SearchLibrary {
  const SearchLibrary(this._repository);

  final LibraryRepository _repository;

  Future<List<BookEntry>> call({
    String query = '',
    String? category,
    int limit = 200,
  }) =>
      _repository.search(query: query, category: category, limit: limit);
}
