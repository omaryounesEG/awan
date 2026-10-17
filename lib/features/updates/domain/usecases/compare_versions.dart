/// Version arithmetic, kept away from the network and the UI so it can be
/// tested exhaustively.
///
/// Rules that matter here:
/// * `1.19.1+23` and `1.19.1` are the same release as far as a user is
///   concerned; the build number is not shown and must not decide an update.
/// * A tag may carry a leading `v` — GitHub tags usually do.
/// * Anything unparsable is *not* treated as newer: a typo in a tag must never
///   push an update onto people.
library;

class SemVer {
  const SemVer(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static SemVer? tryParse(String raw) {
    String text = raw.trim();
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }
    // Drop build metadata / pre-release: 1.19.2+24, 1.20.0-rc1.
    final int cut = text.indexOf(RegExp(r'[+\-]'));
    if (cut >= 0) text = text.substring(0, cut);
    final List<String> parts = text.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final List<int> numbers = <int>[];
    for (final String part in parts) {
      final int? n = int.tryParse(part);
      if (n == null || n < 0) return null;
      numbers.add(n);
    }
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return SemVer(numbers[0], numbers[1], numbers[2]);
  }

  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      other is SemVer &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}

/// True only when [candidate] is strictly newer than [current] *and* both parse.
bool isNewerVersion(String candidate, String current) {
  final SemVer? a = SemVer.tryParse(candidate);
  final SemVer? b = SemVer.tryParse(current);
  if (a == null || b == null) return false;
  return a.compareTo(b) > 0;
}
