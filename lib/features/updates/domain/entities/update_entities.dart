import 'package:equatable/equatable.dart';

/// A published build, as GitHub describes it.
///
/// Deliberately plain: no model, no JSON mapping, no network. The repository
/// turns GitHub's payload into this, and the UI only ever sees this.
/// A delta published next to the full APK: `1.20.0__1.21.0.patch`.
///
/// Named after both ends on purpose — a patch is meaningless without knowing
/// which build it starts from, so the name carries that rather than a guessing
/// game in the client.
class PatchAsset extends Equatable {
  const PatchAsset({required this.name, required this.url, required this.bytes});

  final String name;
  final String url;
  final int bytes;

  /// `1.20.0__1.21.0.patch` → (`1.20.0`, `1.21.0`).
  (String, String)? get fromTo {
    final String base = name.endsWith('.patch') ? name.substring(0, name.length - 6) : name;
    final int split = base.indexOf('__');
    if (split <= 0) return null;
    return (base.substring(0, split), base.substring(split + 2));
  }

  String get sizeLabel => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  List<Object?> get props => <Object?>[name, url, bytes];
}

class AppRelease extends Equatable {
  const AppRelease({
    required this.version,
    required this.tag,
    required this.notes,
    required this.apkUrl,
    required this.apkBytes,
    required this.sha256,
    required this.publishedAt,
    this.patches = const <String, PatchAsset>{},
  });

  /// `1.19.2` — the tag without its leading `v`, which is what a version is.
  final String version;
  final String tag;
  final String notes;
  final String apkUrl;
  final int apkBytes;

  /// Published by the release itself (body line or `SHA256SUMS` asset).
  /// `null` means the maintainer did not publish one, and the UI must say so
  /// rather than pretend the download was verified.
  final String? sha256;

  final DateTime? publishedAt;

  /// Deltas published with this release, keyed by asset name.
  final Map<String, PatchAsset> patches;

  /// The delta that upgrades [currentVersion] to this release, if published.
  ///
  /// Compared on the version alone: a build number differs on every build and
  /// would make the lookup miss for the very users it is meant to serve.
  PatchAsset? patchFrom(String currentVersion) {
    final String clean = currentVersion.split('+').first;
    for (final PatchAsset p in patches.values) {
      final (String, String)? ends = p.fromTo;
      if (ends == null) continue;
      if (ends.$1 == clean && ends.$2 == version) return p;
    }
    return null;
  }

  String get sizeLabel {
    if (apkBytes <= 0) return '';
    final double mb = apkBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => <Object?>[version, tag, apkUrl, apkBytes, sha256, patches];
}

/// The outcome of a manual check. There are five of them because the app has to
/// be honest about *why* nothing happened, not just "no update".
enum UpdateStatus {
  /// This build was compiled without a repository to ask.
  notConfigured,

  /// Asked, and the published release is this one or older.
  upToDate,

  /// A newer build exists and can be downloaded.
  available,

  /// The request failed — no network, rate limit, missing release.
  failed,
}

class UpdateCheck extends Equatable {
  const UpdateCheck({
    required this.status,
    this.release,
    this.currentVersion = '',
    this.message,
  });

  final UpdateStatus status;
  final AppRelease? release;
  final String currentVersion;
  final String? message;

  bool get hasUpdate => status == UpdateStatus.available && release != null;

  @override
  List<Object?> get props => <Object?>[status, release, currentVersion, message];
}

/// What the download is doing right now.
enum DownloadPhase { idle, downloading, verifying, ready, failed }

class DownloadState extends Equatable {
  const DownloadState({
    this.phase = DownloadPhase.idle,
    this.received = 0,
    this.total = 0,
    this.path,
    this.verified = false,
    this.error,
    this.viaPatch = false,
  });

  final DownloadPhase phase;
  final int received;
  final int total;
  final String? path;

  /// True only when a published SHA-256 was compared and matched.
  final bool verified;
  final String? error;

  /// True when the APK was rebuilt on the device from a delta instead of
  /// downloaded whole — worth saying out loud, because the download was a
  /// tenth of the size the user expected.
  final bool viaPatch;

  double get progress => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0);

  DownloadState copyWith({
    DownloadPhase? phase,
    int? received,
    int? total,
    String? path,
    bool? verified,
    String? error,
    bool? viaPatch,
  }) {
    return DownloadState(
      phase: phase ?? this.phase,
      received: received ?? this.received,
      total: total ?? this.total,
      path: path ?? this.path,
      verified: verified ?? this.verified,
      error: error ?? this.error,
      viaPatch: viaPatch ?? this.viaPatch,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[phase, received, total, path, verified, error, viaPatch];
}
