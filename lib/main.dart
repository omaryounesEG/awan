import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awan/app.dart';
import 'package:awan/core/constants/app_typography.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/core/services/isar_service.dart';

/// Cold start, in the order that keeps the first frame fast:
///
/// 1. bindings + platform channels,
/// 2. `SharedPreferences` (a plain JSON snapshot — needed for theme, language
///    and elderly mode, so it must exist *before* the first build),
/// 3. Isar (the offline store) — local, no network, ~30 ms for an empty DB,
/// 4. warm the font cache so the first paint already uses IBM Plex Sans Arabic,
/// 5. `runApp` inside a `ProviderScope` with both singletons injected.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final IsarService isar = await IsarService.open();
  await AppTypography.preload();
  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        isarServiceProvider.overrideWithValue(isar),
      ],
      child: const AwanApp(),
    ),
  );
}
