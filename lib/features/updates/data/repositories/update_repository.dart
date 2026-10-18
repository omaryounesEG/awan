import 'dart:io';

import 'package:crypto/crypto.dart' show Digest, sha256;
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/updates/data/datasources/apk_installer.dart';
import 'package:awan/features/updates/data/datasources/chunk_patch.dart';
import 'package:awan/features/updates/data/datasources/github_releases.dart';
import 'package:awan/features/updates/domain/entities/update_entities.dart';
import 'package:awan/features/updates/domain/usecases/compare_versions.dart';

/// The whole update story: ask GitHub, decide, download, verify, hand over.
///
/// Three decisions worth stating out loud:
///
/// * **Nothing is checked automatically.** No timer, no boot receiver, no
///   background isolate — the user pressed a button, or nothing happened.
/// * **A checksum decides trust.** If the release publishes a SHA-256, the
///   downloaded bytes must match it or the file is deleted and the update is
///   refused. If no checksum was published, the UI says "not verified" in
///   plain words instead of showing a green tick it did not earn.
/// * **The app never installs silently.** It hands the APK to Android's own
///   installer; the user's confirmation is the last step and cannot be skipped.
class UpdateRepository {
  UpdateRepository({
    GithubReleases? releases,
    ApkInstallerBridge installer = const ApkInstallerBridge(),
    Dio? dio,
  })  : _releases = releases ?? GithubReleases(repo: AppConstants.updateRepo),
        _installer = installer,
        _dio = dio ?? Dio();

  final GithubReleases _releases;
  final ApkInstallerBridge _installer;
  final Dio _dio;

  String get currentVersion => AppConstants.appVersion;

  Future<UpdateCheck> check() async {
    if (!_releases.isConfigured) {
      return UpdateCheck(
        status: UpdateStatus.notConfigured,
        currentVersion: currentVersion,
      );
    }
    try {
      final Map<String, dynamic> json = await _releases.latestRelease();
      final String? sumsUrl = _checksumAssetUrl(json);
      final String? sums = sumsUrl == null ? null : await _releases.fetchTextAsset(sumsUrl);
      // Which asset to hand this phone: 32-bit and 64-bit builds are both
      // published, and installing the wrong one fails at the very end.
      final String? abi = await _installer.primaryAbi();
      final AppRelease? release = parseRelease(json, checksumsText: sums, abi: abi);
      if (release == null) {
        return UpdateCheck(
          status: UpdateStatus.failed,
          currentVersion: currentVersion,
          message: 'no_apk_asset',
        );
      }
      final bool newer = isNewerVersion(release.version, currentVersion);
      return UpdateCheck(
        status: newer ? UpdateStatus.available : UpdateStatus.upToDate,
        release: release,
        currentVersion: currentVersion,
      );
    } on ReleasesUnavailable catch (e) {
      return UpdateCheck(
        status: UpdateStatus.failed,
        currentVersion: currentVersion,
        message: e.code,
      );
    } catch (e) {
      return UpdateCheck(
        status: UpdateStatus.failed,
        currentVersion: currentVersion,
        message: 'network',
      );
    }
  }

  /// Pure parsing, unit-tested against real GitHub payload shapes.
  static AppRelease? parseRelease(
    Map<String, dynamic> json, {
    String? checksumsText,
    String? abi,
  }) {
    final List<dynamic> assets = (json['assets'] as List<dynamic>?) ?? <dynamic>[];
    // A release carries one APK per ABI. Picking by name alone hands a 32-bit
    // phone a 64-bit build, which downloads fine and fails at install time.
    final String device = (abi ?? '').toLowerCase();
    final String? preferred = device.isEmpty
        ? null
        : (device.contains('64') ? 'arm64' : 'armeabi-v7a');
    Map<String, dynamic>? apk;
    for (final dynamic raw in assets) {
      if (raw is! Map<String, dynamic>) continue;
      final String name = (raw['name'] as String? ?? '').toLowerCase();
      if (!name.endsWith('.apk')) continue;
      // Remember the first APK as the last resort, then insist on the one this
      // device can actually run.
      apk ??= raw;
      if (preferred != null && name.contains(preferred)) {
        apk = raw;
        break;
      }
      // Unknown ABI (tests, desktop): keep the old arm64 default.
      if (preferred == null && name.contains('arm64')) {
        apk = raw;
        break;
      }
    }
    if (apk == null) return null;

    final String tag = (json['tag_name'] as String? ?? '').trim();
    final String version = tag.replaceFirst(RegExp(r'^[vV]'), '');
    final String body = (json['body'] as String? ?? '').trim();
    final String? url = apk['browser_download_url'] as String?;
    if (url == null || version.isEmpty) return null;

    final Map<String, PatchAsset> patches = <String, PatchAsset>{};
    for (final dynamic raw in assets) {
      if (raw is! Map<String, dynamic>) continue;
      final String name = raw['name'] as String? ?? '';
      if (!name.toLowerCase().endsWith('.patch')) continue;
      final String? patchUrl = raw['browser_download_url'] as String?;
      if (patchUrl == null) continue;
      patches[name] = PatchAsset(
        name: name,
        url: patchUrl,
        bytes: (raw['size'] as num?)?.toInt() ?? 0,
      );
    }

    final String? apkName = apk['name'] as String?;
    return AppRelease(
      version: version,
      tag: tag,
      notes: body,
      apkUrl: url,
      apkBytes: (apk['size'] as num?)?.toInt() ?? 0,
      sha256: _findChecksum(checksumsText, apkName) ?? _findChecksum(body, apkName),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      patches: patches,
    );
  }

