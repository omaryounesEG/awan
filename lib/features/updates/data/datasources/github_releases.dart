import 'package:dio/dio.dart';

import 'package:awan/core/constants/app_constants.dart';

/// GitHub Releases, read directly.
///
/// One unauthenticated `GET` when the user taps "check", and nothing else ever
/// leaves the device. No Firebase, no store SDK, no analytics: the release is
/// the update channel. The endpoint is rate-limited per IP (60/hour) which is
/// far more than a manual button can spend.
class GithubReleases {
  GithubReleases({Dio? dio, required this.repo})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.updateApiBase,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 20),
                headers: <String, String>{
                  'Accept': 'application/vnd.github+json',
                  'User-Agent': 'Awan-Updater',
                },
                // A 404 is an answer ("no release published yet"), not an
                // exception the UI should dress up as a network failure.
                validateStatus: (int? code) => code != null && code < 500,
              ),
            );

  final Dio _dio;

  /// `owner/repo`, or empty when this build has no channel configured.
  final String repo;

  bool get isConfigured => repo.contains('/') && !repo.startsWith('OWNER');

  Future<Map<String, dynamic>> latestRelease() async {
    final Response<dynamic> res = await _dio.get<dynamic>('/repos/$repo/releases/latest');
    if (res.statusCode == 404) {
      // Two very different 404s share this status: a repository that does not
      // exist (or is private) and a repository that simply has no release yet.
      // Telling the user "no releases yet" when `owner/repo` is wrong sends
      // them looking in the wrong place, so ask which one it is.
      final Response<dynamic> probe = await _dio.get<dynamic>('/repos/$repo');
      throw ReleasesUnavailable(probe.statusCode == 404 ? 'repo_not_found' : 'no_release');
    }
    if (res.statusCode == 403 || res.statusCode == 429) {
      throw const ReleasesUnavailable('rate_limited');
    }
    if (res.statusCode != 200 || res.data is! Map<String, dynamic>) {
      throw ReleasesUnavailable('http_${res.statusCode}');
    }
    return res.data! as Map<String, dynamic>;
  }

  /// A published checksum file, if the release carries one.
  Future<String?> fetchTextAsset(String url) async {
    try {
      final Response<String> res = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      return res.statusCode == 200 ? res.data : null;
    } catch (_) {
      return null;
    }
  }
}

class ReleasesUnavailable implements Exception {
  const ReleasesUnavailable(this.code);
  final String code;

  @override
  String toString() => 'ReleasesUnavailable($code)';
}
