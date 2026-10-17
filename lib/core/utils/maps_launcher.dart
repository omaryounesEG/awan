import 'package:url_launcher/url_launcher.dart';

/// Opens the native maps app on a mosque.
///
/// Used by the radar's cards and by the Elderly Mode button, which is why it
/// lives on its own: the elderly path must not depend on a map widget rendering
/// successfully.
///
/// The `geo:` intent is what makes Google Maps (or any installed maps app) open
/// *directly* on the pin, with the label the user just read on screen; the https
/// URL is the fallback for devices whose maps app does not register `geo:`.
class MapsLauncher {
  MapsLauncher._();

  /// Returns `true` when a maps app accepted the request.
  static Future<bool> navigate({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final Uri geo = Uri(
      scheme: 'geo',
      path: '$latitude,$longitude',
      queryParameters: <String, String>{
        'q': '$latitude,$longitude${label == null ? '' : '($label)'}',
      },
    );

    if (await _try(geo)) return true;

    final Uri web = Uri.https(
      'www.google.com',
      '/maps/dir/',
      <String, String>{
        'api': '1',
        'destination': '$latitude,$longitude',
      },
    );
    return _try(web);
  }

  static Future<bool> _try(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fall through to the next scheme.
    }
    return false;
  }
}
