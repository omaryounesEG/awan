import 'package:dartz/dartz.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/features/shamila_library/domain/entities/library_entities.dart';
import 'package:awan/features/shamila_library/domain/repositories/library_repository.dart';

/// "Refresh the catalogue."
///
/// One file, one request: the index lists every book with its size and URL, so
/// the app can search, sort and price the download before anything else is
/// fetched. `force` re-downloads even when a cached index exists.
class SyncLibraryIndex {
  const SyncLibraryIndex(this._repository);

  final LibraryRepository _repository;

  Future<Either<Failure, LibrarySyncReport>> call({bool force = false}) =>
      _repository.syncIndex(force: force);
}
