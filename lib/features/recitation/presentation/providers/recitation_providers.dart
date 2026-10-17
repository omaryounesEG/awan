import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/features/recitation/data/datasources/mushaf_source.dart';
import 'package:awan/features/recitation/data/datasources/recitation_model_installer.dart';
import 'package:awan/features/recitation/data/repositories/recitation_repository.dart';

/// Where the recitation screen gets its model files. Overridable at build time
/// (`--dart-define=AWAN_LIBRARY_CDN=…`), same switch the library and the
/// semantic encoder use, so one server can serve both.
const String kRecitationCdn = String.fromEnvironment(
  'AWAN_LIBRARY_CDN',
  defaultValue: 'https://cdn.saibrx.app',
);

final Provider<RecitationModelInstaller> recitationInstallerProvider =
    Provider<RecitationModelInstaller>((Ref ref) => RecitationModelInstaller());

final Provider<RecitationRepository> recitationRepositoryProvider =
    Provider<RecitationRepository>((Ref ref) {
  final RecitationRepository repo = RecitationRepository(
    installer: ref.watch(recitationInstallerProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

class RecitationUiState {
  const RecitationUiState({
    required this.snapshot,
    this.surah = 1,
    this.ayah = 1,
    this.surahName = 'الفاتحة',
    this.modelInstalled = false,
    this.modelBytes = 0,
    this.downloading = false,
    this.downloadProgress = 0,
    this.showHeard = false,
    this.downloadError,
    this.downloadSource,
  });

  final RecitationSnapshot snapshot;
  final int surah;
  final int ayah;
  final String surahName;
  final bool modelInstalled;
  final int modelBytes;
  final bool downloading;
  final double downloadProgress;
  final bool showHeard;

  /// A reason code (`offline`, `timeout`, `not_found`, …) when the last
  /// download failed. Kept until the next attempt, so a failure never looks
  /// like a button that did nothing.
  final String? downloadError;

  /// Which mirror served the model — shown only when it fell back, because
  /// that is information the user did not have before.
  final String? downloadSource;

  RecitationUiState copyWith({
    RecitationSnapshot? snapshot,
    int? surah,
    int? ayah,
    String? surahName,
    bool? modelInstalled,
    int? modelBytes,
    bool? downloading,
    double? downloadProgress,
    bool? showHeard,
    String? downloadError,
    String? downloadSource,
  }) {
    return RecitationUiState(
      snapshot: snapshot ?? this.snapshot,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      surahName: surahName ?? this.surahName,
      modelInstalled: modelInstalled ?? this.modelInstalled,
      modelBytes: modelBytes ?? this.modelBytes,
      downloading: downloading ?? this.downloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      showHeard: showHeard ?? this.showHeard,
      downloadError: downloadError,
      downloadSource: downloadSource ?? this.downloadSource,
    );
  }
}

class RecitationController extends StateNotifier<RecitationUiState> {
  RecitationController(this._repo, this._installer)
      : super(RecitationUiState(snapshot: _repo.state)) {
    _subscription = _repo.snapshots.listen((RecitationSnapshot snapshot) {
      if (mounted) state = state.copyWith(snapshot: snapshot);
    });
    unawaited(refreshModel());
  }

  final RecitationRepository _repo;
  final RecitationModelInstaller _installer;
  StreamSubscription<RecitationSnapshot>? _subscription;

  RecitationRepository get repository => _repo;

  Future<void> refreshModel() async {
    final bool installed = await _installer.isInstalled();
    final int bytes = await _installer.installedBytes();
    if (!mounted) return;
    state = state.copyWith(modelInstalled: installed, modelBytes: bytes);
    if (installed) {
      await _repo.prepare(surah: state.surah, ayah: state.ayah, surahName: state.surahName);
    }
  }

  /// Where the model may come from, in order: the mirror baked into this
  /// build, then Hugging Face. A private mirror is a convenience, never a
  /// single point of failure.
  static List<ModelSource> get sources => <ModelSource>[
        ModelSource(label: Uri.tryParse(kRecitationCdn)?.host ?? 'cdn', base: kRecitationCdn),
        ModelSource.huggingFace,
      ];

  Future<void> download({List<ModelSource>? from}) async {
    state = state.copyWith(
      downloading: true,
      downloadProgress: 0,
      downloadError: null,
      downloadSource: null,
    );
    try {
      await _repo.installModel(
        sources: from ?? sources,
        onProgress: (double p) {
          if (mounted) state = state.copyWith(downloadProgress: p);
        },
        onSource: (ModelSource s) {
          if (mounted) state = state.copyWith(downloadSource: s.label);
        },
      );
      if (!mounted) return;
      state = state.copyWith(downloading: false, downloadProgress: 1);
      await refreshModel();
    } on ModelDownloadException catch (error) {
      if (!mounted) return;
      state = state.copyWith(downloading: false, downloadError: error.reason);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(downloading: false, downloadError: 'unknown');
    }
  }

  Future<void> select({required int surah, required int ayah, required String surahName}) async {
    if (mounted) {
      state = state.copyWith(surah: surah, ayah: ayah, surahName: surahName);
    }
    await _repo.gotoAyah(surah, ayah, surahName: surahName);
  }

  Future<void> start() => _repo.listen();

  Future<void> stop() => _repo.stop();

  Future<void> feed(File file) => _repo.feed(file);

  Future<void> trySample() => _repo.feedSample();

  void toggleHeard() => state = state.copyWith(showHeard: !state.showHeard);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<RecitationController, RecitationUiState> recitationProvider =
    StateNotifierProvider<RecitationController, RecitationUiState>((Ref ref) {
  return RecitationController(
    ref.watch(recitationRepositoryProvider),
    ref.watch(recitationInstallerProvider),
  );
});

final FutureProvider<List<SurahMeta>> surahListProvider =
    FutureProvider<List<SurahMeta>>((Ref ref) async {
  return ref.watch(recitationRepositoryProvider).mushaf.surahs();
});