  static String? _checksumAssetUrl(Map<String, dynamic> json) {
    for (final dynamic raw in (json['assets'] as List<dynamic>?) ?? <dynamic>[]) {
      if (raw is! Map<String, dynamic>) continue;
      final String name = (raw['name'] as String? ?? '').toUpperCase();
      if (name.startsWith('SHA256') || name == 'CHECKSUMS.TXT') {
        return raw['browser_download_url'] as String?;
      }
    }
    return null;
  }

  /// Accepts `sha256: <hex>`, `<hex>  file.apk`, or a bare 64-hex line.
  static String? _findChecksum(String? text, String? apkName) {
    if (text == null || text.isEmpty) return null;
    final RegExp hex = RegExp(r'\b([a-fA-F0-9]{64})\b');
    String? bare;
    for (final String line in text.split('\n')) {
      final RegExpMatch? m = hex.firstMatch(line);
      if (m == null) continue;
      final String candidate = m.group(1)!.toLowerCase();
      if (apkName != null && line.contains(apkName)) return candidate;
      bare ??= candidate;
    }
    return bare;
  }

  Future<File> download(
    AppRelease release, {
    void Function(int received, int total)? onProgress,
  }) async {
    final Directory dir = Directory(p.join((await getTemporaryDirectory()).path, 'updates'));
    await dir.create(recursive: true);
    final File out = File(p.join(dir.path, 'awan-${release.version}.apk'));
    if (await out.exists()) await out.delete();

    await _dio.download(
      release.apkUrl,
      out.path,
      onReceiveProgress: onProgress,
      options: Options(
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 10),
        headers: <String, String>{'Accept': 'application/octet-stream'},
      ),
    );
    return out;
  }

  /// Returns true when a published checksum was verified.
  ///
  /// Throws [ChecksumMismatch] when a checksum exists and does not match — the
  /// file is deleted first, because a corrupt APK lying around is a trap.
  Future<bool> verify(File file, AppRelease release) async {
    final String? expected = release.sha256;
    if (expected == null) return false;
    final Digest actual = sha256.convert(await file.readAsBytes());
    if (actual.toString().toLowerCase() == expected.toLowerCase()) return true;
    await file.delete();
    throw const ChecksumMismatch();
  }

  /// Path of the APK this process runs from — the input of every delta.
  Future<String?> installedApkPath() => _installer.installedApkPath();

  /// Downloads a delta and rebuilds the new APK from the installed one.
  ///
  /// The rebuilt file is verified against the release's published SHA-256
  /// *before* it is returned, and [PatchUnusable] is thrown otherwise — an APK
  /// that does not match the published build is not something to hand to an
  /// installer. Callers fall back to the full download.
  Future<File> patchToApk(
    AppRelease release,
    PatchAsset patch,
    String installedPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final String? expected = release.sha256;
    if (expected == null) {
      // Without a published hash the rebuilt APK cannot be proven to be the
      // published build, which is the whole point of patching locally.
      throw const PatchUnusable('no_checksum');
    }

    final Directory dir = Directory(p.join((await getTemporaryDirectory()).path, 'updates'));
    await dir.create(recursive: true);
    final File patchFile = File(p.join(dir.path, patch.name));
    if (await patchFile.exists()) await patchFile.delete();

    await _dio.download(
      patch.url,
      patchFile.path,
      onReceiveProgress: onProgress,
      options: Options(
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 10),
        headers: const <String, String>{'Accept': 'application/octet-stream'},
      ),
    );

    final File out = File(p.join(dir.path, 'awan-${release.version}.apk'));
    if (await out.exists()) await out.delete();

    try {
      await applyChunkPatch(
        oldFile: File(installedPath),
        patch: await patchFile.readAsBytes(),
        newFile: out,
      );
    } on ChunkPatchException catch (e) {
      if (await out.exists()) await out.delete();
      throw PatchUnusable(e.message);
    } finally {
      if (await patchFile.exists()) await patchFile.delete();
    }

    final Digest actual = await _digest(out);
    if (actual.toString().toLowerCase() != expected.toLowerCase()) {
      await out.delete();
      throw const PatchUnusable('rebuilt_apk_mismatch');
    }
    return out;
  }

  /// Streams the file through SHA-256 instead of loading 93 MB into memory.
  Future<Digest> _digest(File file) async {
    final _DigestSink sink = _DigestSink();
    final input = sha256.startChunkedConversion(sink);
    await for (final List<int> chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return sink.digest!;
  }

  Future<bool> canInstall() => _installer.canInstall();

  Future<void> install(String path) => _installer.install(path);

  Future<void> openInstallSettings() => _installer.openInstallSettings();
}

/// A delta that cannot be trusted or cannot be applied — the caller must fall
/// back to the full APK rather than retry the same patch.
class PatchUnusable implements Exception {
  const PatchUnusable(this.reason);
  final String reason;
  @override
  String toString() => 'PatchUnusable($reason)';
}

class _DigestSink implements Sink<Digest> {
  Digest? digest;
  @override
  void add(Digest data) => digest = data;
  @override
  void close() {}
}

class ChecksumMismatch implements Exception {
  const ChecksumMismatch();
  @override
  String toString() => 'ChecksumMismatch';
}
