import 'dart:typed_data';

import 'package:awan/features/updates/data/datasources/github_releases.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with a canned status code, keyed by path.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.codes);

  final Map<String, int> codes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final int code = codes[options.path] ?? 500;
    return ResponseBody.fromString(
      code == 200 ? '{"tag_name":"v1.20.0","assets":[]}' : '{"message":"Not Found"}',
      code,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

GithubReleases build(Map<String, int> codes) {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://api.github.com',
    validateStatus: (int? c) => c != null && c < 500,
  ));
  dio.httpClientAdapter = _StubAdapter(codes);
  return GithubReleases(dio: dio, repo: 'saip/awan');
}

void main() {
  test('a missing repository is not reported as "no releases yet"', () async {
    // Both endpoints 404: the path is wrong or the repository is private.
    final GithubReleases client = build(<String, int>{
      '/repos/saip/awan/releases/latest': 404,
      '/repos/saip/awan': 404,
    });
    await expectLater(
      client.latestRelease(),
      throwsA(isA<ReleasesUnavailable>().having((ReleasesUnavailable e) => e.code, 'code', 'repo_not_found')),
    );
  });

  test('a real repository with no release says so', () async {
    final GithubReleases client = build(<String, int>{
      '/repos/saip/awan/releases/latest': 404,
      '/repos/saip/awan': 200,
    });
    await expectLater(
      client.latestRelease(),
      throwsA(isA<ReleasesUnavailable>().having((ReleasesUnavailable e) => e.code, 'code', 'no_release')),
    );
  });

  test('rate limiting is its own message', () async {
    final GithubReleases client = build(<String, int>{
      '/repos/saip/awan/releases/latest': 403,
    });
    await expectLater(
      client.latestRelease(),
      throwsA(isA<ReleasesUnavailable>().having((ReleasesUnavailable e) => e.code, 'code', 'rate_limited')),
    );
  });

  test('an empty repo string means no channel, not a broken build', () {
    final Dio dio = Dio();
    expect(GithubReleases(dio: dio, repo: '').isConfigured, isFalse);
    expect(GithubReleases(dio: dio, repo: 'OWNER/REPO').isConfigured, isFalse);
    expect(GithubReleases(dio: dio, repo: 'saip/awan').isConfigured, isTrue);
  });
}
