import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Awan';

  @override
  String get appFullName => 'Awan | Prayer Times & Quran';

  @override
  String get tagline => 'Calmness for the soul';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Something went wrong';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search…';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get sync => 'Sync';

  @override
  String get version => 'Version';

  @override
  String get about => 'About';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get open => 'Open';

  @override
  String get back => 'Back';

  @override
  String get delete => 'Delete';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get minutesShort => 'min';

  @override
  String get secondsShort => 's';

  @override
  String get hoursShort => 'h';

  @override
  String get km => 'km';

  @override
  String get meter => 'm';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingNoon => 'Peace be upon you';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get nextPrayer => 'Next prayer';

  @override
  String get remaining => 'Remaining';

  @override
  String prayerIn(String time) {
    return '$time left';
  }

  @override
  String get prayerNow => 'It is prayer time';

  @override
  String get todayPrayers => 'Today\'s prayers';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get adhan => 'Adhan';

  @override
  String get prayerTimetable => 'Prayer timetable';

  @override
  String get monthlyTimetable => 'Monthly timetable';

  @override
  String get qibla => 'Qibla';

  @override
  String get qiblaDirection => 'Qibla direction';

  @override
  String qiblaDegrees(String degrees) {
    return '$degrees° from North';
  }

  @override
  String get hijriDate => 'Hijri date';

  @override
  String get gregorianDate => 'Gregorian date';

  @override
  String get hijriOffset => 'Hijri adjustment (days)';

  @override
  String get location => 'Location';

  @override
  String get locationAuto => 'Auto (device GPS)';

  @override
  String get locationManual => 'Manual (choose a city)';

  @override
  String get detectLocation => 'Detect my location';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get cityName => 'City name';

  @override
  String get locationDenied => 'Location permission is required to calculate prayer times for your city.';

  @override
  String get locationUnavailable => 'Could not read the device location. Pick a city manually.';

  @override
  String get calculationMethod => 'Calculation method';

  @override
  String get madhab => 'Asr madhab';

  @override
  String get madhabShafi => 'Shafi / Maliki / Hanbali';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get highLatitudeRule => 'High latitude rule';

  @override
  String get highLatitudeMiddle => 'Middle of the night';

  @override
  String get highLatitudeSeventh => 'One seventh of the night';

  @override
  String get highLatitudeTwilight => 'Angle based';

  @override
  String get prayerAdjustments => 'Manual adjustments (minutes)';

  @override
  String get methodMWL => 'Muslim World League';

  @override
  String get methodEgyptian => 'Egyptian General Authority';

  @override
  String get methodUmmAlQura => 'Umm al-Qura (Makkah)';

  @override
  String get methodKarachi => 'University of Karachi';

  @override
  String get methodNorthAmerica => 'ISNA (North America)';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodDubai => 'Dubai';

  @override
  String get methodTurkey => 'Turkey (Diyanet)';

  @override
  String get methodTehran => 'Tehran';

  @override
  String get methodSingapore => 'Singapore';

  @override
  String get methodOther => 'Other';

  @override
  String get verifyOnline => 'Verify angles online';

  @override
  String get verifyOk => 'Offline calculation matches the reference';

  @override
  String verifyDiff(String minutes) {
    return 'Difference of $minutes min vs. the reference — review the calculation method';
  }

  @override
  String lastVerified(String date) {
    return 'Last verified $date';
  }

  @override
  String get quran => 'Quran';

  @override
  String get surahs => 'Surahs';

  @override
  String get meccan => 'Meccan';

  @override
  String get medinan => 'Medinan';

  @override
  String ayahCount(int count) {
    return '$count verses';
  }

  @override
  String get searchQuran => 'Search the Quran';

  @override
  String get searchQuranHint => 'Type a word or part of a verse';

  @override
  String get noResults => 'No results';

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String get bookmark => 'Bookmark';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get addBookmark => 'Add bookmark';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get bookmarkAdded => 'Bookmark added';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get lastRead => 'Last read';

  @override
  String get continueReading => 'Continue reading';

  @override
  String get fontSize => 'Font size';

  @override
  String get quranFont => 'Quran script';

  @override
  String get scriptUthmani => 'Uthmani (Amiri Quran)';

  @override
  String get scriptScheherazade => 'Scheherazade New';

  @override
  String get nightReadingMode => 'Night reading mode';

  @override
  String get tafsir => 'Tafsir';

  @override
  String get showTafsir => 'Show tafsir';

  @override
  String get tafsirUnavailable => 'No tafsir installed for this verse';

  @override
  String get jumpToAyah => 'Jump to ayah';

  @override
  String get ayah => 'Ayah';

  @override
  String get surah => 'Surah';

  @override
  String get page => 'Page';

  @override
  String get juz => 'Juz';

  @override
  String get copyAyah => 'Copy ayah';

  @override
  String get shareAyah => 'Share ayah';

  @override
  String get tafsirPackages => 'Tafsir packages';

  @override
  String get tafsirPackagesDesc => 'Downloaded once and kept offline on your device.';

  @override
  String get bundledPackage => 'Bundled';

  @override
  String get installPackage => 'Install';

  @override
  String get installing => 'Installing…';

  @override
  String get installed => 'Installed';

  @override
  String get uninstall => 'Remove';

  @override
  String packageSize(String size) {
    return '$size KB';
  }

  @override
  String get mosqueRadar => 'Mosque radar';

  @override
  String get nearbyMosques => 'Nearby mosques';

  @override
  String get nearestMosques => 'Nearest mosques';

  @override
  String walkingTime(String time) {
    return 'Walking $time';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get mosque => 'Mosque';

  @override
  String get noMosquesFound => 'No mosques found nearby';

  @override
  String get placesKeyMissing => 'Add a Google Places key to use Google results. OpenStreetMap data is used meanwhile.';

  @override
  String get cacheHint => 'Results are cached for 48 hours to save data and battery';

  @override
  String get map => 'Map';

  @override
  String get list => 'List';

  @override
  String get library => 'Library';

  @override
  String get maktabaSubtitle => 'Al-Maktaba Al-Shamila';

  @override
  String get catalog => 'Catalog';

  @override
  String get myBooks => 'My books';

  @override
  String get downloadBook => 'Download';

  @override
  String get downloadStarted => 'Download started';

  @override
  String get bookImported => 'Book imported successfully';

  @override
  String get importFile => 'Import from file';

  @override
  String get importUrl => 'Import from a link';

  @override
  String get bookSearch => 'Search for a book or an author';

  @override
  String get noBooks => 'No books yet. Download one from the catalog or import a file.';

  @override
  String get parserIsolate => 'Parsing in the background so the interface stays smooth';

  @override
  String get librarySource => 'Library source';

  @override
  String get sourceShamela => 'Al-Maktaba Al-Shamila';

  @override
  String get sourceOpenIti => 'OpenITI corpus';

  @override
  String get sourceLocal => 'On-device files';

  @override
  String get readingProgress => 'Progress';

  @override
  String get settings => 'Settings';

  @override
  String get display => 'Display';

  @override
  String get elderlyMode => 'Elderly mode';

  @override
  String get elderlyModeDesc => '150% larger text, three large cards and no complex gestures.';

  @override
  String get textScale => 'Text scale';

  @override
  String get simpleMode => 'Simple mode';

  @override
  String get moreFeatures => 'More features';

  @override
  String get notifications => 'Notifications';

  @override
  String get adhanNotifications => 'Adhan notifications';

  @override
  String get notificationsEnabled => 'Notifications are enabled';

  @override
  String get notificationsDenied => 'Notification permission is denied';

  @override
  String get vibrate => 'Vibrate';

  @override
  String get playSound => 'Play sound';

  @override
  String get silentMode => 'Auto silent mode';

  @override
  String get silentModeDesc => 'Mute the phone before the adhan and restore it afterwards (Android).';

  @override
  String get silentModePermission => 'Grant the Do Not Disturb access';

  @override
  String muteBeforeMinutes(int count) {
    return 'Mute $count minutes before';
  }

  @override
  String unmuteAfterMinutes(int count) {
    return 'Restore $count minutes after';
  }

  @override
  String get fridaySchedule => 'Friday prayer';

  @override
  String get fridayScheduleDesc => 'Mute from 11:30 to 13:30 (customisable).';

  @override
  String get fridayStart => 'Start';

  @override
  String get fridayEnd => 'End';

  @override
  String get iosSilentNotice => 'iOS does not allow apps to mute the device. A reminder to enable Focus mode is sent instead.';

  @override
  String get backgroundTasks => 'Background sync';

  @override
  String get backgroundSyncDesc => 'Prayer angles are verified once a week in the background, using no noticeable battery.';

  @override
  String get tasbih => 'Tasbih';

  @override
  String get tasbihCount => 'Count';

  @override
  String get tasbihTarget => 'Target';

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihSaved => 'Saved';

  @override
  String get seasonGreeting => 'May your worship be accepted';

  @override
  String get addons => 'Add-ons';

  @override
  String get dataSources => 'Data sources';

  @override
  String get dataSourcesDesc => 'Prayer times: adhan_dart offline + Aladhan API for verification. Places: Google Places / OpenStreetMap. Quran text: Tanzil Uthmani via quran.com. Tafsir: King Saud University / quran.com.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyDesc => 'Your location, bookmarks and downloads stay on your device. No account, no tracking.';

  @override
  String get licenses => 'Open source licences';

  @override
  String get aboutDesc => 'An offline-first Islamic super app focused on calmness, speed and battery life.';

  @override
  String get elderlyModeOn => 'Elderly mode is on';

  @override
  String get turnOffElderly => 'Turn off';

  @override
  String get permissionNeeded => 'Permission needed';

  @override
  String get openSettings => 'Open settings';

  @override
  String get noNetwork => 'No internet connection — showing offline data';

  @override
  String get cachedResults => 'Cached results';

  @override
  String updated(String time) {
    return 'Updated $time';
  }

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get today => 'Today';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get zeroCount => '0';

  @override
  String adhanScheduled(int count) {
    return 'Scheduled $count upcoming adhan notifications';
  }

  @override
  String get adhanCancelled => 'All adhan notifications cancelled';

  @override
  String get silentNeedsPolicy => 'Auto-silent needs Do-Not-Disturb access';

  @override
  String silentScheduled(int count) {
    return 'Silence windows armed for $count days';
  }

  @override
  String scheduledCount(int count) {
    return '$count notifications armed';
  }

  @override
  String get compassUnavailable => 'This device has no compass (magnetometer), so the dial stays north-up. The bearing below is exact.';

  @override
  String get qiblaAligned => 'You are facing the qibla';

  @override
  String turnRight(int degrees) {
    return 'Turn $degrees° right';
  }

  @override
  String turnLeft(int degrees) {
    return 'Turn $degrees° left';
  }

  @override
  String toMakkah(String km) {
    return '$km km to Makkah';
  }

  @override
  String get compassCalibration => 'Move the phone in a figure 8 to calibrate the compass';

  @override
  String get bearingFromTrueNorth => 'Bearing measured from true north';

  @override
  String get liveCompass => 'Live compass';

  @override
  String declinationCorrection(String degrees) {
    return 'Magnetic declination correction: $degrees°';
  }

  @override
  String get elderlyQibla => 'Face this direction';

  @override
  String get dataFromGoogle => 'Google Places data';

  @override
  String get dataFromOsm => 'OpenStreetMap data';

  @override
  String get dataFromCache => 'From the local cache (under 48 h old)';

  @override
  String searchRadius(String km) {
    return 'Search radius $km km';
  }

  @override
  String get nearestMosque => 'Nearest mosque';

  @override
  String get navigateToNearest => 'Navigate to the nearest mosque';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get metersShort => 'm';

  @override
  String get navigateShort => 'Directions';

  @override
  String get timeSection => 'Time';

  @override
  String get daylightSaving => 'Summer / winter time';

  @override
  String get dstAuto => 'Automatic (device)';

  @override
  String get dstAutoDesc => 'Trust the device clock — correct for almost every country.';

  @override
  String get dstPlusOne => 'Summer time (+1)';

  @override
  String get dstPlusOneDesc => 'Every time and reminder moves one hour earlier.';

  @override
  String get dstMinusOne => 'Winter time (−1)';

  @override
  String get dstMinusOneDesc => 'Every time and reminder moves one hour later.';

  @override
  String get dstDeviceFixed => 'Your device keeps one offset all year';

  @override
  String get dstDeviceOnSummer => 'Your device is on summer time';

  @override
  String get dstDeviceStandard => 'Your device is on winter time';

  @override
  String get dstNote => 'For countries that observe summer and winter time: if your device does not apply your country\'s rule (or ships an outdated one), set it here. The correction moves both the displayed time and the adhan alarm so they can never disagree, and it never touches the astronomical calculation.';

  @override
  String get quranTitle => 'The Holy Quran';

  @override
  String get startReading => 'Start reading';

  @override
  String get continueButton => 'Continue';

  @override
  String get surahIndex => 'Surahs';

  @override
  String get stopMarker => 'Stop marker';

  @override
  String get stopMarkerSet => 'Stop marker saved';

  @override
  String get stopMarkerCleared => 'Stop marker cleared';

  @override
  String get noStopMarker => 'No stop marker yet — tap the bookmark icon while reading.';

  @override
  String get goToStopMarker => 'Go there';

  @override
  String get setStopHere => 'Set the stop marker here';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchOffline => 'Search works without internet';

  @override
  String get bookmarksTitle => 'Saved verses';

  @override
  String get noBookmarks => 'Nothing saved yet';

  @override
  String get readingSettings => 'Reading settings';

  @override
  String get ayahFontSize => 'Ayah size';

  @override
  String get tafsirFontSize => 'Tafsir size';

  @override
  String get screenColour => 'Screen colour';

  @override
  String get palettePaper => 'Paper';

  @override
  String get paletteSepia => 'Sepia';

  @override
  String get paletteDark => 'Night';

  @override
  String get paletteOled => 'Pure black';

  @override
  String get readerMode => 'Reading mode';

  @override
  String get modePages => 'Mushaf pages';

  @override
  String get modeSurah => 'Continuous surah';

  @override
  String get makki => 'Meccan';

  @override
  String get madani => 'Medinan';

  @override
  String get ayahWord => 'verse';

  @override
  String get sajdaAyah => 'Prostration verse';

  @override
  String get prePrayerReminder => 'Reminder before prayer';

  @override
  String get prePrayerHint => 'An hourglass appears before the adhan and leaves with a tap — or by itself when the adhan arrives';

  @override
  String get prePrayerLead => 'Lead time';

  @override
  String get prePrayerSound => 'Soft chime';

  @override
  String get prePrayerSoundHint => 'A short ring with the reminder instead of silence';

  @override
  String reminderSoonOne(Object prayer) {
    return '1 minute to $prayer';
  }

  @override
  String reminderSoonTwo(Object prayer) {
    return '2 minutes to $prayer';
  }

  @override
  String reminderSoonFew(Object minutes, Object prayer) {
    return '$minutes minutes to $prayer';
  }

  @override
  String reminderSoonMany(Object minutes, Object prayer) {
    return '$minutes minutes to $prayer';
  }

  @override
  String reminderPrepare(String prayer) {
    return 'Get ready for $prayer';
  }

  @override
  String get libraryTitle => 'Library';

  @override
  String get librarySubtitle => 'Arabic books, readable offline';

  @override
  String get libraryDiscover => 'Discover';

  @override
  String get libraryShelf => 'My shelf';

  @override
  String get librarySearchHint => 'Search title or author';

  @override
  String get libraryAllCategories => 'All categories';

  @override
  String get librarySync => 'Refresh index';

  @override
  String get librarySyncing => 'Refreshing the index…';

  @override
  String get librarySynced => 'Index up to date';

  @override
  String librarySyncedDetail(int added, int total) {
    return '$added added · $total total';
  }

  @override
  String get librarySyncFailed => 'Could not refresh the index';

  @override
  String get libraryOfflineCached => 'Offline — showing the saved copy';

  @override
  String get libraryIndexEmpty => 'The index is empty';

  @override
  String get libraryIndexEmptyHint => 'Refresh the index to fetch the catalogue, then download what you want to read.';

  @override
  String get libraryNoResults => 'No matches';

  @override
  String get libraryShelfEmpty => 'No downloaded books yet';

  @override
  String get libraryShelfEmptyHint => 'Downloaded books read fully offline.';

  @override
  String get libraryInstall => 'Download';

  @override
  String libraryInstalling(int percent) {
    return 'Downloading · $percent%';
  }

  @override
  String libraryUnpacking(int percent) {
    return 'Preparing · $percent%';
  }

  @override
  String get libraryInstalled => 'Downloaded';

  @override
  String get libraryRead => 'Read';

  @override
  String get libraryContinue => 'Continue reading';

  @override
  String get libraryRemove => 'Delete the downloaded copy';

  @override
  String libraryRemoveQuestion(String title) {
    return 'Delete “$title” from this device?';
  }

  @override
  String get libraryRemoveHint => 'The book stays in the catalogue and can be downloaded again.';

  @override
  String get libraryCancel => 'Cancel';

  @override
  String get libraryRetry => 'Try again';

  @override
  String get librarySourceHint => 'Index server address (https://…)';

  @override
  String get librarySourceSaved => 'Source saved';

  @override
  String get librarySourceInvalid => 'That address is not valid';

  @override
  String get libraryCancelInstall => 'Stop the download';

  @override
  String libraryLastSync(String when) {
    return 'Last refresh: $when';
  }

  @override
  String get libraryNever => 'Never refreshed';

  @override
  String libraryBooksCount(int count) {
    return '$count books';
  }

  @override
  String libraryChaptersCount(int count) {
    return '$count sections';
  }

  @override
  String librarySizeKb(int kb) {
    return '$kb KB';
  }

  @override
  String libraryAuthorDied(int year) {
    return 'd. $year AH';
  }

  @override
  String get libraryCategoryLabel => 'Category';

  @override
  String get readerTitle => 'Library reader';

  @override
  String get readerFontSize => 'Text size';

  @override
  String get readerNight => 'Night mode';

  @override
  String get readerChapterLabel => 'Chapter';

  @override
  String readerPageLabel(String page) {
    return 'p. $page';
  }

  @override
  String get readerBackToTop => 'Back to the first page';

  @override
  String get libraryShortcutEmpty => 'Download books to read offline';

  @override
  String libraryShortcutShelf(int count) {
    return '$count books on this device';
  }

  @override
  String libraryShortcutLastRead(String title) {
    return 'Last read: $title';
  }

  @override
  String get commonClose => 'Close';
}
