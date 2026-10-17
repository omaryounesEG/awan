import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awan/core/error/failures.dart';
import 'package:awan/core/l10n/l10n.dart';
import 'package:awan/core/settings/app_settings.dart';
import 'package:awan/core/providers/core_providers.dart';
import 'package:awan/l10n/app_localizations.dart';

/// Small, dependency-free helpers used across the layers.

/// Localizations on any widget context.
extension L10nContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  MediaQueryData get media => MediaQuery.of(this);
}

/// Localizations + settings on a Riverpod ref (screens mostly use context).
extension L10nRefX on WidgetRef {
  AppSettings get settings => watch(settingsProvider);
  AppLocalizations get l10n => localizationsFor(read(settingsProvider).localeCode);
}

/// `Either` plumbing so the presentation layer stays flat and readable.
extension EitherX<L, R> on Either<L, R> {
  R? get valueOrNull => fold((L _) => null, (R r) => r);

  L? get failureOrNull => fold((L l) => l, (R _) => null);

  bool get isSuccess => isRight();
}

/// Unwraps an `Either` inside a Riverpod `FutureProvider`, turning a `Failure`
/// into a thrown `Failure` so `AsyncValue.error` carries it verbatim.
///
/// `L` is bounded by `Object` because Dart only allows throwing `Object`s.
Future<R> unwrapOrThrow<L extends Object, R>(Either<L, R> either) async =>
    either.fold((L failure) => throw failure, (R value) => value);

/// `Future<Either<..>>` → `Future<R>` for the presentation layer.
extension FutureEitherX<L extends Object, R> on Future<Either<L, R>> {
  Future<R> unwrap() async => (await this).fold(
        (L failure) => throw failure,
        (R value) => value,
      );
}

/// The `Failure` inside an `AsyncValue.error`, or a generic wrapper.
///
/// Riverpod carries whatever was thrown; the presentation layer only ever wants a
/// `Failure` so it can pick an ARB sentence.
Failure asFailure(Object error) => error is Failure
    ? error
    : ServerFailure(message: error.toString(), cause: error);

/// Human text for any failure, resolved against the ARB catalogue.
String failureText(AppLocalizations l10n, Failure failure) {
  if (failure is NetworkFailure) return l10n.noNetwork;
  if (failure is PermissionFailure) return l10n.permissionNeeded;
  if (failure is LocationFailureReason) return l10n.locationUnavailable;
  if (failure is UnsupportedFailure) return l10n.compassUnavailable;
  if (failure is PlacesKeyMissingFailure) return l10n.placesKeyMissing;
  if (failure is ParseFailure) return l10n.error;
  return l10n.error;
}
