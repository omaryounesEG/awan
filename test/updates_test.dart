import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/updates/data/repositories/update_repository.dart';
import 'package:awan/features/updates/domain/entities/update_entities.dart';
import 'package:awan/features/updates/domain/usecases/compare_versions.dart';

/// The update path has one job that must never fail: **do not offer a build
/// that is not newer, and do not install bytes that do not match the published
/// checksum.** Everything here tests one of those two promises.
void main() {
  group('version comparison', () {
    test('reads the tags GitHub actually produces', () {
      expect(SemVer.tryParse('v1.19.2'), const SemVer(1, 19, 2));
      expect(SemVer.tryParse('1.19.2'), const SemVer(1, 19, 2));
      // Build metadata is not part of "is this release newer".
      expect(SemVer.tryParse('1.19.1+23'), const SemVer(1, 19, 1));
      expect(SemVer.tryParse('1.20.0-rc1'), const SemVer(1, 20, 0));
      expect(SemVer.tryParse('2'), const SemVer(2, 0, 0));
    });

    test('an unparsable tag is never newer', () {
      expect(SemVer.tryParse('release-latest'), isNull);
      expect(isNewerVersion('release-latest', '1.19.1'), isFalse);
      expect(isNewerVersion('1.19.2', 'not-a-version'), isFalse);
    });

    test('compares numerically, not as text', () {
      expect(isNewerVersion('1.19.10', '1.19.9'), isTrue,
          reason: 'string comparison would call 1.19.10 older');
      expect(isNewerVersion('1.9.0', '1.19.0'), isFalse);
      expect(isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(isNewerVersion('1.19.1', '1.19.1'), isFalse,
          reason: 'the same version is not an update');
      expect(isNewerVersion('1.19.0', '1.19.1'), isFalse,
          reason: 'never offer a downgrade');
    });

    test('same version with a different build number is not an update', () {
      expect(isNewerVersion('1.19.1+24', '1.19.1+23'), isFalse);
    });
  });

  group('release parsing', () {
    Map<String, dynamic> githubPayload({
      String tag = 'v1.20.0',
      String body = '',
      List<Map<String, dynamic>>? assets,
    }) {
      return <String, dynamic>{
        'tag_name': tag,
        'body': body,
        'published_at': '2026-10-17T09:00:00Z',
        'assets': assets ??
            <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'Awan_v1.20.0_emulator.apk',
                'size': 1000,
                'browser_download_url': 'https://example.test/emu.apk',
              },
              <String, dynamic>{
                'name': 'Awan_v1.20.0-arm64-v8a.apk',
                'size': 120000000,
                'browser_download_url': 'https://example.test/arm64.apk',
              },
            ],
      };
    }

    test('prefers the arm64 phone build over the emulator one', () {
      final AppRelease? r = UpdateRepository.parseRelease(githubPayload());
      expect(r, isNotNull);
      expect(r!.apkUrl, 'https://example.test/arm64.apk');
      expect(r.version, '1.20.0');
      expect(r.apkBytes, 120000000);
      expect(r.sizeLabel, '114.4 MB');
    });

    test('reads a checksum published in the release body', () {
      const String hex =
          '9f2c1d3e4b5a69788796a5b4c3d2e1f00112233445566778899aabbccddeeff0';
      final AppRelease? r = UpdateRepository.parseRelease(
        githubPayload(body: 'What is new…\n\nsha256: $hex\n'),
      );
      expect(r!.sha256, hex);
    });

    test('a checksums file wins, line by line, over the body', () {
      const String want =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const String other =
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      final AppRelease? r = UpdateRepository.parseRelease(
        githubPayload(body: 'no checksum here'),
        checksumsText: '$other  Awan_v1.20.0_emulator.apk\n'
            '$want  Awan_v1.20.0-arm64-v8a.apk\n',
      );
      expect(r!.sha256, want);
    });

    test('a release with no APK asset is not an update', () {
      final AppRelease? r = UpdateRepository.parseRelease(
        githubPayload(assets: <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'notes.txt',
            'size': 10,
            'browser_download_url': 'https://example.test/notes.txt',
          },
        ]),
      );
      expect(r, isNull);
    });

    test('no published checksum stays null — it is never invented', () {
      final AppRelease? r = UpdateRepository.parseRelease(githubPayload());
      expect(r!.sha256, isNull);
    });
  });
}
