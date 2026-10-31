import 'package:flutter_test/flutter_test.dart';

import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/updates/data/datasources/github_releases.dart';
import 'package:awan/features/updates/domain/entities/update_entities.dart';

/// The update card used to answer «هذا البناء بلا قناة تحديث» because the repo
/// path only existed as a `--dart-define` and the published builds were made
/// without it. The constant now has a default, and these tests keep it that way.
void main() {
  test('a build carries an update channel by default', () {
    expect(AppConstants.updateRepo, isNotEmpty);
    expect(AppConstants.updateRepo, contains('/'));
    expect(GithubReleases(repo: AppConstants.updateRepo).isConfigured, isTrue);
  });

  test('an empty repo is still recognised as no channel', () {
    expect(GithubReleases(repo: '').isConfigured, isFalse);
    expect(GithubReleases(repo: 'owner/repo').isConfigured, isTrue);
  });

  test('notConfigured is a status, not a failure', () {
    const UpdateCheck check = UpdateCheck(
      status: UpdateStatus.notConfigured,
      currentVersion: '1.0.0',
    );
    expect(check.status, UpdateStatus.notConfigured);
    expect(check.hasUpdate, isFalse);
  });
}
