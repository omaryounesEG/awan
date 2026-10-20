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
  String get dataSourcesDesc => 'Everything below is bundled with the app; its origin and licence are stated — nothing is fetched quietly.';

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
  String get adhanAlertPerPrayer => 'Each adhan separately';

  @override
  String get adhanAlertHint => 'Per adhan: notification only, with vibration, or with vibration and the tone';

  @override
  String get adhanAlertQuiet => 'Notification only';

  @override
  String get adhanAlertVibrate => 'Vibration';

  @override
  String get adhanAlertTone => 'Vibration + tone';

  @override
  String get silentStartsLabel => 'Silence';

  @override
  String get silentLastsLabel => 'Lasts';

  @override
  String get silentStartsAtAdhan => 'At the adhan';

  @override
  String silentStartsAfter(int count) {
    return 'After $count min';
  }

  @override
  String silentLastsFor(int count) {
    return 'For $count min';
  }

  @override
  String get silentSaved => 'Silence windows saved';

  @override
  String get lockScreenCountdown => 'With the pre-prayer reminder on, a live countdown appears on the lock screen and keeps running after it locks.';

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
  String get graphTitle => 'Mutashabihat';

  @override
  String graphNodeLabel(String surah, String ayah) {
    return 'Surah $surah · Ayah $ayah';
  }

  @override
  String graphNodeNamedLabel(String name, String ayah) {
    return '$name · Ayah $ayah';
  }

  @override
  String get graphRuleLabel => 'The rule';

  @override
  String get graphRuleHint => 'What the two ayat share';

  @override
  String get graphPreparing => 'Preparing the graph for the first time…';

  @override
  String get graphEmptyNode => 'Nothing recorded for this ayah';

  @override
  String get graphSeedFailed => 'Could not prepare the Mutashabihat data';

  @override
  String get graphTapHint => 'Tap a node to read the ayah and the similarity rule';

  @override
  String get graphPickAyah => 'Choose an ayah';

  @override
  String get graphLevelAll => 'All';

  @override
  String get graphLevelHint => 'Ordered by match strength — pick how many verses to show';

  @override
  String graphShownOf(String shown, String total) {
    return '$shown of $total';
  }

  @override
  String get quranShowMutashabihat => 'Show similar verses';

  @override
  String get quranShowMutashabihatOn => 'Similar verses shown — tap any tinted verse to open its relations';

  @override
  String get graphSourceTag => 'The open ayah';

  @override
  String get graphTargetTag => 'Similar ayah';

  @override
  String graphTargetCount(int count) {
    return '$count similar ayat';
  }

  @override
  String get graphOpenTarget => 'This ayah\'s matches';

  @override
  String get graphShortcutEmpty => 'An interactive map of similar ayat';

  @override
  String graphShortcutReady(int nodes, int edges) {
    return '$nodes ayat · $edges similarity links';
  }

  @override
  String get commonClose => 'Close';

  @override
  String get kisaiLayerTitle => 'Al-Kisa\'i\'s similarities';

  @override
  String kisaiLayerSubtitle(String similar, String unique) {
    return '$similar verses with a counterpart, and $unique the book states have none — «مشتبهات القرآن» by al-Kisa\'i (d. 189 AH)';
  }

  @override
  String kisaiSimilarTab(String count) {
    return 'With a counterpart ($count)';
  }

  @override
  String kisaiUniqueTab(String count) {
    return 'Without one ($count)';
  }

  @override
  String get kisaiUniqueHint => 'Verses the book states have no similar passage anywhere in the Quran — the graph drops links that touch them.';

  @override
  String get kisaiFilterHint => 'Search by surah name or the book\'s wording';

  @override
  String get kisaiNoMatch => 'No matches';

  @override
  String get ayahSearchTitle => 'Find a verse';

  @override
  String get ayahSearchHint => 'Words from the verse, or its number (2:255)';

  @override
  String get ayahSearchExamples => '«لعلكم تتقون» · «2:255» · «البقرة 255»';

  @override
  String get ayahSearchExampleWords => 'لعلكم تتقون';

  @override
  String get ayahSearchExampleReference => '2:255';

  @override
  String get ayahSearchExampleNamed => 'البقرة 255';

  @override
  String ayahSearchGoTo(String surah, String ayah) {
    return 'Go to $surah $ayah';
  }

  @override
  String get ayahSearchBySurah => 'Pick surah and verse instead';

  @override
  String get lockScreenAllDayLabel => 'Lock-screen card, all day';

  @override
  String get lockScreenAllDayHint => 'The next prayer and its live countdown sit on your lock screen from Fajr to Isha — silent, and not swipeable.';

  @override
  String get prayerClockTitle => 'Prayer clock';

  @override
  String get prayerClockHint => 'Full screen: the clock, the time left to the next prayer, its name, and the hijri date.';

  @override
  String get clockFaceSegment => 'Segments';

  @override
  String get clockFaceWhite => 'Glowing white';

  @override
  String get clockFaceRed => 'Glowing red';

  @override
  String get clockFaceGreen => 'Glowing green';

  @override
  String get clockNight => 'Night mode';

  @override
  String get openPrayerClock => 'Open the prayer clock';

  @override
  String get clockOnLock => 'Show the prayer clock on the lock screen';

  @override
  String get clockOnLockHint => 'Comes up full screen over the PIN screen whenever you light the screen. Needs the “display over other apps” permission, and the app’s ongoing notification must stay on.';

  @override
  String get clockOverlayNeeded => 'The “display over other apps” permission is not granted yet — open settings, allow it, then try again.';

  @override
  String get clockOverlayGrant => 'Grant the permission';

  @override
  String get clockShowNow => 'Show it now';

  @override
  String get readerContents => 'Contents';

  @override
  String get readerContentsEmpty => 'This book has no headings.';

  @override
  String get readerSearch => 'Search in book';

  @override
  String get readerSearchHint => 'Type a word or phrase…';

  @override
  String get readerSearchEmpty => 'No matches in this book';

  @override
  String get readerSearchPrompt => 'Type at least two letters';

  @override
  String get readerNightMode => 'Night reading';

  @override
  String get adhanSoundTitle => 'Adhan sound';

  @override
  String get adhanSoundHint => 'The clip that rings at prayer time — audition it before choosing.';

  @override
  String get preAdhanSoundTitle => 'Reminder sound';

  @override
  String get preAdhanSoundHint => 'The clip for the reminder twenty minutes before the adhan.';

  @override
  String get soundSystem => 'System — the phone\'s alarm tone';

  @override
  String get soundSilent => 'No sound';

  @override
  String get soundTakbir => 'Alert 1';

  @override
  String get soundCall => 'Alert 2';

  @override
  String get soundAdhan => 'Alert 3';

  @override
  String get soundPreview => 'Audition';

  @override
  String get soundStop => 'Stop';

  @override
  String get readerPages => 'The book\'s pages';

  @override
  String get adhanPassed => 'Since the adhan';

  @override
  String get elapsedHint => 'Time since the adhan — clears after twenty minutes';

  @override
  String get soundRing => 'Alert 4';

  @override
  String get jumuahSilentTitle => 'Auto-silent on Friday';

  @override
  String get jumuahSilentHint => 'From the Jumu\'ah adhan, for the minutes you choose.';

  @override
  String get libraryInstallAll => 'Install bundled books';

  @override
  String get libraryAllInstalled => 'Every book is installed';

  @override
  String libraryInstallingAll(int index, int total, String title) {
    return 'Installing $index of $total: $title';
  }

  @override
  String get smartTitle => 'Smart sync';

  @override
  String get smartCalendarTab => 'Calendar';

  @override
  String get smartSilentTab => 'Smart silence';

  @override
  String get smartHeroTitle => 'Prayer blocks in your calendar';

  @override
  String get smartHeroBody => 'Prayer times move every day, so the app writes a rolling window rather than a repeating event.';

  @override
  String get smartWindow => 'Planning horizon';

  @override
  String smartWindowDays(int days) {
    return '$days days';
  }

  @override
  String get smartDuration => 'Block length';

  @override
  String smartDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get smartWorkHours => 'Working hours';

  @override
  String get smartFrom => 'From';

  @override
  String get smartTo => 'To';

  @override
  String get smartWrite => 'Write to calendar';

  @override
  String get smartWriting => 'Writing…';

  @override
  String smartWrote(int created, int updated, int unchanged) {
    return 'Added $created · updated $updated · unchanged $unchanged';
  }

  @override
  String get smartNeedPermission => 'The app needs to read and write the phone calendar. It reads nothing before that.';

  @override
  String get smartGrant => 'Allow calendar';

  @override
  String get smartNoCalendar => 'No writable calendar on this phone. Add an account in your calendar app and come back.';

  @override
  String get smartConflicts => 'Conflicts that need a decision';

  @override
  String get smartNoConflicts => 'No overlap between your prayers and your meetings.';

  @override
  String smartPostponeTo(String time) {
    return 'Move to $time';
  }

  @override
  String get smartSilentDuring => 'Silent during the meeting';

  @override
  String get smartBlocksPreview => 'Upcoming blocks';

  @override
  String smartBlockCount(int count) {
    return '$count blocks inside your working hours';
  }

  @override
  String get smartDecisionNow => 'Right now';

  @override
  String smartInMosque(String mosque) {
    return 'You are in $mosque — the phone stays silent and your watch pulses.';
  }

  @override
  String smartAtGate(String mosque) {
    return 'You are at $mosque — silence and a pulse instead of the adhan.';
  }

  @override
  String smartInMeeting(String event) {
    return 'You are in $event — silent until it ends.';
  }

  @override
  String get smartNormal => 'No mosque and no meeting — the adhan plays as usual.';

  @override
  String get smartMatrixTitle => 'Decision matrix';

  @override
  String get smartMatrixMosque => 'Inside a mosque';

  @override
  String get smartMatrixMeeting => 'In a meeting';

  @override
  String get smartMatrixNormal => 'Normal';

  @override
  String get smartMatrixMosqueAction => 'Silent + pulse';

  @override
  String get smartMatrixMeetingAction => 'Temporary silence';

  @override
  String get smartMatrixNormalAction => 'Full adhan';

  @override
  String get smartRadius => 'Mosque radius';

  @override
  String smartRadiusMeters(int meters) {
    return '$meters m';
  }

  @override
  String get smartMosques => 'Nearest mosques';

  @override
  String get smartNoMosques => 'No nearby mosques found in OpenStreetMap.';

  @override
  String get smartDndOn => 'Allow automatic silence';

  @override
  String get smartRefresh => 'Refresh';

  @override
  String get smartPostponed => 'Meeting moved';

  @override
  String get smartSilenced => 'The phone will stay silent during the meeting';

  @override
  String get smartDndDesc => 'Automatic silence in a mosque or during a meeting, restored afterwards.';

  @override
  String get smartMosqueError => 'Could not load nearby mosques. Check the connection and try again.';

  @override
  String smartSilencedCount(int count) {
    return '$count meetings silenced';
  }

  @override
  String get semanticMeaningChip => 'meaning';

  @override
  String get semanticModelHint => 'Meaning search runs offline — the engine downloads once';

  @override
  String get semanticDownload => 'Download engine';

  @override
  String semanticDownloading(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get semanticFailed => 'The engine download failed';

  @override
  String get semanticRetry => 'Try again';

  @override
  String get sunAlignTitle => 'Sun alignment';

  @override
  String sunAlignFar(String degrees) {
    return 'The sun is $degrees° from the qibla';
  }

  @override
  String get sunAlignNear => 'The sun is close to the qibla — your shadow points to it';

  @override
  String get sunAlignNow => 'The sun is on the qibla now — your shadow points to it';

  @override
  String get sunAlignNight => 'Sun alignment returns after sunrise';

  @override
  String get recitationTitle => 'Recitation check';

  @override
  String get recitationPickAyah => 'Choose surah and ayah';

  @override
  String get recitationListening => 'Listening to you…';

  @override
  String get recitationThinking => 'Working out what I heard…';

  @override
  String get recitationComplete => 'Ayah complete — well recited';

  @override
  String get recitationPreparing => 'Preparing the mushaf…';

  @override
  String get recitationIdle => 'Tap the microphone and start reciting';

  @override
  String get recitationModelMissing => 'The recitation engine is not installed';

  @override
  String get recitationModelHint => 'The recitation engine downloads once (160 MB) and then works offline. Your voice is never recorded or stored.';

  @override
  String get recitationDownload => 'Download engine';

  @override
  String get recitationDownloadFailed => 'Download failed — check your connection';

  @override
  String get recitationError => 'Something went wrong';

  @override
  String get recitationMicDenied => 'Microphone permission is required for the recitation check';

  @override
  String get recitationHeard => 'What the engine heard';

  @override
  String recitationHeardInstead(String spoken, String expected) {
    return 'Heard \"$spoken\" but the verse says \"$expected\"';
  }

  @override
  String get recitationTrySample => 'Try a sample recitation';

  @override
  String get srcQuranText => 'Uthmani Quran text from Quran.com v4 — bundled, no network while reading';

  @override
  String get srcTafsir => 'Al-Muyassar tafsir (Quran.com v4, edition 16) — bundled';

  @override
  String get srcLibrary => '21 books from the Shamela corpus via OpenITI — CC BY-NC-SA 4.0';

  @override
  String get srcMutashabih => 'Al-Kisa\'i, Mutashabihat al-Qur\'an (d. 189 AH) — every link traced to its verse';

  @override
  String get srcAdhan => 'Prayer times computed on the device with adhan-dart — MIT';

  @override
  String get srcAladhanVerify => 'Optional cross-check of the calculation angles only, never used for the times shown';

  @override
  String get srcOsm => 'Mosque locations from OpenStreetMap — ODbL, via Overpass and Nominatim';

  @override
  String get srcGooglePlaces => 'Extra mosque results when a key is present — Google Places';

  @override
  String get srcWhisper => 'Recitation checking: Whisper base-ar-quran by tarteel-ai, ONNX build by Synthesium — Apache-2.0, on-device';

  @override
  String get srcSemantic => 'Search by meaning: multilingual-e5-small by intfloat — MIT, quantised to int8 on-device';

  @override
  String get srcFonts => 'Fonts: KFGQPC Uthmanic Hafs, Amiri, Scheherazade New, IBM Plex Sans Arabic — SIL OFL';

  @override
  String get openSourceLicenses => 'Open-source licences';

  @override
  String get updateTitle => 'Updates';

  @override
  String get updateCheck => 'Check';

  @override
  String get updateIntro => 'Updates are entirely manual: nothing is checked in the background. The app reads the project\'s GitHub releases page only when you tap the button.';

  @override
  String get updateUpToDate => 'You are up to date';

  @override
  String get updateAvailable => 'New version:';

  @override
  String get updateDownload => 'Download';

  @override
  String get updateVerifying => 'Verifying the file\'s checksum…';

  @override
  String get updateInstall => 'Install';

  @override
  String get updateAllowInstall => 'Android needs your permission to install apps from this source. I will open that setting; come back and tap Install.';

  @override
  String get updateOpenSettings => 'Open settings';

  @override
  String get updateUnverified => 'The release publishes no SHA-256, so I could not verify the file. Install at your own risk.';

  @override
  String get updateNoChannel => 'This build has no update channel (no repository path was set when it was compiled).';

  @override
  String get updateFailed => 'Could not reach GitHub. Check the connection and try again.';

  @override
  String get updateRateLimited => 'GitHub is rate-limiting this network. Wait a moment and try again.';

  @override
  String get updateNoRelease => 'The repository has no published release yet.';

  @override
  String get updateChecksumFailed => 'The file\'s checksum does not match the published one — it was deleted and nothing was installed.';

  @override
  String get recitationDownloadErrorOffline => 'Could not reach the server. Check the connection and try again.';

  @override
  String get recitationDownloadErrorTimeout => 'The download timed out.';

  @override
  String get recitationDownloadErrorNotFound => 'The file is missing on the server (404).';

  @override
  String get recitationDownloadErrorBadPayload => 'The server returned an invalid file; nothing was installed.';

  @override
  String get recitationDownloadErrorUnknown => 'The download failed for an unexpected reason.';

  @override
  String get recitationDownloadRetry => 'Try again';

  @override
  String get recitationModelSizeHint => '153 MB — Wi‑Fi recommended, downloaded once.';

  @override
  String recitationDownloadedFrom(Object source) {
    return 'Source: $source';
  }

  @override
  String get updateRepoNotFound => 'Repository not found on GitHub. Check the owner/name path, or that it is public.';

  @override
  String updatePatchHint(String size) {
    return 'Small update: $size only — rebuilt on the device from the installed build.';
  }

  @override
  String get updatePatchedLocally => 'Ready — rebuilt on the device and verified against the published checksum.';

  @override
  String get silentNowTitle => 'The phone is silent now';

  @override
  String silentNowBody(String time) {
    return 'It was silenced for prayer time and will restore itself at $time.';
  }

  @override
  String get silentNowRestore => 'Restore sound now';

  @override
  String get silentNowRestored => 'The ringer is back to how it was.';

  @override
  String get locationNotDetected => 'Your location is not known yet, so nearby mosques cannot be searched.';

  @override
  String get locationDetectNow => 'Locate me';

  @override
  String radarUsingManualCity(String city) {
    return 'Mosques around $city — the location was chosen by hand.';
  }

  @override
  String get mosqueAddHere => 'Add the mosque here';

  @override
  String get mosqueAddHint => 'The mosque is saved at your current position, accurate to 10 metres.';

  @override
  String get mosqueNameOptional => 'Mosque name (optional)';

  @override
  String get mosqueAdded => 'The mosque was added to your list.';

  @override
  String get mosqueDelete => 'Delete the mosque';

  @override
  String get mosqueDeleted => 'The mosque was removed from your list.';

  @override
  String get mosqueUserTag => 'Added by you';

  @override
  String get bookNeedsRepair => 'This book was downloaded before but its text is missing. Download it again.';

  @override
  String get bookReinstall => 'Download again';

  @override
  String recitationResuming(String size) {
    return 'Resuming from $size already downloaded.';
  }

  @override
  String get bookRepairing => 'Repairing the book…';

  @override
  String get midadTitle => 'Al-Mi\'dad';

  @override
  String get midadSubtitle => 'The Qur\'an text lab';

  @override
  String get midadScopeMushaf => 'Mushaf';

  @override
  String get midadScopeSurah => 'Surah';

  @override
  String get midadScopeJuz => 'Juz';

  @override
  String get midadScopePage => 'Page';

  @override
  String get midadScopeHizb => 'Hizb';

  @override
  String get midadScopeMeccan => 'Meccan';

  @override
  String get midadScopeMedinan => 'Medinan';

  @override
  String get midadUnitLetter => 'Letter';

  @override
  String get midadUnitWord => 'Word';

  @override
  String get midadUnitAyah => 'Verse length';

  @override
  String get midadUnitFasila => 'Rhyme letter';

  @override
  String get midadProbeLetterHint => 'Type one letter…';

  @override
  String get midadProbeWordHint => 'Type a word…';

  @override
  String get midadBasmala => 'Count the basmala';

  @override
  String get midadSimpleScript => 'Simple script';

  @override
  String get midadResult => 'Result';

  @override
  String get midadCounted => 'times';

  @override
  String midadOfLetters(Object total) {
    return 'out of $total letters in this scope';
  }

  @override
  String midadOfWords(Object total) {
    return 'out of $total words in this scope';
  }

  @override
  String midadOfAyahs(Object total) {
    return 'verses end with it, out of $total verses';
  }

  @override
  String midadAvgLength(Object n) {
    return 'Average verse length: $n letters';
  }

  @override
  String get midadHeatmap => 'Where it concentrates';

  @override
  String get midadHeatmapHint => 'Each square is a surah — tap one to narrow the count to it';

  @override
  String get midadTopVerses => 'Verses where it concentrates';

  @override
  String get midadInsights => 'Curiosities';

  @override
  String get midadInsightTopLetter => 'Most frequent letter';

  @override
  String get midadInsightHapax => 'Words that occur only once';

  @override
  String get midadInsightLongest => 'Longest verse';

  @override
  String get midadInsightRarest => 'Rarest letter by spread';

  @override
  String get midadHowWeCount => 'How we count';

  @override
  String get midadHowBody => 'Counted from the bundled Uthmani text:\n\n• Letters: diacritics and pause marks are removed; the letter stays as written. “Simple script” folds ٱ أ إ آ into one alef (ا).\n• Words: whole tokens — «الله» is not counted inside «بالله». “Inside words” allows exactly that, explicitly.\n• The divine name: «الله» alone is 2,153, plus «لله» it is 2,703; the familiar 2,699 figure combines them — which is why it differs from the whole-word count.\n• Basmala: not a verse outside Al-Fatihah. The option adds its letters and words, never a verse.\n• Rhyme letter: the last written letter of the verse.\n\nEvery card carries its scope and switches, so every number is reproducible.';

  @override
  String get midadPickPlace => 'Choose a scope';

  @override
  String get midadNothing => 'Nothing in this scope';

  @override
  String get midadOpenVerse => 'Open the verse';

  @override
  String get midadLettersTotal => 'Letters of the mushaf';

  @override
  String get midadWordsTotal => 'Its words';

  @override
  String get midadVerse => 'verse';

  @override
  String get midadWordInside => 'Inside words';

  @override
  String midadOfAyahCount(Object total) {
    return 'out of $total verses in this scope';
  }

  @override
  String get mosqueFenceTitle => 'My mosque';

  @override
  String get mosqueFenceSubtitle => 'Record it while you are inside — the silence works only inside this fence, and only at prayer times.';

  @override
  String get mosqueFenceSubtitleOn => 'Silence is now limited to your mosque\'s fence, and to prayer times.';

  @override
  String get mosqueFenceRegister => 'Record this mosque';

  @override
  String get mosqueFenceRegisterHint => 'Stand inside or at the door, then tap — ten metres is enough.';

  @override
  String get mosqueFenceNameHint => 'Mosque name (optional)';

  @override
  String get mosqueFenceRadius => 'Fence radius';

  @override
  String get mosqueFenceMeterUnit => 'm';

  @override
  String mosqueFenceRadiusLabel(Object n) {
    return '$n m fence';
  }

  @override
  String mosqueFenceDistanceMeters(Object n) {
    return '$n m away';
  }

  @override
  String mosqueFenceDistanceKm(Object n) {
    return '$n km away';
  }

  @override
  String get mosqueFenceCheck => 'Check now';

  @override
  String get mosqueFenceInsideNow => 'You are inside the fence — it will silence at prayer time.';

  @override
  String mosqueFenceOutsideNow(Object n) {
    return 'You are outside the fence ($n m) — it will not silence.';
  }

  @override
  String get mosqueFenceUnknown => 'Could not read your location now; the silence will follow the usual schedule.';

  @override
  String get mosqueFenceDelete => 'Delete mosque';

  @override
  String get mosqueFenceAddAnother => 'Add another';

  @override
  String get mosqueFenceUnnamed => 'My mosque';

  @override
  String get mosqueFenceSaved => 'Saved — the silence is now limited to its fence.';

  @override
  String get mosqueFenceNeedLocation => 'Fix your location first from the button above, then record the mosque.';

  @override
  String mosqueFenceAccuracy(Object n) {
    return 'Your fix is ±$n m right now.';
  }

  @override
  String get mosqueFenceNeedsBackground => 'To work with the app closed it needs the “allow all the time” location permission.';

  @override
  String mosqueAccuracyLine(Object n) {
    return 'Location accuracy ±$n m — the smaller, the truer.';
  }

  @override
  String mosqueAccuracyPoor(Object n) {
    return 'Your location is coarse (±$n m). Tap the location button above while you are at the place itself.';
  }

  @override
  String get mosqueFixNow => 'Refresh location';

  @override
  String get mosqueFenceFallbackNote => 'If the location cannot be read at the adhan, the silence follows the usual schedule rather than missing it.';

  @override
  String get adhkarTitle => 'Adhkar';

  @override
  String get adhkarReport => 'Monthly report';

  @override
  String get adhkarReminders => 'Reminder times';

  @override
  String get adhkarMorning => 'Morning';

  @override
  String get adhkarEvening => 'Evening';

  @override
  String get adhkarMorningDone => 'Morning adhkar done — evening is next';

  @override
  String get adhkarEveningDone => 'Evening adhkar done — see you at dawn';

  @override
  String adhkarProgressOf(int done, int total) {
    return '$done of $total';
  }

  @override
  String get adhkarListen => 'Listen';

  @override
  String get adhkarReset => 'Reset';

  @override
  String get adhkarTapToExpand => 'Tap to read it in full';

  @override
  String get adhkarPlay => 'Play';

  @override
  String get adhkarDone => 'Done';

  @override
  String get adhkarCount => 'Count';

  @override
  String get adhkarRemindersBody => 'Two daily nudges for morning and evening, working with the app closed.';

  @override
  String get adhkarRemindersEnable => 'Enable reminders';

  @override
  String get adhkarMorningReminderTitle => 'Morning adhkar';

  @override
  String get adhkarMorningReminderBody => 'Time for the morning adhkar — twenty-four remembrances.';

  @override
  String get adhkarEveningReminderTitle => 'Evening adhkar';

  @override
  String get adhkarEveningReminderBody => 'Time for the evening adhkar — twenty-four remembrances.';

  @override
  String get adhkarReminderSaved => 'Reminders saved.';

  @override
  String get adhkarReminderOff => 'Reminders stopped.';

  @override
  String get adhkarPlayerFinished => 'All done — may Allah accept it.';

  @override
  String get adhkarCarMode => 'Car mode';

  @override
  String get adhkarAutoNextOn => 'Auto-advance is on';

  @override
  String get adhkarAutoNextOff => 'Manual advance';

  @override
  String get adhkarMorningDays => 'Days with morning done';

  @override
  String get adhkarEveningDays => 'Days with evening done';

  @override
  String get adhkarBothDays => 'Days with both';

  @override
  String get adhkarAverage => 'Average completion';

  @override
  String get adhkarLegendNone => 'Nothing';

  @override
  String get adhkarLegendHalf => 'Half';

  @override
  String get adhkarLegendFull => 'Complete';

  @override
  String get weekdaySun => 'S';

  @override
  String get weekdayMon => 'M';

  @override
  String get weekdayTue => 'T';

  @override
  String get weekdayWed => 'W';

  @override
  String get weekdayThu => 'T';

  @override
  String get weekdayFri => 'F';

  @override
  String get weekdaySat => 'S';

  @override
  String get adhkarAudioTitle => 'Listen offline';

  @override
  String get adhkarAudioBody => 'The audio downloads on request: twenty-four files, about thirty megabytes. Without it, listening streams from the internet.';

  @override
  String adhkarAudioCount(int done, int total) {
    return '$done of $total clips on the device';
  }

  @override
  String get adhkarAudioDownload => 'Download the audio';

  @override
  String get adhkarAudioDelete => 'Delete';
}
