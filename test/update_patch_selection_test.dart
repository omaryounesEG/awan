import 'package:awan/features/updates/data/repositories/update_repository.dart';
import 'package:awan/features/updates/domain/entities/update_entities.dart';
import 'package:flutter_test/flutter_test.dart';

/// Choosing the right delta is the one decision that can silently corrupt an
/// install if it is made loosely — a patch is only valid for the exact build it
/// was cut from, so the pairing is asserted here, not assumed.
Map<String, dynamic> payload() => <String, dynamic>{
      'tag_name': 'v1.21.0',
      'body': 'release notes',
      'published_at': '2026-10-17T10:00:00Z',
      'assets': <dynamic>[
        <String, dynamic>{
          'name': 'Awan_v1.21.0-arm64-v8a.apk',
          'size': 97880631,
          'browser_download_url': 'https://example.test/Awan_v1.21.0-arm64-v8a.apk',
        },
        <String, dynamic>{
          'name': '1.20.0__1.21.0.patch',
          'size': 4700000,
          'browser_download_url': 'https://example.test/1.20.0__1.21.0.patch',
        },
        <String, dynamic>{
          'name': '1.19.1__1.21.0.patch',
          'size': 6100000,
          'browser_download_url': 'https://example.test/1.19.1__1.21.0.patch',
        },
      ],
    };

void main() {
  test('every delta asset is collected, not just the first', () {
    final AppRelease? r = UpdateRepository.parseRelease(payload());
    expect(r, isNotNull);
    expect(r!.patches.length, 2);
    expect(r.patches.containsKey('1.20.0__1.21.0.patch'), isTrue);
  });

  test('the delta is chosen by the installed version, ignoring the build number', () {
    final AppRelease r = UpdateRepository.parseRelease(payload())!;
    final PatchAsset? p = r.patchFrom('1.20.0+24');
    expect(p, isNotNull);
    expect(p!.name, '1.20.0__1.21.0.patch');
    expect(p.sizeLabel, '4.5 MB');
  });

  test('a delta from a different version is never used', () {
    final AppRelease r = UpdateRepository.parseRelease(payload())!;
    expect(r.patchFrom('1.19.1+23')!.name, '1.19.1__1.21.0.patch');
    expect(r.patchFrom('1.18.0+21'), isNull);
  });

  test('a release with no delta simply offers the full APK', () {
    final Map<String, dynamic> json = payload();
    (json['assets'] as List<dynamic>).removeWhere(
      (dynamic a) => (a['name'] as String).endsWith('.patch'),
    );
    final AppRelease r = UpdateRepository.parseRelease(json)!;
    expect(r.patches, isEmpty);
    expect(r.patchFrom('1.20.0'), isNull);
  });

  test('a malformed patch name is ignored instead of guessed', () {
    final Map<String, dynamic> json = payload();
    (json['assets'] as List<dynamic>).add(<String, dynamic>{
      'name': 'update.patch',
      'size': 10,
      'browser_download_url': 'https://example.test/update.patch',
    });
    final AppRelease r = UpdateRepository.parseRelease(json)!;
    expect(r.patchFrom('1.20.0'), isNotNull);
    expect(r.patchFrom('update'), isNull);
  });
}
