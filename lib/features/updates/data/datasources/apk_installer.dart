import 'package:flutter/services.dart';

/// The thin line between "a file exists" and "Android is installing it".
///
/// Kept native (see `ApkInstaller.kt`) because launching an installer needs a
/// FileProvider URI and the user's "install unknown apps" consent — neither is
/// something a pure-Dart package should be trusted to fake.
class ApkInstallerBridge {
  const ApkInstallerBridge();

  static const MethodChannel _channel = MethodChannel('com.awan.app/updater');

  Future<bool> canInstall() async {
    try {
      return await _channel.invokeMethod<bool>('canInstall') ?? false;
    } on PlatformException {
      // Unknown/unavailable means "do not assume permission".
      return false;
    }
  }

  /// Absolute path of the APK this process is running from.
  ///
  /// A delta patch is only valid against those exact bytes; anything else is a
  /// different build and must be rejected rather than half-applied.
  Future<String?> installedApkPath() async {
    try {
      return await _channel.invokeMethod<String>('installedApkPath');
    } on PlatformException {
      return null;
    }
  }

  /// The device's primary ABI (`arm64-v8a`, `armeabi-v7a`, ...).
  ///
  /// Null on any host without the channel — the picker then keeps its old
  /// default rather than guessing wrong.
  Future<String?> primaryAbi() async {
    try {
      final String? abi = await _channel.invokeMethod<String>('primaryAbi');
      return (abi == null || abi.isEmpty) ? null : abi;
    } catch (_) {
      return null;
    }
  }

  Future<void> install(String path) =>
      _channel.invokeMethod<void>('install', <String, dynamic>{'path': path});

  Future<void> openInstallSettings() =>
      _channel.invokeMethod<void>('openInstallSettings');
}
