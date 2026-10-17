// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appSettingsNotifierHash() =>
    r'0413247f8837827e06a5ae6f881b866310ce909b';

/// `@riverpod` (generator) notifier — the canonical Riverpod 2 pattern: no
/// manual `StateNotifierProvider` boilerplate, and `keepAlive` because UI
/// preferences must survive tab switches.
///
/// Copied from [AppSettingsNotifier].
@ProviderFor(AppSettingsNotifier)
final appSettingsNotifierProvider =
    NotifierProvider<AppSettingsNotifier, AppUiSettings>.internal(
  AppSettingsNotifier.new,
  name: r'appSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppSettingsNotifier = Notifier<AppUiSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
