import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/features/quran_tafseer/presentation/providers/quran_providers.dart';
import 'package:awan/features/semantic_search/data/datasources/semantic_model_installer.dart';
import 'package:awan/features/semantic_search/data/repositories/semantic_search_repository_impl.dart';
import 'package:awan/features/semantic_search/domain/entities/semantic_entities.dart';

final Provider<SemanticSearchRepositoryImpl> semanticRepositoryProvider =
    Provider<SemanticSearchRepositoryImpl>((Ref ref) {
  return SemanticSearchRepositoryImpl(
    quran: ref.watch(quranRepositoryProvider),
  );
});

final Provider<SemanticModelInstaller> semanticModelInstallerProvider =
    Provider<SemanticModelInstaller>((Ref ref) => SemanticModelInstaller());

/// Whether the encoder is on the device, and how far a download has got.
class SemanticModelState {
  const SemanticModelState({
    this.phase = SemanticModelPhase.unknown,
    this.progress = 0,
    this.bytes = 0,
    this.error,
  });

  final SemanticModelPhase phase;
  final double progress;
  final int bytes;
  final String? error;

  SemanticModelState copyWith({
    SemanticModelPhase? phase,
    double? progress,
    int? bytes,
    String? error,
  }) =>
      SemanticModelState(
        phase: phase ?? this.phase,
        progress: progress ?? this.progress,
        bytes: bytes ?? this.bytes,
        error: error ?? this.error,
      );
}

enum SemanticModelPhase { unknown, missing, downloading, ready, failed }

class SemanticModelController extends StateNotifier<SemanticModelState> {
  SemanticModelController(this._installer) : super(const SemanticModelState()) {
    refresh();
  }

  final SemanticModelInstaller _installer;

  Future<void> refresh() async {
    final int bytes = await _installer.installedBytes();
    if (!mounted) return;
    state = state.copyWith(
      phase: bytes > 1000000 ? SemanticModelPhase.ready : SemanticModelPhase.missing,
      bytes: bytes,
      progress: bytes > 1000000 ? 1 : 0,
      error: null,
    );
  }

  Future<bool> download(String baseUrl) async {
    state = state.copyWith(phase: SemanticModelPhase.downloading, progress: 0);
    try {
      final int bytes = await _installer.download(
        baseUrl: baseUrl,
        onProgress: (double value) {
          if (mounted) state = state.copyWith(progress: value);
        },
      );
      if (!mounted) return true;
      state = state.copyWith(
        phase: SemanticModelPhase.ready,
        progress: 1,
        bytes: bytes,
        error: null,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(phase: SemanticModelPhase.failed, error: '$error');
      return false;
    }
  }

  Future<void> delete() async {
    await _installer.remove();
    await refresh();
  }
}

final StateNotifierProvider<SemanticModelController, SemanticModelState>
    semanticModelProvider =
    StateNotifierProvider<SemanticModelController, SemanticModelState>((Ref ref) {
  return SemanticModelController(ref.watch(semanticModelInstallerProvider));
});

/// Hybrid results: words and meaning, fused.
///
/// Falls back to the lexical half when the encoder is not on the device, so the
/// search never becomes *empty* just because a download was skipped.
final FutureProviderFamily<List<SemanticHit>, String> semanticSearchProvider =
    FutureProvider.family<List<SemanticHit>, String>((Ref ref, String query) async {
  final SemanticSearchRepositoryImpl repository =
      ref.watch(semanticRepositoryProvider);
  await repository.ensureReady();
  return repository.search(query);
});
