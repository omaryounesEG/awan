import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';

/// "Bring me this book."
///
/// A stream rather than a future because the interesting part is the middle:
/// bytes, then unpacking, then rows landing in Isar — the UI shows one honest
/// bar for all three.
class DownloadBook {
  const DownloadBook(this._repository);

  final LibraryRepository _repository;

  Stream<BookInstallProgress> call(String bookId) => _repository.install(bookId);
}
