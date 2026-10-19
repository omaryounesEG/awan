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
  /// **'Everything below is bundled with the app; its origin and licence are stated — nothing is fetched quietly.'**
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

  /// No description provided for @adhanAlertPerPrayer.
  ///
  /// In en, this message translates to:
  /// **'Each adhan separately'**
  String get adhanAlertPerPrayer;

  /// No description provided for @adhanAlertHint.
  ///
  /// In en, this message translates to:
  /// **'Per adhan: notification only, with vibration, or with vibration and the tone'**
  String get adhanAlertHint;

  /// No description provided for @adhanAlertQuiet.
  ///
  /// In en, this message translates to:
  /// **'Notification only'**
  String get adhanAlertQuiet;

  /// No description provided for @adhanAlertVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get adhanAlertVibrate;

  /// No description provided for @adhanAlertTone.
  ///
  /// In en, this message translates to:
  /// **'Vibration + tone'**
  String get adhanAlertTone;

  /// No description provided for @silentStartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Silence'**
  String get silentStartsLabel;

  /// No description provided for @silentLastsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lasts'**
  String get silentLastsLabel;

  /// No description provided for @silentStartsAtAdhan.
  ///
  /// In en, this message translates to:
  /// **'At the adhan'**
  String get silentStartsAtAdhan;

  /// No description provided for @silentStartsAfter.
  ///
  /// In en, this message translates to:
  /// **'After {count} min'**
  String silentStartsAfter(int count);

  /// No description provided for @silentLastsFor.
  ///
  /// In en, this message translates to:
  /// **'For {count} min'**
  String silentLastsFor(int count);

  /// No description provided for @silentSaved.
  ///
  /// In en, this message translates to:
  /// **'Silence windows saved'**
  String get silentSaved;

  /// No description provided for @lockScreenCountdown.
  ///
  /// In en, this message translates to:
  /// **'With the pre-prayer reminder on, a live countdown appears on the lock screen and keeps running after it locks.'**
  String get lockScreenCountdown;

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

  /// No description provided for @graphTitle.
  ///
  /// In en, this message translates to:
  /// **'Mutashabihat'**
  String get graphTitle;

  /// No description provided for @graphNodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah} · Ayah {ayah}'**
  String graphNodeLabel(String surah, String ayah);

  /// No description provided for @graphNodeNamedLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} · Ayah {ayah}'**
  String graphNodeNamedLabel(String name, String ayah);

  /// No description provided for @graphRuleLabel.
  ///
  /// In en, this message translates to:
  /// **'The rule'**
  String get graphRuleLabel;

  /// No description provided for @graphRuleHint.
  ///
  /// In en, this message translates to:
  /// **'What the two ayat share'**
  String get graphRuleHint;

  /// No description provided for @graphPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the graph for the first time…'**
  String get graphPreparing;

  /// No description provided for @graphEmptyNode.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded for this ayah'**
  String get graphEmptyNode;

  /// No description provided for @graphSeedFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the Mutashabihat data'**
  String get graphSeedFailed;

  /// No description provided for @graphTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a node to read the ayah and the similarity rule'**
  String get graphTapHint;

  /// No description provided for @graphPickAyah.
  ///
  /// In en, this message translates to:
  /// **'Choose an ayah'**
  String get graphPickAyah;

  /// No description provided for @graphLevelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get graphLevelAll;

  /// No description provided for @graphLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Ordered by match strength — pick how many verses to show'**
  String get graphLevelHint;

  /// No description provided for @graphShownOf.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String graphShownOf(String shown, String total);

  /// No description provided for @quranShowMutashabihat.
  ///
  /// In en, this message translates to:
  /// **'Show similar verses'**
  String get quranShowMutashabihat;

  /// No description provided for @quranShowMutashabihatOn.
  ///
  /// In en, this message translates to:
  /// **'Similar verses shown — tap any tinted verse to open its relations'**
  String get quranShowMutashabihatOn;

  /// No description provided for @graphSourceTag.
  ///
  /// In en, this message translates to:
  /// **'The open ayah'**
  String get graphSourceTag;

  /// No description provided for @graphTargetTag.
  ///
  /// In en, this message translates to:
  /// **'Similar ayah'**
  String get graphTargetTag;

  /// No description provided for @graphTargetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} similar ayat'**
  String graphTargetCount(int count);

  /// No description provided for @graphOpenTarget.
  ///
  /// In en, this message translates to:
  /// **'This ayah\'s matches'**
  String get graphOpenTarget;

  /// No description provided for @graphShortcutEmpty.
  ///
  /// In en, this message translates to:
  /// **'An interactive map of similar ayat'**
  String get graphShortcutEmpty;

  /// No description provided for @graphShortcutReady.
  ///
  /// In en, this message translates to:
  /// **'{nodes} ayat · {edges} similarity links'**
  String graphShortcutReady(int nodes, int edges);

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @kisaiLayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Al-Kisa\'i\'s similarities'**
  String get kisaiLayerTitle;

  /// No description provided for @kisaiLayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{similar} verses with a counterpart, and {unique} the book states have none — «مشتبهات القرآن» by al-Kisa\'i (d. 189 AH)'**
  String kisaiLayerSubtitle(String similar, String unique);

  /// No description provided for @kisaiSimilarTab.
  ///
  /// In en, this message translates to:
  /// **'With a counterpart ({count})'**
  String kisaiSimilarTab(String count);

  /// No description provided for @kisaiUniqueTab.
  ///
  /// In en, this message translates to:
  /// **'Without one ({count})'**
  String kisaiUniqueTab(String count);

  /// No description provided for @kisaiUniqueHint.
  ///
  /// In en, this message translates to:
  /// **'Verses the book states have no similar passage anywhere in the Quran — the graph drops links that touch them.'**
  String get kisaiUniqueHint;

  /// No description provided for @kisaiFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Search by surah name or the book\'s wording'**
  String get kisaiFilterHint;

  /// No description provided for @kisaiNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get kisaiNoMatch;

  /// No description provided for @ayahSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a verse'**
  String get ayahSearchTitle;

  /// No description provided for @ayahSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Words from the verse, or its number (2:255)'**
  String get ayahSearchHint;

  /// No description provided for @ayahSearchExamples.
  ///
  /// In en, this message translates to:
  /// **'«لعلكم تتقون» · «2:255» · «البقرة 255»'**
  String get ayahSearchExamples;

  /// No description provided for @ayahSearchExampleWords.
  ///
  /// In en, this message translates to:
  /// **'لعلكم تتقون'**
  String get ayahSearchExampleWords;

  /// No description provided for @ayahSearchExampleReference.
  ///
  /// In en, this message translates to:
  /// **'2:255'**
  String get ayahSearchExampleReference;

  /// No description provided for @ayahSearchExampleNamed.
  ///
  /// In en, this message translates to:
  /// **'البقرة 255'**
  String get ayahSearchExampleNamed;

  /// No description provided for @ayahSearchGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to {surah} {ayah}'**
  String ayahSearchGoTo(String surah, String ayah);

  /// No description provided for @ayahSearchBySurah.
  ///
  /// In en, this message translates to:
  /// **'Pick surah and verse instead'**
  String get ayahSearchBySurah;

  /// No description provided for @lockScreenAllDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock-screen card, all day'**
  String get lockScreenAllDayLabel;

  /// No description provided for @lockScreenAllDayHint.
  ///
  /// In en, this message translates to:
  /// **'The next prayer and its live countdown sit on your lock screen from Fajr to Isha — silent, and not swipeable.'**
  String get lockScreenAllDayHint;

  /// No description provided for @prayerClockTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer clock'**
  String get prayerClockTitle;

  /// No description provided for @prayerClockHint.
  ///
  /// In en, this message translates to:
  /// **'Full screen: the clock, the time left to the next prayer, its name, and the hijri date.'**
  String get prayerClockHint;

  /// No description provided for @clockFaceSegment.
  ///
  /// In en, this message translates to:
  /// **'Segments'**
  String get clockFaceSegment;

  /// No description provided for @clockFaceWhite.
  ///
  /// In en, this message translates to:
  /// **'Glowing white'**
  String get clockFaceWhite;

  /// No description provided for @clockFaceRed.
  ///
  /// In en, this message translates to:
  /// **'Glowing red'**
  String get clockFaceRed;

  /// No description provided for @clockFaceGreen.
  ///
  /// In en, this message translates to:
  /// **'Glowing green'**
  String get clockFaceGreen;

  /// No description provided for @clockNight.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get clockNight;

  /// No description provided for @openPrayerClock.
  ///
  /// In en, this message translates to:
  /// **'Open the prayer clock'**
  String get openPrayerClock;

  /// No description provided for @clockOnLock.
  ///
  /// In en, this message translates to:
  /// **'Show the prayer clock on the lock screen'**
  String get clockOnLock;

  /// No description provided for @clockOnLockHint.
  ///
  /// In en, this message translates to:
  /// **'Comes up full screen over the PIN screen whenever you light the screen. Needs the “display over other apps” permission, and the app’s ongoing notification must stay on.'**
  String get clockOnLockHint;

  /// No description provided for @clockOverlayNeeded.
  ///
  /// In en, this message translates to:
  /// **'The “display over other apps” permission is not granted yet — open settings, allow it, then try again.'**
  String get clockOverlayNeeded;

  /// No description provided for @clockOverlayGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant the permission'**
  String get clockOverlayGrant;

  /// No description provided for @clockShowNow.
  ///
  /// In en, this message translates to:
  /// **'Show it now'**
  String get clockShowNow;

  /// No description provided for @readerContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get readerContents;

  /// No description provided for @readerContentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This book has no headings.'**
  String get readerContentsEmpty;

  /// No description provided for @readerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search in book'**
  String get readerSearch;

  /// No description provided for @readerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word or phrase…'**
  String get readerSearchHint;

  /// No description provided for @readerSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matches in this book'**
  String get readerSearchEmpty;

  /// No description provided for @readerSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type at least two letters'**
  String get readerSearchPrompt;

  /// No description provided for @readerNightMode.
  ///
  /// In en, this message translates to:
  /// **'Night reading'**
  String get readerNightMode;

  /// No description provided for @adhanSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan sound'**
  String get adhanSoundTitle;

  /// No description provided for @adhanSoundHint.
  ///
  /// In en, this message translates to:
  /// **'The clip that rings at prayer time — audition it before choosing.'**
  String get adhanSoundHint;

  /// No description provided for @preAdhanSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get preAdhanSoundTitle;

  /// No description provided for @preAdhanSoundHint.
  ///
  /// In en, this message translates to:
  /// **'The clip for the reminder twenty minutes before the adhan.'**
  String get preAdhanSoundHint;

  /// No description provided for @soundSystem.
  ///
  /// In en, this message translates to:
  /// **'System — the phone\'s alarm tone'**
  String get soundSystem;

  /// No description provided for @soundSilent.
  ///
  /// In en, this message translates to:
  /// **'No sound'**
  String get soundSilent;

  /// No description provided for @soundTakbir.
  ///
  /// In en, this message translates to:
  /// **'Alert 1'**
  String get soundTakbir;

  /// No description provided for @soundCall.
  ///
  /// In en, this message translates to:
  /// **'Alert 2'**
  String get soundCall;

  /// No description provided for @soundAdhan.
  ///
  /// In en, this message translates to:
  /// **'Alert 3'**
  String get soundAdhan;

  /// No description provided for @soundPreview.
  ///
  /// In en, this message translates to:
  /// **'Audition'**
  String get soundPreview;

  /// No description provided for @soundStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get soundStop;

  /// No description provided for @readerPages.
  ///
  /// In en, this message translates to:
  /// **'The book\'s pages'**
  String get readerPages;

  /// No description provided for @adhanPassed.
  ///
  /// In en, this message translates to:
  /// **'Since the adhan'**
  String get adhanPassed;

  /// No description provided for @elapsedHint.
  ///
  /// In en, this message translates to:
  /// **'Time since the adhan — clears after twenty minutes'**
  String get elapsedHint;

  /// No description provided for @soundRing.
  ///
  /// In en, this message translates to:
  /// **'Alert 4'**
  String get soundRing;

  /// No description provided for @jumuahSilentTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-silent on Friday'**
  String get jumuahSilentTitle;

  /// No description provided for @jumuahSilentHint.
  ///
  /// In en, this message translates to:
  /// **'From the Jumu\'ah adhan, for the minutes you choose.'**
  String get jumuahSilentHint;

  /// No description provided for @libraryInstallAll.
  ///
  /// In en, this message translates to:
  /// **'Install bundled books'**
  String get libraryInstallAll;

  /// No description provided for @libraryAllInstalled.
  ///
  /// In en, this message translates to:
  /// **'Every book is installed'**
  String get libraryAllInstalled;

  /// No description provided for @libraryInstallingAll.
  ///
  /// In en, this message translates to:
  /// **'Installing {index} of {total}: {title}'**
  String libraryInstallingAll(int index, int total, String title);

  /// No description provided for @smartTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart sync'**
  String get smartTitle;

  /// No description provided for @smartCalendarTab.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get smartCalendarTab;

  /// No description provided for @smartSilentTab.
  ///
  /// In en, this message translates to:
  /// **'Smart silence'**
  String get smartSilentTab;

  /// No description provided for @smartHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer blocks in your calendar'**
  String get smartHeroTitle;

  /// No description provided for @smartHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Prayer times move every day, so the app writes a rolling window rather than a repeating event.'**
  String get smartHeroBody;

  /// No description provided for @smartWindow.
  ///
  /// In en, this message translates to:
  /// **'Planning horizon'**
  String get smartWindow;

  /// No description provided for @smartWindowDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String smartWindowDays(int days);

  /// No description provided for @smartDuration.
  ///
  /// In en, this message translates to:
  /// **'Block length'**
  String get smartDuration;

  /// No description provided for @smartDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String smartDurationMinutes(int minutes);

  /// No description provided for @smartWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get smartWorkHours;

  /// No description provided for @smartFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get smartFrom;

  /// No description provided for @smartTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get smartTo;

  /// No description provided for @smartWrite.
  ///
  /// In en, this message translates to:
  /// **'Write to calendar'**
  String get smartWrite;

  /// No description provided for @smartWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get smartWriting;

  /// No description provided for @smartWrote.
  ///
  /// In en, this message translates to:
  /// **'Added {created} · updated {updated} · unchanged {unchanged}'**
  String smartWrote(int created, int updated, int unchanged);

  /// No description provided for @smartNeedPermission.
  ///
  /// In en, this message translates to:
  /// **'The app needs to read and write the phone calendar. It reads nothing before that.'**
  String get smartNeedPermission;

  /// No description provided for @smartGrant.
  ///
  /// In en, this message translates to:
  /// **'Allow calendar'**
  String get smartGrant;

  /// No description provided for @smartNoCalendar.
  ///
  /// In en, this message translates to:
  /// **'No writable calendar on this phone. Add an account in your calendar app and come back.'**
  String get smartNoCalendar;

  /// No description provided for @smartConflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts that need a decision'**
  String get smartConflicts;

  /// No description provided for @smartNoConflicts.
  ///
  /// In en, this message translates to:
  /// **'No overlap between your prayers and your meetings.'**
  String get smartNoConflicts;

  /// No description provided for @smartPostponeTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {time}'**
  String smartPostponeTo(String time);

  /// No description provided for @smartSilentDuring.
  ///
  /// In en, this message translates to:
  /// **'Silent during the meeting'**
  String get smartSilentDuring;

  /// No description provided for @smartBlocksPreview.
  ///
  /// In en, this message translates to:
  /// **'Upcoming blocks'**
  String get smartBlocksPreview;

  /// No description provided for @smartBlockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks inside your working hours'**
  String smartBlockCount(int count);

  /// No description provided for @smartDecisionNow.
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get smartDecisionNow;

  /// No description provided for @smartInMosque.
  ///
  /// In en, this message translates to:
  /// **'You are in {mosque} — the phone stays silent and your watch pulses.'**
  String smartInMosque(String mosque);

  /// No description provided for @smartAtGate.
  ///
  /// In en, this message translates to:
  /// **'You are at {mosque} — silence and a pulse instead of the adhan.'**
  String smartAtGate(String mosque);

  /// No description provided for @smartInMeeting.
  ///
  /// In en, this message translates to:
  /// **'You are in {event} — silent until it ends.'**
  String smartInMeeting(String event);

  /// No description provided for @smartNormal.
  ///
  /// In en, this message translates to:
  /// **'No mosque and no meeting — the adhan plays as usual.'**
  String get smartNormal;

  /// No description provided for @smartMatrixTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision matrix'**
  String get smartMatrixTitle;

  /// No description provided for @smartMatrixMosque.
  ///
  /// In en, this message translates to:
  /// **'Inside a mosque'**
  String get smartMatrixMosque;

  /// No description provided for @smartMatrixMeeting.
  ///
  /// In en, this message translates to:
  /// **'In a meeting'**
  String get smartMatrixMeeting;

  /// No description provided for @smartMatrixNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get smartMatrixNormal;

  /// No description provided for @smartMatrixMosqueAction.
  ///
  /// In en, this message translates to:
  /// **'Silent + pulse'**
  String get smartMatrixMosqueAction;

  /// No description provided for @smartMatrixMeetingAction.
  ///
  /// In en, this message translates to:
  /// **'Temporary silence'**
  String get smartMatrixMeetingAction;

  /// No description provided for @smartMatrixNormalAction.
  ///
  /// In en, this message translates to:
  /// **'Full adhan'**
  String get smartMatrixNormalAction;

  /// No description provided for @smartRadius.
  ///
  /// In en, this message translates to:
  /// **'Mosque radius'**
  String get smartRadius;

  /// No description provided for @smartRadiusMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String smartRadiusMeters(int meters);

  /// No description provided for @smartMosques.
  ///
  /// In en, this message translates to:
  /// **'Nearest mosques'**
  String get smartMosques;

  /// No description provided for @smartNoMosques.
  ///
  /// In en, this message translates to:
  /// **'No nearby mosques found in OpenStreetMap.'**
  String get smartNoMosques;

  /// No description provided for @smartDndOn.
  ///
  /// In en, this message translates to:
  /// **'Allow automatic silence'**
  String get smartDndOn;

  /// No description provided for @smartRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get smartRefresh;

  /// No description provided for @smartPostponed.
  ///
  /// In en, this message translates to:
  /// **'Meeting moved'**
  String get smartPostponed;

  /// No description provided for @smartSilenced.
  ///
  /// In en, this message translates to:
  /// **'The phone will stay silent during the meeting'**
  String get smartSilenced;

  /// No description provided for @smartDndDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatic silence in a mosque or during a meeting, restored afterwards.'**
  String get smartDndDesc;

  /// No description provided for @smartMosqueError.
  ///
  /// In en, this message translates to:
  /// **'Could not load nearby mosques. Check the connection and try again.'**
  String get smartMosqueError;

  /// No description provided for @smartSilencedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} meetings silenced'**
  String smartSilencedCount(int count);

  /// No description provided for @semanticMeaningChip.
  ///
  /// In en, this message translates to:
  /// **'meaning'**
  String get semanticMeaningChip;

  /// No description provided for @semanticModelHint.
  ///
  /// In en, this message translates to:
  /// **'Meaning search runs offline — the engine downloads once'**
  String get semanticModelHint;

  /// No description provided for @semanticDownload.
  ///
  /// In en, this message translates to:
  /// **'Download engine'**
  String get semanticDownload;

  /// No description provided for @semanticDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String semanticDownloading(int percent);

  /// No description provided for @semanticFailed.
  ///
  /// In en, this message translates to:
  /// **'The engine download failed'**
  String get semanticFailed;

  /// No description provided for @semanticRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get semanticRetry;

  /// No description provided for @sunAlignTitle.
  ///
  /// In en, this message translates to:
  /// **'Sun alignment'**
  String get sunAlignTitle;

  /// No description provided for @sunAlignFar.
  ///
  /// In en, this message translates to:
  /// **'The sun is {degrees}° from the qibla'**
  String sunAlignFar(String degrees);

  /// No description provided for @sunAlignNear.
  ///
  /// In en, this message translates to:
  /// **'The sun is close to the qibla — your shadow points to it'**
  String get sunAlignNear;

  /// No description provided for @sunAlignNow.
  ///
  /// In en, this message translates to:
  /// **'The sun is on the qibla now — your shadow points to it'**
  String get sunAlignNow;

  /// No description provided for @sunAlignNight.
  ///
  /// In en, this message translates to:
  /// **'Sun alignment returns after sunrise'**
  String get sunAlignNight;

  /// No description provided for @recitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recitation check'**
  String get recitationTitle;

  /// No description provided for @recitationPickAyah.
  ///
  /// In en, this message translates to:
  /// **'Choose surah and ayah'**
  String get recitationPickAyah;

  /// No description provided for @recitationListening.
  ///
  /// In en, this message translates to:
  /// **'Listening to you…'**
  String get recitationListening;

  /// No description provided for @recitationThinking.
  ///
  /// In en, this message translates to:
  /// **'Working out what I heard…'**
  String get recitationThinking;

  /// No description provided for @recitationComplete.
  ///
  /// In en, this message translates to:
  /// **'Ayah complete — well recited'**
  String get recitationComplete;

  /// No description provided for @recitationPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the mushaf…'**
  String get recitationPreparing;

  /// No description provided for @recitationIdle.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone and start reciting'**
  String get recitationIdle;

  /// No description provided for @recitationModelMissing.
  ///
  /// In en, this message translates to:
  /// **'The recitation engine is not installed'**
  String get recitationModelMissing;

  /// No description provided for @recitationModelHint.
  ///
  /// In en, this message translates to:
  /// **'The recitation engine downloads once (160 MB) and then works offline. Your voice is never recorded or stored.'**
  String get recitationModelHint;

  /// No description provided for @recitationDownload.
  ///
  /// In en, this message translates to:
  /// **'Download engine'**
  String get recitationDownload;

  /// No description provided for @recitationDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed — check your connection'**
  String get recitationDownloadFailed;

  /// No description provided for @recitationError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get recitationError;

  /// No description provided for @recitationMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for the recitation check'**
  String get recitationMicDenied;

  /// No description provided for @recitationHeard.
  ///
  /// In en, this message translates to:
  /// **'What the engine heard'**
  String get recitationHeard;

  /// No description provided for @recitationHeardInstead.
  ///
  /// In en, this message translates to:
  /// **'Heard \"{spoken}\" but the verse says \"{expected}\"'**
  String recitationHeardInstead(String spoken, String expected);

  /// No description provided for @recitationTrySample.
  ///
  /// In en, this message translates to:
  /// **'Try a sample recitation'**
  String get recitationTrySample;

  /// No description provided for @srcQuranText.
  ///
  /// In en, this message translates to:
  /// **'Uthmani Quran text from Quran.com v4 — bundled, no network while reading'**
  String get srcQuranText;

  /// No description provided for @srcTafsir.
  ///
  /// In en, this message translates to:
  /// **'Al-Muyassar tafsir (Quran.com v4, edition 16) — bundled'**
  String get srcTafsir;

  /// No description provided for @srcLibrary.
  ///
  /// In en, this message translates to:
  /// **'21 books from the Shamela corpus via OpenITI — CC BY-NC-SA 4.0'**
  String get srcLibrary;

  /// No description provided for @srcMutashabih.
  ///
  /// In en, this message translates to:
  /// **'Al-Kisa\'i, Mutashabihat al-Qur\'an (d. 189 AH) — every link traced to its verse'**
  String get srcMutashabih;

  /// No description provided for @srcAdhan.
  ///
  /// In en, this message translates to:
  /// **'Prayer times computed on the device with adhan-dart — MIT'**
  String get srcAdhan;

  /// No description provided for @srcAladhanVerify.
  ///
  /// In en, this message translates to:
  /// **'Optional cross-check of the calculation angles only, never used for the times shown'**
  String get srcAladhanVerify;

  /// No description provided for @srcOsm.
  ///
  /// In en, this message translates to:
  /// **'Mosque locations from OpenStreetMap — ODbL, via Overpass and Nominatim'**
  String get srcOsm;

  /// No description provided for @srcGooglePlaces.
  ///
  /// In en, this message translates to:
  /// **'Extra mosque results when a key is present — Google Places'**
  String get srcGooglePlaces;

  /// No description provided for @srcWhisper.
  ///
  /// In en, this message translates to:
  /// **'Recitation checking: Whisper base-ar-quran by tarteel-ai, ONNX build by Synthesium — Apache-2.0, on-device'**
  String get srcWhisper;

  /// No description provided for @srcSemantic.
  ///
  /// In en, this message translates to:
  /// **'Search by meaning: multilingual-e5-small by intfloat — MIT, quantised to int8 on-device'**
  String get srcSemantic;

  /// No description provided for @srcFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts: KFGQPC Uthmanic Hafs, Amiri, Scheherazade New, IBM Plex Sans Arabic — SIL OFL'**
  String get srcFonts;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get openSourceLicenses;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updateTitle;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get updateCheck;

  /// No description provided for @updateIntro.
  ///
  /// In en, this message translates to:
  /// **'Updates are entirely manual: nothing is checked in the background. The app reads the project\'s GitHub releases page only when you tap the button.'**
  String get updateIntro;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get updateUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version:'**
  String get updateAvailable;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// No description provided for @updateVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying the file\'s checksum…'**
  String get updateVerifying;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get updateInstall;

  /// No description provided for @updateAllowInstall.
  ///
  /// In en, this message translates to:
  /// **'Android needs your permission to install apps from this source. I will open that setting; come back and tap Install.'**
  String get updateAllowInstall;

  /// No description provided for @updateOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get updateOpenSettings;

  /// No description provided for @updateUnverified.
  ///
  /// In en, this message translates to:
  /// **'The release publishes no SHA-256, so I could not verify the file. Install at your own risk.'**
  String get updateUnverified;

  /// No description provided for @updateNoChannel.
  ///
  /// In en, this message translates to:
  /// **'This build has no update channel (no repository path was set when it was compiled).'**
  String get updateNoChannel;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach GitHub. Check the connection and try again.'**
  String get updateFailed;

  /// No description provided for @updateRateLimited.
  ///
  /// In en, this message translates to:
  /// **'GitHub is rate-limiting this network. Wait a moment and try again.'**
  String get updateRateLimited;

  /// No description provided for @updateNoRelease.
  ///
  /// In en, this message translates to:
  /// **'The repository has no published release yet.'**
  String get updateNoRelease;

  /// No description provided for @updateChecksumFailed.
  ///
  /// In en, this message translates to:
  /// **'The file\'s checksum does not match the published one — it was deleted and nothing was installed.'**
  String get updateChecksumFailed;

  /// No description provided for @recitationDownloadErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check the connection and try again.'**
  String get recitationDownloadErrorOffline;

  /// No description provided for @recitationDownloadErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The download timed out.'**
  String get recitationDownloadErrorTimeout;

  /// No description provided for @recitationDownloadErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The file is missing on the server (404).'**
  String get recitationDownloadErrorNotFound;

  /// No description provided for @recitationDownloadErrorBadPayload.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid file; nothing was installed.'**
  String get recitationDownloadErrorBadPayload;

  /// No description provided for @recitationDownloadErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'The download failed for an unexpected reason.'**
  String get recitationDownloadErrorUnknown;

  /// No description provided for @recitationDownloadRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get recitationDownloadRetry;

  /// No description provided for @recitationModelSizeHint.
  ///
  /// In en, this message translates to:
  /// **'153 MB — Wi‑Fi recommended, downloaded once.'**
  String get recitationModelSizeHint;

  /// No description provided for @recitationDownloadedFrom.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String recitationDownloadedFrom(Object source);

  /// No description provided for @updateRepoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Repository not found on GitHub. Check the owner/name path, or that it is public.'**
  String get updateRepoNotFound;

  /// No description provided for @updatePatchHint.
  ///
  /// In en, this message translates to:
  /// **'Small update: {size} only — rebuilt on the device from the installed build.'**
  String updatePatchHint(String size);

  /// No description provided for @updatePatchedLocally.
  ///
  /// In en, this message translates to:
  /// **'Ready — rebuilt on the device and verified against the published checksum.'**
  String get updatePatchedLocally;

  /// No description provided for @silentNowTitle.
  ///
  /// In en, this message translates to:
  /// **'The phone is silent now'**
  String get silentNowTitle;

  /// No description provided for @silentNowBody.
  ///
  /// In en, this message translates to:
  /// **'It was silenced for prayer time and will restore itself at {time}.'**
  String silentNowBody(String time);

  /// No description provided for @silentNowRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore sound now'**
  String get silentNowRestore;

  /// No description provided for @silentNowRestored.
  ///
  /// In en, this message translates to:
  /// **'The ringer is back to how it was.'**
  String get silentNowRestored;

  /// No description provided for @locationNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Your location is not known yet, so nearby mosques cannot be searched.'**
  String get locationNotDetected;

  /// No description provided for @locationDetectNow.
  ///
  /// In en, this message translates to:
  /// **'Locate me'**
  String get locationDetectNow;

  /// No description provided for @radarUsingManualCity.
  ///
  /// In en, this message translates to:
  /// **'Mosques around {city} — the location was chosen by hand.'**
  String radarUsingManualCity(String city);

  /// No description provided for @mosqueAddHere.
  ///
  /// In en, this message translates to:
  /// **'Add the mosque here'**
  String get mosqueAddHere;

  /// No description provided for @mosqueAddHint.
  ///
  /// In en, this message translates to:
  /// **'The mosque is saved at your current position, accurate to 10 metres.'**
  String get mosqueAddHint;

  /// No description provided for @mosqueNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Mosque name (optional)'**
  String get mosqueNameOptional;

  /// No description provided for @mosqueAdded.
  ///
  /// In en, this message translates to:
  /// **'The mosque was added to your list.'**
  String get mosqueAdded;

  /// No description provided for @mosqueDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete the mosque'**
  String get mosqueDelete;

  /// No description provided for @mosqueDeleted.
  ///
  /// In en, this message translates to:
  /// **'The mosque was removed from your list.'**
  String get mosqueDeleted;

  /// No description provided for @mosqueUserTag.
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get mosqueUserTag;

  /// No description provided for @bookNeedsRepair.
  ///
  /// In en, this message translates to:
  /// **'This book was downloaded before but its text is missing. Download it again.'**
  String get bookNeedsRepair;

  /// No description provided for @bookReinstall.
  ///
  /// In en, this message translates to:
  /// **'Download again'**
  String get bookReinstall;

  /// No description provided for @recitationResuming.
  ///
  /// In en, this message translates to:
  /// **'Resuming from {size} already downloaded.'**
  String recitationResuming(String size);

  /// No description provided for @bookRepairing.
  ///
  /// In en, this message translates to:
  /// **'Repairing the book…'**
  String get bookRepairing;

  /// No description provided for @midadTitle.
  ///
  /// In en, this message translates to:
  /// **'Al-Mi\'dad'**
  String get midadTitle;

  /// No description provided for @midadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The Qur\'an text lab'**
  String get midadSubtitle;

  /// No description provided for @midadScopeMushaf.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get midadScopeMushaf;

  /// No description provided for @midadScopeSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get midadScopeSurah;

  /// No description provided for @midadScopeJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get midadScopeJuz;

  /// No description provided for @midadScopePage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get midadScopePage;

  /// No description provided for @midadScopeHizb.
  ///
  /// In en, this message translates to:
  /// **'Hizb'**
  String get midadScopeHizb;

  /// No description provided for @midadScopeMeccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get midadScopeMeccan;

  /// No description provided for @midadScopeMedinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get midadScopeMedinan;

  /// No description provided for @midadUnitLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get midadUnitLetter;

  /// No description provided for @midadUnitWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get midadUnitWord;

  /// No description provided for @midadUnitAyah.
  ///
  /// In en, this message translates to:
  /// **'Verse length'**
  String get midadUnitAyah;

  /// No description provided for @midadUnitFasila.
  ///
  /// In en, this message translates to:
  /// **'Rhyme letter'**
  String get midadUnitFasila;

  /// No description provided for @midadProbeLetterHint.
  ///
  /// In en, this message translates to:
  /// **'Type one letter…'**
  String get midadProbeLetterHint;

  /// No description provided for @midadProbeWordHint.
  ///
  /// In en, this message translates to:
  /// **'Type a word…'**
  String get midadProbeWordHint;

  /// No description provided for @midadBasmala.
  ///
  /// In en, this message translates to:
  /// **'Count the basmala'**
  String get midadBasmala;

  /// No description provided for @midadSimpleScript.
  ///
  /// In en, this message translates to:
  /// **'Simple script'**
  String get midadSimpleScript;

  /// No description provided for @midadResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get midadResult;

  /// No description provided for @midadCounted.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get midadCounted;

  /// No description provided for @midadOfLetters.
  ///
  /// In en, this message translates to:
  /// **'out of {total} letters in this scope'**
  String midadOfLetters(Object total);

  /// No description provided for @midadOfWords.
  ///
  /// In en, this message translates to:
  /// **'out of {total} words in this scope'**
  String midadOfWords(Object total);

  /// No description provided for @midadOfAyahs.
  ///
  /// In en, this message translates to:
  /// **'verses end with it, out of {total} verses'**
  String midadOfAyahs(Object total);

  /// No description provided for @midadAvgLength.
  ///
  /// In en, this message translates to:
  /// **'Average verse length: {n} letters'**
  String midadAvgLength(Object n);

  /// No description provided for @midadHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Where it concentrates'**
  String get midadHeatmap;

  /// No description provided for @midadHeatmapHint.
  ///
  /// In en, this message translates to:
  /// **'Each square is a surah — tap one to narrow the count to it'**
  String get midadHeatmapHint;

  /// No description provided for @midadTopVerses.
  ///
  /// In en, this message translates to:
  /// **'Verses where it concentrates'**
  String get midadTopVerses;

  /// No description provided for @midadInsights.
  ///
  /// In en, this message translates to:
  /// **'Curiosities'**
  String get midadInsights;

  /// No description provided for @midadInsightTopLetter.
  ///
  /// In en, this message translates to:
  /// **'Most frequent letter'**
  String get midadInsightTopLetter;

  /// No description provided for @midadInsightHapax.
  ///
  /// In en, this message translates to:
  /// **'Words that occur only once'**
  String get midadInsightHapax;

  /// No description provided for @midadInsightLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest verse'**
  String get midadInsightLongest;

  /// No description provided for @midadInsightRarest.
  ///
  /// In en, this message translates to:
  /// **'Rarest letter by spread'**
  String get midadInsightRarest;

  /// No description provided for @midadHowWeCount.
  ///
  /// In en, this message translates to:
  /// **'How we count'**
  String get midadHowWeCount;

  /// No description provided for @midadHowBody.
  ///
  /// In en, this message translates to:
  /// **'Counted from the bundled Uthmani text:\n\n• Letters: diacritics and pause marks are removed; the letter stays as written. “Simple script” folds ٱ أ إ آ into one alef (ا).\n• Words: whole tokens — «الله» is not counted inside «بالله». “Inside words” allows exactly that, explicitly.\n• The divine name: «الله» alone is 2,153, plus «لله» it is 2,703; the familiar 2,699 figure combines them — which is why it differs from the whole-word count.\n• Basmala: not a verse outside Al-Fatihah. The option adds its letters and words, never a verse.\n• Rhyme letter: the last written letter of the verse.\n\nEvery card carries its scope and switches, so every number is reproducible.'**
  String get midadHowBody;

  /// No description provided for @midadPickPlace.
  ///
  /// In en, this message translates to:
  /// **'Choose a scope'**
  String get midadPickPlace;

  /// No description provided for @midadNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this scope'**
  String get midadNothing;

  /// No description provided for @midadOpenVerse.
  ///
  /// In en, this message translates to:
  /// **'Open the verse'**
  String get midadOpenVerse;

  /// No description provided for @midadLettersTotal.
  ///
  /// In en, this message translates to:
  /// **'Letters of the mushaf'**
  String get midadLettersTotal;

  /// No description provided for @midadWordsTotal.
  ///
  /// In en, this message translates to:
  /// **'Its words'**
  String get midadWordsTotal;

  /// No description provided for @midadVerse.
  ///
  /// In en, this message translates to:
  /// **'verse'**
  String get midadVerse;

  /// No description provided for @midadWordInside.
  ///
  /// In en, this message translates to:
  /// **'Inside words'**
  String get midadWordInside;

  /// No description provided for @midadOfAyahCount.
  ///
  /// In en, this message translates to:
  /// **'out of {total} verses in this scope'**
  String midadOfAyahCount(Object total);

  /// No description provided for @mosqueFenceTitle.
  ///
  /// In en, this message translates to:
  /// **'My mosque'**
  String get mosqueFenceTitle;

  /// No description provided for @mosqueFenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record it while you are inside — the silence works only inside this fence, and only at prayer times.'**
  String get mosqueFenceSubtitle;

  /// No description provided for @mosqueFenceSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Silence is now limited to your mosque\'s fence, and to prayer times.'**
  String get mosqueFenceSubtitleOn;

  /// No description provided for @mosqueFenceRegister.
  ///
  /// In en, this message translates to:
  /// **'Record this mosque'**
  String get mosqueFenceRegister;

  /// No description provided for @mosqueFenceRegisterHint.
  ///
  /// In en, this message translates to:
  /// **'Stand inside or at the door, then tap — ten metres is enough.'**
  String get mosqueFenceRegisterHint;

  /// No description provided for @mosqueFenceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Mosque name (optional)'**
  String get mosqueFenceNameHint;

  /// No description provided for @mosqueFenceRadius.
  ///
  /// In en, this message translates to:
  /// **'Fence radius'**
  String get mosqueFenceRadius;

  /// No description provided for @mosqueFenceMeterUnit.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get mosqueFenceMeterUnit;

  /// No description provided for @mosqueFenceRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} m fence'**
  String mosqueFenceRadiusLabel(Object n);

  /// No description provided for @mosqueFenceDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{n} m away'**
  String mosqueFenceDistanceMeters(Object n);

  /// No description provided for @mosqueFenceDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{n} km away'**
  String mosqueFenceDistanceKm(Object n);

  /// No description provided for @mosqueFenceCheck.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get mosqueFenceCheck;

  /// No description provided for @mosqueFenceInsideNow.
  ///
  /// In en, this message translates to:
  /// **'You are inside the fence — it will silence at prayer time.'**
  String get mosqueFenceInsideNow;

  /// No description provided for @mosqueFenceOutsideNow.
  ///
  /// In en, this message translates to:
  /// **'You are outside the fence ({n} m) — it will not silence.'**
  String mosqueFenceOutsideNow(Object n);

  /// No description provided for @mosqueFenceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not read your location now; the silence will follow the usual schedule.'**
  String get mosqueFenceUnknown;

  /// No description provided for @mosqueFenceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete mosque'**
  String get mosqueFenceDelete;

  /// No description provided for @mosqueFenceAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get mosqueFenceAddAnother;

  /// No description provided for @mosqueFenceUnnamed.
  ///
  /// In en, this message translates to:
  /// **'My mosque'**
  String get mosqueFenceUnnamed;

  /// No description provided for @mosqueFenceSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved — the silence is now limited to its fence.'**
  String get mosqueFenceSaved;

  /// No description provided for @mosqueFenceNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'Fix your location first from the button above, then record the mosque.'**
  String get mosqueFenceNeedLocation;

  /// No description provided for @mosqueFenceAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Your fix is ±{n} m right now.'**
  String mosqueFenceAccuracy(Object n);

  /// No description provided for @mosqueFenceNeedsBackground.
  ///
  /// In en, this message translates to:
  /// **'To work with the app closed it needs the “allow all the time” location permission.'**
  String get mosqueFenceNeedsBackground;

  /// No description provided for @mosqueAccuracyLine.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy ±{n} m — the smaller, the truer.'**
  String mosqueAccuracyLine(Object n);

  /// No description provided for @mosqueAccuracyPoor.
  ///
  /// In en, this message translates to:
  /// **'Your location is coarse (±{n} m). Tap the location button above while you are at the place itself.'**
  String mosqueAccuracyPoor(Object n);

  /// No description provided for @mosqueFixNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get mosqueFixNow;

  /// No description provided for @mosqueFenceFallbackNote.
  ///
  /// In en, this message translates to:
  /// **'If the location cannot be read at the adhan, the silence follows the usual schedule rather than missing it.'**
  String get mosqueFenceFallbackNote;
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
