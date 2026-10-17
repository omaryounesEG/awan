import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/features/updates/data/repositories/update_repository.dart';
import 'package:awan/features/updates/domain/entities/update_entities.dart';

final Provider<UpdateRepository> updateRepositoryProvider =
    Provider<UpdateRepository>((Ref ref) => UpdateRepository());

/// One small state machine: idle → checking → result, then download phases.
///
/// It holds no timer and starts no work on creation. Everything here happens
/// because a finger touched a button.
class UpdateState {
  const UpdateState({
    this.checking = false,
    this.check,
    this.download = const DownloadState(),
  });

  final bool checking;
  final UpdateCheck? check;
  final DownloadState download;

  UpdateState copyWith({
    bool? checking,
    UpdateCheck? check,
    DownloadState? download,
  }) {
    return UpdateState(
      checking: checking ?? this.checking,
      check: check ?? this.check,
      download: download ?? this.download,
    );
  }
}

class UpdateController extends StateNotifier<UpdateState> {
  UpdateController(this._repo) : super(const UpdateState());

  final UpdateRepository _repo;

  Future<void> checkNow() async {
    if (state.checking) return;
    state = state.copyWith(checking: true, download: const DownloadState());
    final UpdateCheck result = await _repo.check();
    if (!mounted) return;
    state = state.copyWith(checking: false, check: result);
  }

  Future<void> downloadAndInstall({required String? expectedSha}) async {
    final AppRelease? release = state.check?.release;
    if (release == null) return;
    if (state.download.phase == DownloadPhase.downloading) return;

    final PatchAsset? delta = release.patchFrom(state.check?.currentVersion ?? '');
    final String? installedPath = delta == null ? null : await _repo.installedApkPath();

    // A delta is tried first because it is a tenth of the size; everything it
    // needs is already on the device. If it is missing, refused, or rebuilds
    // something that is not the published build, the full APK follows — the
    // user asked for an update, not for a specific transport.
    // Visible in logcat as `I/flutter` in release builds, which is the only
    // place a delta decision can be observed on a device.
    debugPrint('AWAN_UPDATE delta=${delta?.name} installed=$installedPath');
    if (delta != null && installedPath != null) {
      state = state.copyWith(
        download: DownloadState(phase: DownloadPhase.downloading, total: delta.bytes),
      );
      try {
        final File rebuilt = await _repo.patchToApk(
          release,
          delta,
          installedPath,
          onProgress: (int received, int total) {
            if (!mounted) return;
            state = state.copyWith(
              download: state.download.copyWith(
                received: received,
                total: total > 0 ? total : state.download.total,
              ),
            );
          },
        );
        if (!mounted) return;
        state = state.copyWith(
          download: DownloadState(
            phase: DownloadPhase.ready,
            path: rebuilt.path,
            verified: true,
            total: release.apkBytes,
            received: release.apkBytes,
            viaPatch: true,
          ),
        );
        return;
      } on PatchUnusable catch (e) {
        debugPrint('AWAN_UPDATE patch rejected: ${e.reason}');
        // Fall through to the full download; the reason is not an error the
        // user needs to act on, it is a fallback.
      } catch (e) {
        debugPrint('AWAN_UPDATE patch failed: $e');
      }
    }

    state = state.copyWith(
      download: DownloadState(phase: DownloadPhase.downloading, total: release.apkBytes),
    );
    try {
      final File file = await _repo.download(
        release,
        onProgress: (int received, int total) {
          if (!mounted) return;
          state = state.copyWith(
            download: state.download.copyWith(
              received: received,
              total: total > 0 ? total : state.download.total,
            ),
          );
        },
      );
      if (!mounted) return;
      state = state.copyWith(download: state.download.copyWith(phase: DownloadPhase.verifying));
      final bool verified = await _repo.verify(file, release);
      if (!mounted) return;
      state = state.copyWith(
        download: state.download.copyWith(
          phase: DownloadPhase.ready,
          path: file.path,
          verified: verified,
        ),
      );
    } on ChecksumMismatch {
      if (!mounted) return;
      state = state.copyWith(
        download: const DownloadState(phase: DownloadPhase.failed, error: 'checksum'),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        download: DownloadState(phase: DownloadPhase.failed, error: '$e'),
      );
    }
  }

  /// True when Android will let this app hand over an APK right now.
  Future<bool> canInstall() => _repo.canInstall();

  Future<void> install(String path) => _repo.install(path);

  Future<void> openInstallSettings() => _repo.openInstallSettings();
}

final StateNotifierProvider<UpdateController, UpdateState> updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>(
  (Ref ref) => UpdateController(ref.watch(updateRepositoryProvider)),
);
