import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/updates/data/repositories/update_repository.dart';
import 'package:awan/features/updates/domain/entities/update_entities.dart';

/// The exact asset list published under `v1.23.0`, replayed through the real
/// parser. Names are a contract: `patchFrom` only fires when the file is called
/// `<from>__<to>.patch`, so a rename during publish silently turns every delta
/// into a full download — the one failure the user feels as "it downloaded the
/// whole app again".
void main() {
  const Map<String, int> published = <String, int>{
    'Awan_v1.23.0-arm64-v8a.apk': 97946431,
    'Awan_v1.23.0-armeabi-v7a.apk': 87045935,
    '1.22.1__1.23.0.patch': 4079449,
    '1.22.0__1.23.0.patch': 7372272,
    'SHA256SUMS': 362,
  };

  Map<String, dynamic> payload() => <String, dynamic>{
        'tag_name': 'v1.23.0',
        'body': '',
        'published_at': '2026-10-18T10:15:00Z',
        'assets': <Map<String, dynamic>>[
          for (final MapEntry<String, int> a in published.entries)
            <String, dynamic>{
              'name': a.key,
              'size': a.value,
              'browser_download_url':
                  'https://github.com/omaryounesEG/awan/releases/download/v1.23.0/${a.key}',
            },
        ],
      };

  test('a 1.22.1 install is offered the 3.9 MB delta', () {
    final AppRelease r =
        UpdateRepository.parseRelease(payload(), abi: 'arm64-v8a')!;
    final PatchAsset? p = r.patchFrom('1.22.1+27');
    expect(p, isNotNull);
    expect(p!.name, '1.22.1__1.23.0.patch');
    expect(p.bytes, lessThan(r.apkBytes ~/ 10));
  });

  test('a 1.22.0 install is still offered a delta, not the full APK', () {
    final AppRelease r =
        UpdateRepository.parseRelease(payload(), abi: 'arm64-v8a')!;
    expect(r.patchFrom('1.22.0+26')?.name, '1.22.0__1.23.0.patch');
  });

  test('the arm64 APK is chosen for an arm64 device', () {
    final AppRelease r =
        UpdateRepository.parseRelease(payload(), abi: 'arm64-v8a')!;
    expect(r.apkUrl, endsWith('Awan_v1.23.0-arm64-v8a.apk'));
  });

  test('a build from before both deltas falls back to the full APK', () {
    final AppRelease r =
        UpdateRepository.parseRelease(payload(), abi: 'arm64-v8a')!;
    expect(r.patchFrom('1.21.0+25'), isNull);
  });
}
