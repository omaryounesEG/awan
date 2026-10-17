import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/settings/presentation/screens/about_screen.dart';

/// The version printed inside the app is a claim the user can check against the
/// APK they installed. Keeping it as a constant is fine only if something stops
/// it drifting; that something is this test.
void main() {
  test('the version in About matches pubspec.yaml', () {
    final List<String> lines = File('pubspec.yaml').readAsLinesSync();
    final String declared = lines
        .firstWhere((String l) => l.startsWith('version:'))
        .split(':')[1]
        .trim();

    expect(appVersion, declared,
        reason: 'update `appVersion` in about_screen.dart when you bump '
            'pubspec.yaml — an app that lies about its own version is a bug');
  });
}
