/// App-wide immutable constants: identities, endpoints, cache windows.
///
/// Everything a layer needs to know about "where data comes from" lives here so
/// the data layer holds no magic strings.
class AppConstants {
  AppConstants._();

  static const String appNameAr = 'أَوَان';
  static const String appNameEn = 'Awan';
  static const String packageId = 'com.saip.awan';

  /// The version the app reports, in one place: `pubspec.yaml`'s version line.
  /// `test/about_version_test.dart` keeps the two from drifting apart.
  static const String appVersion = '1.24.0+29';

  /// `owner/repo` of the project the manual update button asks for a release.
  ///
  /// Set at build time — `--dart-define=AWAN_UPDATE_REPO=owner/repo` — because a
  /// channel baked into the code is a channel nobody can move. Empty means this
  /// build has no update channel, and the button says so instead of guessing.
  static const String updateRepo = String.fromEnvironment('AWAN_UPDATE_REPO');

  /// Where releases are read from. GitHub by default; overridable so a build
  /// can be pointed at a mirror — or at a local server, which is how the delta
  /// updater is exercised end to end without publishing anything.
  static const String updateApiBase = String.fromEnvironment(
    'AWAN_UPDATE_API',
    defaultValue: 'https://api.github.com',
  );

  // ---------------------------------------------------------------- assets
  static const String quranAsset = 'assets/data/quran_uthmani.json';

  /// الكسائي's «مشتبهات القرآن», parsed into the verses the graph cites.
  static const String kisaiLayerAsset = 'assets/data/kisai_mutashabihat.json';
  static const String addonsManifestAsset = 'assets/addons/addons_manifest.json';
  static const String bundledTafsirAsset = 'assets/addons/tafsir_muyassar.json';

  /// Page / juz / hizb / sajda of every ayah — what lets the reader page like a
  /// printed Mushaf and remember a *page*. Built by `tools/fetch_quran_index.py`.
  static const String quranIndexAsset = 'assets/data/quran_index.json';

  /// The tafsir edition bundled with the app (تفسير الميسّر, King Fahd Complex).
  static const int tafsirMuyassarId = 16;

  /// Where a downloaded add-on edition is expected on disk.
  static String tafsirAddonAsset(int id) => 'assets/addons/tafsir_$id.json';

  // ------------------------------------------------------------------ data
  static const String isarDbName = 'awan';
  static const int isarSchemaVersion = 1;

  static const String prefsKeySettings = 'awan.settings.v1';

  // ------------------------------------------------------------- endpoints
  static const String aladhanBase = 'https://api.aladhan.com/v1';
  static const String quranApiBase = 'https://api.quran.com/api/v4';
  static const String alquranCloudBase = 'https://api.alquran.cloud/v1';
  static const String googlePlacesBase =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const List<String> overpassEndpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];
  static const String nominatimBase = 'https://nominatim.openstreetmap.org';

  /// Supplied at build time, e.g.
  /// `flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=AIza...`.
  /// When empty the radar silently falls back to OpenStreetMap data + OSM tiles.
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Places REST key. One Google key usually covers both APIs, so it defaults to
  /// the Maps key above; override it when the two are different projects.
  static const String placesApiKey = String.fromEnvironment(
    'PLACES_API_KEY',
    defaultValue: googleMapsApiKey,
  );

  // ----------------------------------------------------------- mosque radar
  /// Search radius for "mosques near me", metres (Step 6 asks for 2 km).
  static const int mosqueRadiusMeters = 2000;

  /// Cached mosque payloads are reused for this long …
  static const int mosqueCacheTtlHours = 48;

  /// … as long as the previous search point is within this many metres of the
  /// new one (both numbers come from the Step 6 brief).
  static const int mosqueCacheRadiusMeters = 500;

  /// How many mosques the radar plots and lists.
  static const int radarTopMosques = 5;

  // ------------------------------------------------------------- qibla/Makkah
  /// The Kaaba, WGS-84 — the destination of every qibla bearing in the app.
  static const double kaabaLatitude = 21.4224779;
  static const double kaabaLongitude = 39.8251832;

  /// "Aligned with the qibla" window, degrees either side (Step 6 asks +/-2).
  static const double qiblaToleranceDegrees = 2.0;

  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  // ------------------------------------------------------------ behaviour
  /// Mosques are cached for 48h per geographic cell (battery + API billing).
  static const Duration mosqueCacheTtl = Duration(hours: 48);

  /// Prayer notifications are scheduled this far ahead, locally.
  static const int notificationDaysAhead = 30;

  /// Lead time of the pre-prayer reminder when the reader never picked one.
  static const int defaultPreAdhanMinutes = 20;

  /// The lead times the settings screen offers.
  static const List<int> preAdhanChoices = <int>[5, 10, 15, 20, 30];

  /// The whole-week background verification of the offline angles.
  static const String weeklySyncTask = 'awan.prayer.sync';
  static const Duration weeklySyncFrequency = Duration(days: 7);

  /// A user-visible mismatch threshold (minutes) between adhan_dart and Aladhan.
  static const int syncMismatchThresholdMinutes = 2;

  /// Walking speed used for the radar ETA (m/s).
  static const double walkingSpeedMps = 1.35;

  /// Default values used when the user has not chosen a location yet.
  static const double defaultLatitude = 30.0444; // Cairo
  static const double defaultLongitude = 31.2357;
  static const String defaultCityAr = 'القاهرة';
  static const String defaultCityEn = 'Cairo';

  static const int tasbihDefaultTarget = 33;

  // -------------------------------------------------------------- library
  /// Where the static book CDN lives.
  ///
  /// The library is *static files* — one `library_index.json` plus one
  /// `<book_id>.sqlite.zip` per book — so this is the only configuration the
  /// feature needs, and any static host (GitHub Releases, S3, R2, nginx) is a
  /// valid answer. Overridable from the library screen for a self-hosted mirror;
  /// `--dart-define=AWAN_LIBRARY_CDN=…` bakes a default into a build.
  static const String libraryCdnDefaultUrl = String.fromEnvironment(
    'AWAN_LIBRARY_CDN',
    defaultValue: 'https://cdn.saibrx.app/awan/library',
  );

  /// Below this, a re-sync is a waste of a request.
  static const Duration libraryIndexTtl = Duration(hours: 12);

  /// Chunks the reader asks for per page (ListView.builder window).
  static const int libraryReaderPageSize = 30;

  // -------------------------------------------------------- knowledge graph
  /// The Mutashabihat corpus: 1,298 ayat, 3,705 edges, shipped as an asset and
  /// seeded into Isar on first open. Generated by the data-engineering step;
  /// the app only reads it.
  static const String mutashabihatAssetPath =
      'assets/data/mutashabihat_data_normalized.json';

  /// Which ayah the graph opens on when nothing else is asked for.
  ///
  /// Al-Baqarah 2:2 — the first node of the corpus, so a reader who taps the
  /// card always lands on a graph that has something in it.
  // No default ayah: the graph opens on whatever the reader last read (see
  // `quranLastReadAbsoluteIdProvider`) and asks for one otherwise, because a
  // fixed 2:2 made the whole section look stuck on a single verse.

  /// `graphview`'s layout is iterative; past this the graph looks the same and
  /// the first frame costs more.
  static const int mutashabihatLayoutIterations = 300;
}
