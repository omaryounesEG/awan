// Debug-only file logger used while bringing features up on a device.
//
// Dart `print` does not reach `logcat` on the emulators used here, so a probe
// that appends to the app cache dir and is read back with
// `adb shell run-as <pkg> cat cache/<name>.log` is the only reliable channel.
// Nothing in the shipped app imports this file.
//
// (Kept as `//` rather than `///` on purpose: a dangling library doc comment is
// a lint, and this file is a tool, not a library.)
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// TEMPORARY diagnostic sink (removed once Step 10 is verified).
///
/// `print` never reached logcat on this emulator, so the app's own cache dir is
/// the only channel that reports where a cold start stops.
Future<void> probe(String message) async {
  try {
    final Directory dir = await getApplicationCacheDirectory();
    await File('${dir.path}/awan_start.log')
        .writeAsString('$message\n', mode: FileMode.append, flush: true);
  } catch (error) {
    debugPrint('probe failed: $error');
  }
}
