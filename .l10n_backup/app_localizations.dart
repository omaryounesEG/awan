import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Awan'**
  String get appName;

  /// No description provided for @appFullName.
  ///
  /// In en, this message translates to:
  /// **'Awan | Prayer Times & Quran'**
  String get appFullName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Calmness for the soul'**
  String get tagline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsShort;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @meter.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get meter;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingNoon.
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you'**
  String get greetingNoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get nextPrayer;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @prayerIn.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String prayerIn(String time);

  /// No description provided for @prayerNow.
  ///
  /// In en, this message translates to:
  /// **'It is prayer time'**
  String get prayerNow;

  /// No description provided for @todayPrayers.
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayers'**
  String get todayPrayers;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @adhan.
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get adhan;

  /// No description provided for @prayerTimetable.
  ///
  /// In en, this message translates to:
  /// **'Prayer timetable'**
  String get prayerTimetable;

  /// No description provided for @monthlyTimetable.
  ///
  /// In en, this message translates to:
  /// **'Monthly timetable'**
  String get monthlyTimetable;

  /// No description provided for @qibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qibla;

  /// No description provided for @qiblaDirection.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get qiblaDirection;

  /// No description provided for @qiblaDegrees.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° from North'**
  String qiblaDegrees(String degrees);

  /// No description provided for @hijriDate.
  ///
  /// In en, this message translates to:
  /// **'Hijri date'**
  String get hijriDate;

  /// No description provided for @gregorianDate.
  ///
  /// In en, this message translates to:
  /// **'Gregorian date'**
  String get gregorianDate;

  /// No description provided for @hijriOffset.
  ///
  /// In en, this message translates to:
  /// **'Hijri adjustment (days)'**
  String get hijriOffset;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (device GPS)'**
  String get locationAuto;

  /// No description provided for @locationManual.
  ///
  /// In en, this message translates to:
  /// **'Manual (choose a city)'**
  String get locationManual;

  /// No description provided for @detectLocation.
  ///
  /// In en, this message translates to:
  /// **'Detect my location'**
  String get detectLocation;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @cityName.
  ///
  /// In en, this message translates to:
  /// **'City name'**
  String get cityName;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to calculate prayer times for your city.'**
  String get locationDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the device location. Pick a city manually.'**
  String get locationUnavailable;

  /// No description provided for @calculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get calculationMethod;

  /// No description provided for @madhab.
  ///
  /// In en, this message translates to:
  /// **'Asr madhab'**
  String get madhab;

  /// No description provided for @madhabShafi.
  ///
  /// In en, this message translates to:
  /// **'Shafi / Maliki / Hanbali'**
  String get madhabShafi;

  /// No description provided for @madhabHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get madhabHanafi;

  /// No description provided for @highLatitudeRule.
  ///
  /// In en, this message translates to:
  /// **'High latitude rule'**
  String get highLatitudeRule;

  /// No description provided for @highLatitudeMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle of the night'**
  String get highLatitudeMiddle;

  /// No description provided for @highLatitudeSeventh.
  ///
  /// In en, this message translates to:
  /// **'One seventh of the night'**
  String get highLatitudeSeventh;

  /// No description provided for @highLatitudeTwilight.
  ///
  /// In en, this message translates to:
  /// **'Angle based'**
  String get highLatitudeTwilight;

  /// No description provided for @prayerAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Manual adjustments (minutes)'**
  String get prayerAdjustments;

  /// No description provided for @methodMWL.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMWL;

  /// No description provided for @methodEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority'**
  String get methodEgyptian;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura (Makkah)'**
  String get methodUmmAlQura;

  /// No description provided for @methodKarachi.
  ///
  /// In en, this message translates to:
  /// **'University of Karachi'**
  String get methodKarachi;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In en, this message translates to:
  /// **'ISNA (North America)'**
  String get methodNorthAmerica;

  /// No description provided for @methodKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get methodKuwait;

  /// No description provided for @methodQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get methodQatar;

  /// No description provided for @methodDubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get methodDubai;

  /// No description provided for @methodTurkey.
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get methodTurkey;

  /// No description provided for @methodTehran.
  ///
  /// In en, this message translates to:
  /// **'Tehran'**
  String get methodTehran;

  /// No description provided for @methodSingapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get methodSingapore;

  /// No description provided for @methodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get methodOther;

  /// No description provided for @verifyOnline.
  ///
  /// In en, this message translates to:
  /// **'Verify angles online'**
  String get verifyOnline;

  /// No description provided for @verifyOk.
  ///
  /// In en, this message translates to:
  /// **'Offline calculation matches the reference'**
  String get verifyOk;

  /// No description provided for @verifyDiff.
  ///
  /// In en, this message translates to:
  /// **'Difference of {minutes} min vs. the reference — review the calculation method'**
  String verifyDiff(String minutes);

  /// No description provided for @lastVerified.
  ///
  /// In en, this message translates to:
  /// **'Last verified {date}'**
  String lastVerified(String date);

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// No description provided for @meccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// No description provided for @ayahCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String ayahCount(int count);

  /// No description provided for @searchQuran.
  ///
  /// In en, this message translates to:
  /// **'Search the Quran'**
  String get searchQuran;

  /// No description provided for @searchQuranHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word or part of a verse'**
  String get searchQuranHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmarkAdded;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @lastRead.
  ///
  /// In en, this message translates to:
  /// **'Last read'**
  String get lastRead;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @quranFont.
  ///
  /// In en, this message translates to:
  /// **'Quran script'**
  String get quranFont;

  /// No description provided for @scriptUthmani.
  ///
  /// In en, this message translates to:
  /// **'Uthmani (Amiri Quran)'**
  String get scriptUthmani;

  /// No description provided for @scriptScheherazade.
  ///
  /// In en, this message translates to:
  /// **'Scheherazade New'**
  String get scriptScheherazade;

  /// No description provided for @nightReadingMode.
  ///
  /// In en, this message translates to:
  /// **'Night reading mode'**
  String get nightReadingMode;

  /// No description provided for @tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// No description provided for @showTafsir.
  ///
  /// In en, this message translates to:
  /// **'Show tafsir'**
  String get showTafsir;

  /// No description provided for @tafsirUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No tafsir installed for this verse'**
  String get tafsirUnavailable;

  /// No description provided for @jumpToAyah.
  ///
  /// In en, this message translates to:
  /// **'Jump to ayah'**
  String get jumpToAyah;

  /// No description provided for @ayah.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayah;

  /// No description provided for @surah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surah;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get juz;

  /// No description provided for @copyAyah.
  ///
  /// In en, this message translates to:
  /// **'Copy ayah'**
  String get copyAyah;

  /// No description provided for @shareAyah.
  ///
  /// In en, this message translates to:
  /// **'Share ayah'**
  String get shareAyah;

  /// No description provided for @tafsirPackages.
  ///
  /// In en, this message translates to:
  /// **'Tafsir packages'**
  String get tafsirPackages;

  /// No description provided for @tafsirPackagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Downloaded once and kept offline on your device.'**
  String get tafsirPackagesDesc;

  /// No description provided for @bundledPackage.
  ///
  /// In en, this message translates to:
  /// **'Bundled'**
  String get bundledPackage;

  /// No description provided for @installPackage.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installPackage;

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get installing;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get uninstall;

  /// No description provided for @packageSize.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String packageSize(String size);

  /// No description provided for @mosqueRadar.
  ///
  /// In en, this message translates to:
  /// **'Mosque radar'**
  String get mosqueRadar;

  /// No description provided for @nearbyMosques.
  ///
  /// In en, this message translates to:
  /// **'Nearby mosques'**
  String get nearbyMosques;

  /// No description provided for @nearestMosques.
  ///
  /// In en, this message translates to:
  /// **'Nearest mosques'**
  String get nearestMosques;

  /// No description provided for @walkingTime.
  ///
  /// In en, this message translates to:
  /// **'Walking {time}'**
  String walkingTime(String time);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @mosque.
  ///
  /// In en, this message translates to:
  /// **'Mosque'**
  String get mosque;

  /// No description provided for @noMosquesFound.
  ///
  /// In en, this message translates to:
  /// **'No mosques found nearby'**
  String get noMosquesFound;

  /// No description provided for @placesKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Add a Google Places key to use Google results. OpenStreetMap data is used meanwhile.'**
  String get placesKeyMissing;

  /// No description provided for @cacheHint.
  ///
  /// In en, this message translates to:
  /// **'Results are cached for 48 hours to save data and battery'**
  String get cacheHint;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @maktabaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Al-Maktaba Al-Shamila'**
  String get maktabaSubtitle;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @myBooks.
  ///
  /// In en, this message translates to:
  /// **'My books'**
  String get myBooks;

  /// No description provided for @downloadBook.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadBook;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get downloadStarted;

  /// No description provided for @bookImported.
  ///
  /// In en, this message translates to:
  /// **'Book imported successfully'**
  String get bookImported;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get importFile;

  /// No description provided for @importUrl.
  ///
  /// In en, this message translates to:
  /// **'Import from a link'**
  String get importUrl;

  /// No description provided for @bookSearch.
  ///
  /// In en, this message translates to:
  /// **'Search for a book or an author'**
  String get bookSearch;

  /// No description provided for @noBooks.
  ///
  /// In en, this message translates to:
  /// **'No books yet. Download one from the catalog or import a file.'**
  String get noBooks;

  /// No description provided for @parserIsolate.
  ///
  /// In en, this message translates to:
  /// **'Parsing in the background so the interface stays smooth'**
  String get parserIsolate;

  /// No description provided for @librarySource.
  ///
  /// In en, this message translates to:
  /// **'Library source'**
  String get librarySource;

  /// No description provided for @sourceShamela.
  ///
  /// In en, this message translates to:
  /// **'Al-Maktaba Al-Shamila'**
  String get sourceShamela;

  /// No description provided for @sourceOpenIti.
  ///
  /// In en, this message translates to:
  /// **'OpenITI corpus'**
  String get sourceOpenIti;

  /// No description provided for @sourceLocal.
  ///
  /// In en, this message translates to:
  /// **'On-device files'**
  String get sourceLocal;

  /// No description provided for @readingProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get readingProgress;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @elderlyMode.
  ///
  /// In en, this message translates to:
  /// **'Elderly mode'**
  String get elderlyMode;

  /// No description provided for @elderlyModeDesc.
  ///
  /// In en, this message translates to:
  /// **'150% larger text, three large cards and no complex gestures.'**
  String get elderlyModeDesc;

  /// No description provided for @textScale.
  ///
  /// In en, this message translates to:
  /// **'Text scale'**
  String get textScale;

  /// No description provided for @simpleMode.
  ///
  /// In en, this message translates to:
  /// **'Simple mode'**
  String get simpleMode;

  /// No description provided for @moreFeatures.
  ///
  /// In en, this message translates to:
  /// **'More features'**
  String get moreFeatures;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @adhanNotifications.
  ///
  /// In en, this message translates to:
  /// **'Adhan notifications'**
  String get adhanNotifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is denied'**
  String get notificationsDenied;

  /// No description provided for @vibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get vibrate;

  /// No description provided for @playSound.
  ///
  /// In en, this message translates to:
  /// **'Play sound'**
  String get playSound;

  /// No description provided for @silentMode.
  ///
  /// In en, this message translates to:
  /// **'Auto silent mode'**
  String get silentMode;

  /// No description provided for @silentModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Mute the phone before the adhan and restore it afterwards (Android).'**
  String get silentModeDesc;

  /// No description provided for @silentModePermission.
  ///
  /// In en, this message translates to:
  /// **'Grant the Do Not Disturb access'**
  String get silentModePermission;

  /// No description provided for @muteBeforeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Mute {count} minutes before'**
  String muteBeforeMinutes(int count);

  /// No description provided for @unmuteAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Restore {count} minutes after'**
  String unmuteAfterMinutes(int count);

  /// No description provided for @fridaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Friday prayer'**
  String get fridaySchedule;

  /// No description provided for @fridayScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'Mute from 11:30 to 13:30 (customisable).'**
  String get fridayScheduleDesc;

  /// No description provided for @fridayStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get fridayStart;

  /// No description provided for @fridayEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get fridayEnd;

  /// No description provided for @iosSilentNotice.
  ///
  /// In en, this message translates to:
  /// **'iOS does not allow apps to mute the device. A reminder to enable Focus mode is sent instead.'**
  String get iosSilentNotice;

  /// No description provided for @backgroundTasks.
  ///
  /// In en, this message translates to:
  /// **'Background sync'**
  String get backgroundTasks;

  /// No description provided for @backgroundSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Prayer angles are verified once a week in the background, using no noticeable battery.'**
  String get backgroundSyncDesc;

  /// No description provided for @tasbih.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbih;

  /// No description provided for @tasbihCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get tasbihCount;

  /// No description provided for @tasbihTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get tasbihTarget;

  /// No description provided for @tasbihReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tasbihReset;

  /// No description provided for @tasbihSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get tasbihSaved;

  /// No description provided for @seasonGreeting.
  ///
  /// In en, this message translates to:
  /// **'May your worship be accepted'**
  String get seasonGreeting;

  /// No description provided for @addons.
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get addons;

  /// No description provided for @dataSources.
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get dataSources;

  /// No description provided for @dataSourcesDesc.
  ///
  /// In en, this message translates to:
  /// **'Prayer times: adhan_dart offline + Aladhan API for verification. Places: Google Places / OpenStreetMap. Quran text: Tanzil Uthmani via quran.com. Tafsir: King Saud University / quran.com.'**
  String get dataSourcesDesc;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your location, bookmarks and downloads stay on your device. No account, no tracking.'**
  String get privacyDesc;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licences'**
  String get licenses;

  /// No description provided for @aboutDesc.
  ///
  /// In en, this message translates to:
  /// **'An offline-first Islamic super app focused on calmness, speed and battery life.'**
  String get aboutDesc;

  /// No description provided for @elderlyModeOn.
  ///
  /// In en, this message translates to:
  /// **'Elderly mode is on'**
  String get elderlyModeOn;

  /// No description provided for @turnOffElderly.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOffElderly;

  /// No description provided for @permissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get permissionNeeded;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @noNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection — showing offline data'**
  String get noNetwork;

  /// No description provided for @cachedResults.
  ///
  /// In en, this message translates to:
  /// **'Cached results'**
  String get cachedResults;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updated(String time);

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @weekdaysShort.
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get weekdaysShort;

  /// No description provided for @zeroCount.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get zeroCount;

  /// Notification scheduling feedback
  ///
  /// In en, this message translates to:
  /// **'Scheduled {count} upcoming adhan notifications'**
  String adhanScheduled(int count);

  /// No description provided for @adhanCancelled.
  ///
  /// In en, this message translates to:
  /// **'All adhan notifications cancelled'**
  String get adhanCancelled;

  /// No description provided for @silentNeedsPolicy.
  ///
  /// In en, this message translates to:
  /// **'Auto-silent needs Do-Not-Disturb access'**
  String get silentNeedsPolicy;

  /// Notification scheduling feedback
  ///
  /// In en, this message translates to:
  /// **'Silence windows armed for {count} days'**
  String silentScheduled(int count);

  /// Number of adhan notifications currently held by the OS
  ///
  /// In en, this message translates to:
  /// **'{count} notifications armed'**
  String scheduledCount(int count);

  /// No description provided for @compassUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device has no compass (magnetometer), so the dial stays north-up. The bearing below is exact.'**
  String get compassUnavailable;

  /// No description provided for @qiblaAligned.
  ///
  /// In en, this message translates to:
  /// **'You are facing the qibla'**
  String get qiblaAligned;

  /// No description provided for @turnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn {degrees}° right'**
  String turnRight(int degrees);

  /// No description provided for @turnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn {degrees}° left'**
  String turnLeft(int degrees);

  /// No description provided for @toMakkah.
  ///
  /// In en, this message translates to:
  /// **'{km} km to Makkah'**
  String toMakkah(String km);

  /// No description provided for @compassCalibration.
  ///
  /// In en, this message translates to:
  /// **'Move the phone in a figure 8 to calibrate the compass'**
  String get compassCalibration;

  /// No description provided for @bearingFromTrueNorth.
  ///
  /// In en, this message translates to:
  /// **'Bearing measured from true north'**
  String get bearingFromTrueNorth;

  /// No description provided for @liveCompass.
  ///
  /// In en, this message translates to:
  /// **'Live compass'**
  String get liveCompass;

  /// No description provided for @declinationCorrection.
  ///
  /// In en, this message translates to:
  /// **'Magnetic declination correction: {degrees}°'**
  String declinationCorrection(String degrees);

  /// No description provided for @elderlyQibla.
  ///
  /// In en, this message translates to:
  /// **'Face this direction'**
  String get elderlyQibla;

  /// No description provided for @dataFromGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Places data'**
  String get dataFromGoogle;

  /// No description provided for @dataFromOsm.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap data'**
  String get dataFromOsm;

  /// No description provided for @dataFromCache.
  ///
  /// In en, this message translates to:
  /// **'From the local cache (under 48 h old)'**
  String get dataFromCache;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search radius {km} km'**
  String searchRadius(String km);

  /// No description provided for @nearestMosque.
  ///
  /// In en, this message translates to:
  /// **'Nearest mosque'**
  String get nearestMosque;

  /// No description provided for @navigateToNearest.
  ///
  /// In en, this message translates to:
  /// **'Navigate to the nearest mosque'**
  String get navigateToNearest;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @metersShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get metersShort;

  /// No description provided for @navigateShort.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get navigateShort;

  /// No description provided for @timeSection.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeSection;

  /// No description provided for @daylightSaving.
  ///
  /// In en, this message translates to:
  /// **'Summer / winter time'**
  String get daylightSaving;

  /// No description provided for @dstAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (device)'**
  String get dstAuto;

  /// No description provided for @dstAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Trust the device clock — correct for almost every country.'**
  String get dstAutoDesc;

  /// No description provided for @dstPlusOne.
  ///
  /// In en, this message translates to:
  /// **'Summer time (+1)'**
  String get dstPlusOne;

  /// No description provided for @dstPlusOneDesc.
  ///
  /// In en, this message translates to:
  /// **'Every time and reminder moves one hour earlier.'**
  String get dstPlusOneDesc;

  /// No description provided for @dstMinusOne.
  ///
  /// In en, this message translates to:
  /// **'Winter time (−1)'**
  String get dstMinusOne;

  /// No description provided for @dstMinusOneDesc.
  ///
  /// In en, this message translates to:
  /// **'Every time and reminder moves one hour later.'**
  String get dstMinusOneDesc;

  /// No description provided for @dstDeviceFixed.
  ///
  /// In en, this message translates to:
  /// **'Your device keeps one offset all year'**
  String get dstDeviceFixed;

  /// No description provided for @dstDeviceOnSummer.
  ///
  /// In en, this message translates to:
  /// **'Your device is on summer time'**
  String get dstDeviceOnSummer;

  /// No description provided for @dstDeviceStandard.
  ///
  /// In en, this message translates to:
  /// **'Your device is on winter time'**
  String get dstDeviceStandard;

  /// No description provided for @dstNote.
  ///
  /// In en, this message translates to:
  /// **'For countries that observe summer and winter time: if your device does not apply your country\'s rule (or ships an outdated one), set it here. The correction moves both the displayed time and the adhan alarm so they can never disagree, and it never touches the astronomical calculation.'**
  String get dstNote;

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'The Holy Quran'**
  String get quranTitle;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @surahIndex.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahIndex;

  /// No description provided for @stopMarker.
  ///
  /// In en, this message translates to:
  /// **'Stop marker'**
  String get stopMarker;

  /// No description provided for @stopMarkerSet.
  ///
  /// In en, this message translates to:
  /// **'Stop marker saved'**
  String get stopMarkerSet;

  /// No description provided for @stopMarkerCleared.
  ///
  /// In en, this message translates to:
  /// **'Stop marker cleared'**
  String get stopMarkerCleared;

  /// No description provided for @noStopMarker.
  ///
  /// In en, this message translates to:
  /// **'No stop marker yet — tap the bookmark icon while reading.'**
  String get noStopMarker;

  /// No description provided for @goToStopMarker.
  ///
  /// In en, this message translates to:
  /// **'Go there'**
  String get goToStopMarker;

  /// No description provided for @setStopHere.
  ///
  /// In en, this message translates to:
  /// **'Set the stop marker here'**
  String get setStopHere;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @searchOffline.
  ///
  /// In en, this message translates to:
  /// **'Search works without internet'**
  String get searchOffline;

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved verses'**
  String get bookmarksTitle;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get noBookmarks;

  /// No description provided for @readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readingSettings;

  /// No description provided for @ayahFontSize.
  ///
  /// In en, this message translates to:
  /// **'Ayah size'**
  String get ayahFontSize;

  /// No description provided for @tafsirFontSize.
  ///
  /// In en, this message translates to:
  /// **'Tafsir size'**
  String get tafsirFontSize;

  /// No description provided for @screenColour.
  ///
  /// In en, this message translates to:
  /// **'Screen colour'**
  String get screenColour;

  /// No description provided for @palettePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get palettePaper;

  /// No description provided for @paletteSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get paletteSepia;

  /// No description provided for @paletteDark.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get paletteDark;

  /// No description provided for @paletteOled.
  ///
  /// In en, this message translates to:
  /// **'Pure black'**
  String get paletteOled;

  /// No description provided for @readerMode.
  ///
  /// In en, this message translates to:
  /// **'Reading mode'**
  String get readerMode;

  /// No description provided for @modePages.
  ///
  /// In en, this message translates to:
  /// **'Mushaf pages'**
  String get modePages;

  /// No description provided for @modeSurah.
  ///
  /// In en, this message translates to:
  /// **'Continuous surah'**
  String get modeSurah;

  /// No description provided for @makki.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get makki;

  /// No description provided for @madani.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get madani;

  /// No description provided for @ayahWord.
  ///
  /// In en, this message translates to:
  /// **'verse'**
  String get ayahWord;

  /// No description provided for @sajdaAyah.
  ///
  /// In en, this message translates to:
  /// **'Prostration verse'**
  String get sajdaAyah;

  /// No description provided for @prePrayerReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder before prayer'**
  String get prePrayerReminder;

  /// No description provided for @prePrayerHint.
  ///
  /// In en, this message translates to:
  /// **'An hourglass appears before the adhan and leaves with a tap — or by itself when the adhan arrives'**
  String get prePrayerHint;

  /// No description provided for @prePrayerLead.
  ///
  /// In en, this message translates to:
  /// **'Lead time'**
  String get prePrayerLead;

  /// No description provided for @prePrayerSound.
  ///
  /// In en, this message translates to:
  /// **'Soft chime'**
  String get prePrayerSound;

  /// No description provided for @prePrayerSoundHint.
  ///
  /// In en, this message translates to:
  /// **'A short ring with the reminder instead of silence'**
  String get prePrayerSoundHint;

  /// No description provided for @reminderSoonOne.
  ///
  /// In en, this message translates to:
  /// **'1 minute to {prayer}'**
  String reminderSoonOne(Object prayer);

  /// No description provided for @reminderSoonTwo.
  ///
  /// In en, this message translates to:
  /// **'2 minutes to {prayer}'**
  String reminderSoonTwo(Object prayer);

  /// No description provided for @reminderSoonFew.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes to {prayer}'**
  String reminderSoonFew(Object minutes, Object prayer);

  /// No description provided for @reminderSoonMany.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes to {prayer}'**
  String reminderSoonMany(Object minutes, Object prayer);

  /// Pre-prayer hourglass subtitle
  ///
  /// In en, this message translates to:
  /// **'Get ready for {prayer}'**
  String reminderPrepare(String prayer);

  /// Library feature title
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arabic books, readable offline'**
  String get librarySubtitle;

  /// No description provided for @libraryDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get libraryDiscover;

  /// No description provided for @libraryShelf.
  ///
  /// In en, this message translates to:
  /// **'My shelf'**
  String get libraryShelf;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title or author'**
  String get librarySearchHint;

  /// No description provided for @libraryAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get libraryAllCategories;

  /// No description provided for @librarySync.
  ///
  /// In en, this message translates to:
  /// **'Refresh index'**
  String get librarySync;

  /// No description provided for @librarySyncing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing the index…'**
  String get librarySyncing;

  /// No description provided for @librarySynced.
  ///
  /// In en, this message translates to:
  /// **'Index up to date'**
  String get librarySynced;

  /// No description provided for @librarySyncedDetail.
  ///
  /// In en, this message translates to:
  /// **'{added} added · {total} total'**
  String librarySyncedDetail(int added, int total);

  /// No description provided for @librarySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the index'**
  String get librarySyncFailed;

  /// No description provided for @libraryOfflineCached.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing the saved copy'**
  String get libraryOfflineCached;

  /// No description provided for @libraryIndexEmpty.
  ///
  /// In en, this message translates to:
  /// **'The index is empty'**
  String get libraryIndexEmpty;

  /// No description provided for @libraryIndexEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Refresh the index to fetch the catalogue, then download what you want to read.'**
  String get libraryIndexEmptyHint;

  /// No description provided for @libraryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get libraryNoResults;

  /// No description provided for @libraryShelfEmpty.
  ///
  /// In en, this message translates to:
  /// **'No downloaded books yet'**
  String get libraryShelfEmpty;

  /// No description provided for @libraryShelfEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Downloaded books read fully offline.'**
  String get libraryShelfEmptyHint;

  /// No description provided for @libraryInstall.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get libraryInstall;

  /// No description provided for @libraryInstalling.
  ///
  /// In en, this message translates to:
  /// **'Downloading · {percent}%'**
  String libraryInstalling(int percent);

  /// No description provided for @libraryUnpacking.
  ///
  /// In en, this message translates to:
  /// **'Preparing · {percent}%'**
  String libraryUnpacking(int percent);

  /// No description provided for @libraryInstalled.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get libraryInstalled;

  /// No description provided for @libraryRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get libraryRead;

  /// No description provided for @libraryContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get libraryContinue;

  /// No description provided for @libraryRemove.
  ///
  /// In en, this message translates to:
  /// **'Delete the downloaded copy'**
  String get libraryRemove;

  /// No description provided for @libraryRemoveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}” from this device?'**
  String libraryRemoveQuestion(String title);

  /// No description provided for @libraryRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'The book stays in the catalogue and can be downloaded again.'**
  String get libraryRemoveHint;

  /// No description provided for @libraryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get libraryCancel;

  /// No description provided for @libraryRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get libraryRetry;

  /// No description provided for @librarySourceHint.
  ///
  /// In en, this message translates to:
  /// **'Index server address (https://…)'**
  String get librarySourceHint;

  /// No description provided for @librarySourceSaved.
  ///
  /// In en, this message translates to:
  /// **'Source saved'**
  String get librarySourceSaved;

  /// No description provided for @librarySourceInvalid.
  ///
  /// In en, this message translates to:
  /// **'That address is not valid'**
  String get librarySourceInvalid;

  /// No description provided for @libraryCancelInstall.
  ///
  /// In en, this message translates to:
  /// **'Stop the download'**
  String get libraryCancelInstall;

  /// No description provided for @libraryLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last refresh: {when}'**
  String libraryLastSync(String when);

  /// No description provided for @libraryNever.
  ///
  /// In en, this message translates to:
  /// **'Never refreshed'**
  String get libraryNever;

  /// No description provided for @libraryBooksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} books'**
  String libraryBooksCount(int count);

  /// No description provided for @libraryChaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sections'**
  String libraryChaptersCount(int count);

  /// No description provided for @librarySizeKb.
  ///
  /// In en, this message translates to:
  /// **'{kb} KB'**
  String librarySizeKb(int kb);

  /// No description provided for @libraryAuthorDied.
  ///
  /// In en, this message translates to:
  /// **'d. {year} AH'**
  String libraryAuthorDied(int year);

  /// No description provided for @libraryCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get libraryCategoryLabel;

  /// No description provided for @readerTitle.
  ///
  /// In en, this message translates to:
  /// **'Library reader'**
  String get readerTitle;

  /// No description provided for @readerFontSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get readerFontSize;

  /// No description provided for @readerNight.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get readerNight;

  /// No description provided for @readerChapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get readerChapterLabel;

  /// No description provided for @readerPageLabel.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String readerPageLabel(String page);

  /// No description provided for @readerBackToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to the first page'**
  String get readerBackToTop;

  /// No description provided for @libraryShortcutEmpty.
  ///
  /// In en, this message translates to:
  /// **'Download books to read offline'**
  String get libraryShortcutEmpty;

  /// No description provided for @libraryShortcutShelf.
  ///
  /// In en, this message translates to:
  /// **'{count} books on this device'**
  String libraryShortcutShelf(int count);

  /// No description provided for @libraryShortcutLastRead.
  ///
  /// In en, this message translates to:
  /// **'Last read: {title}'**
  String libraryShortcutLastRead(String title);

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
