import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'أَوَان';

  @override
  String get appFullName => 'أَوَان | مواقيت الصلاة والقرآن';

  @override
  String get tagline => 'سكينة للروح';

  @override
  String get ok => 'حسناً';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get error => 'حدث خطأ ما';

  @override
  String get close => 'إغلاق';

  @override
  String get search => 'بحث';

  @override
  String get searchHint => 'ابحث…';

  @override
  String get done => 'تم';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get offline => 'بدون إنترنت';

  @override
  String get online => 'متصل';

  @override
  String get sync => 'مزامنة';

  @override
  String get version => 'الإصدار';

  @override
  String get about => 'عن التطبيق';

  @override
  String get share => 'مشاركة';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ';

  @override
  String get open => 'فتح';

  @override
  String get back => 'رجوع';

  @override
  String get delete => 'حذف';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'نهاري';

  @override
  String get themeDark => 'ليلي';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get minutesShort => 'د';

  @override
  String get secondsShort => 'ث';

  @override
  String get hoursShort => 'س';

  @override
  String get km => 'كم';

  @override
  String get meter => 'م';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingNoon => 'السلام عليكم';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get remaining => 'المتبقي';

  @override
  String prayerIn(String time) {
    return 'بعد $time';
  }

  @override
  String get prayerNow => 'حان وقت الصلاة';

  @override
  String get todayPrayers => 'صلوات اليوم';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get adhan => 'الأذان';

  @override
  String get prayerTimetable => 'جدول المواقيت';

  @override
  String get monthlyTimetable => 'جدول الشهر';

  @override
  String get qibla => 'القبلة';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String qiblaDegrees(String degrees) {
    return '$degrees° من الشمال';
  }

  @override
  String get hijriDate => 'التاريخ الهجري';

  @override
  String get gregorianDate => 'التاريخ الميلادي';

  @override
  String get hijriOffset => 'تعديل التاريخ الهجري (أيام)';

  @override
  String get location => 'الموقع';

  @override
  String get locationAuto => 'تلقائي (موقع الجهاز)';

  @override
  String get locationManual => 'يدوي (اختر مدينة)';

  @override
  String get detectLocation => 'تحديد موقعي';

  @override
  String get latitude => 'خط العرض';

  @override
  String get longitude => 'خط الطول';

  @override
  String get cityName => 'اسم المدينة';

  @override
  String get locationDenied => 'تحتاج مواقيت الصلاة إلى إذن الموقع لحسابها لمدينتك.';

  @override
  String get locationUnavailable => 'لم نتمكن من قراءة موقع الجهاز. اختر مدينتك يدوياً.';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get madhab => 'مذهب العصر';

  @override
  String get madhabShafi => 'الشافعي / المالكي / الحنبلي';

  @override
  String get madhabHanafi => 'الحنفي';

  @override
  String get highLatitudeRule => 'قاعدة خطوط العرض العليا';

  @override
  String get highLatitudeMiddle => 'منتصف الليل';

  @override
  String get highLatitudeSeventh => 'سُبع الليل';

  @override
  String get highLatitudeTwilight => 'بالزاوية';

  @override
  String get prayerAdjustments => 'تعديلات يدوية (دقائق)';

  @override
  String get methodMWL => 'رابطة العالم الإسلامي';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodUmmAlQura => 'أم القرى (مكة المكرمة)';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية بكراتشي';

  @override
  String get methodNorthAmerica => 'الجمعية الإسلامية لأمريكا الشمالية';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodDubai => 'دبي';

  @override
  String get methodTurkey => 'تركيا (ديانت)';

  @override
  String get methodTehran => 'طهران';

  @override
  String get methodSingapore => 'سنغافورة';

  @override
  String get methodOther => 'أخرى';

  @override
  String get verifyOnline => 'التحقق من الزوايا عبر الإنترنت';

  @override
  String get verifyOk => 'الحساب المحلي مطابق للمرجع';

  @override
  String verifyDiff(String minutes) {
    return 'فرق $minutes دقيقة عن المرجع — راجع طريقة الحساب';
  }

  @override
  String lastVerified(String date) {
    return 'آخر تحقق $date';
  }

  @override
  String get quran => 'القرآن';

  @override
  String get surahs => 'السور';

  @override
  String get meccan => 'مكية';

  @override
  String get medinan => 'مدنية';

  @override
  String ayahCount(int count) {
    return '$count آية';
  }

  @override
  String get searchQuran => 'البحث في القرآن';

  @override
  String get searchQuranHint => 'اكتب كلمة أو جزءاً من آية';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String resultsCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get bookmark => 'علامة';

  @override
  String get bookmarks => 'العلامات';

  @override
  String get addBookmark => 'إضافة علامة';

  @override
  String get removeBookmark => 'إزالة العلامة';

  @override
  String get bookmarkAdded => 'تمت إضافة العلامة';

  @override
  String get bookmarkRemoved => 'تمت إزالة العلامة';

  @override
  String get lastRead => 'آخر قراءة';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get quranFont => 'خط المصحف';

  @override
  String get scriptUthmani => 'الرسم العثماني (أميري قرآن)';

  @override
  String get scriptScheherazade => 'شهرزاد الجديد';

  @override
  String get nightReadingMode => 'وضع القراءة الليلية';

  @override
  String get tafsir => 'التفسير';

  @override
  String get showTafsir => 'إظهار التفسير';

  @override
  String get tafsirUnavailable => 'لا يوجد تفسير محمّل لهذه الآية';

  @override
  String get jumpToAyah => 'الانتقال إلى آية';

  @override
  String get ayah => 'آية';

  @override
  String get surah => 'سورة';

  @override
  String get page => 'صفحة';

  @override
  String get juz => 'جزء';

  @override
  String get copyAyah => 'نسخ الآية';

  @override
  String get shareAyah => 'مشاركة الآية';

  @override
  String get tafsirPackages => 'حزم التفسير';

  @override
  String get tafsirPackagesDesc => 'تُحمّل مرة واحدة وتبقى على جهازك للعمل دون إنترنت.';

  @override
  String get bundledPackage => 'مضمّنة';

  @override
  String get installPackage => 'تثبيت';

  @override
  String get installing => 'جارٍ التثبيت…';

  @override
  String get installed => 'مثبّتة';

  @override
  String get uninstall => 'إزالة';

  @override
  String packageSize(String size) {
    return '$size ك.ب';
  }

  @override
  String get mosqueRadar => 'رادار المساجد';

  @override
  String get nearbyMosques => 'المساجد القريبة';

  @override
  String get nearestMosques => 'أقرب المساجد';

  @override
  String walkingTime(String time) {
    return '$time سيراً على الأقدام';
  }

  @override
  String get refresh => 'تحديث';

  @override
  String get mosque => 'مسجد';

  @override
  String get noMosquesFound => 'لم نعثر على مساجد قريبة';

  @override
  String get placesKeyMissing => 'أضف مفتاح Google Places لاستخدام نتائج جوجل، وتُستخدم بيانات OpenStreetMap حالياً.';

  @override
  String get cacheHint => 'تُحفظ النتائج 48 ساعة لتقليل استهلاك البيانات والبطارية';

  @override
  String get map => 'الخريطة';

  @override
  String get list => 'القائمة';

  @override
  String get library => 'المكتبة';

  @override
  String get maktabaSubtitle => 'المكتبة الشاملة';

  @override
  String get catalog => 'الفهرس';

  @override
  String get myBooks => 'كتبي';

  @override
  String get downloadBook => 'تحميل';

  @override
  String get downloadStarted => 'بدأ التحميل';

  @override
  String get bookImported => 'تم استيراد الكتاب بنجاح';

  @override
  String get importFile => 'استيراد من ملف';

  @override
  String get importUrl => 'استيراد من رابط';

  @override
  String get bookSearch => 'ابحث عن كتاب أو مؤلف';

  @override
  String get noBooks => 'لا توجد كتب بعد. حمّل كتاباً من الفهرس أو استورد ملفاً.';

  @override
  String get parserIsolate => 'تتم المعالجة في الخلفية لتبقى الواجهة سلسة';

  @override
  String get librarySource => 'مصدر المكتبة';

  @override
  String get sourceShamela => 'المكتبة الشاملة';

  @override
  String get sourceOpenIti => 'متن OpenITI';

  @override
  String get sourceLocal => 'ملفات الجهاز';

  @override
  String get readingProgress => 'نسبة التقدم';

  @override
  String get settings => 'الإعدادات';

  @override
  String get display => 'العرض';

  @override
  String get elderlyMode => 'وضع كبار السن';

  @override
  String get elderlyModeDesc => 'تكبير النص 150%، وثلاث بطاقات كبيرة، وإلغاء الإيماءات المعقدة.';

  @override
  String get textScale => 'مقياس النص';

  @override
  String get simpleMode => 'الوضع المبسّط';

  @override
  String get moreFeatures => 'مزيد من الميزات';

  @override
  String get notifications => 'التنبيهات';

  @override
  String get adhanNotifications => 'تنبيهات الأذان';

  @override
  String get notificationsEnabled => 'التنبيهات مُفعّلة';

  @override
  String get notificationsDenied => 'إذن التنبيهات مرفوض';

  @override
  String get vibrate => 'اهتزاز';

  @override
  String get playSound => 'صوت التنبيه';

  @override
  String get silentMode => 'الصامت التلقائي';

  @override
  String get silentModeDesc => 'إسكات الهاتف قبل الأذان وإعادته بعده (أندرويد).';

  @override
  String get silentModePermission => 'منح صلاحية وضع عدم الإزعاج';

  @override
  String muteBeforeMinutes(int count) {
    return 'الإسكات قبل $count دقيقة';
  }

  @override
  String unmuteAfterMinutes(int count) {
    return 'الإعادة بعد $count دقيقة';
  }

  @override
  String get fridaySchedule => 'صلاة الجمعة';

  @override
  String get fridayScheduleDesc => 'إسكات من 11:30 حتى 13:30 (قابل للتخصيص).';

  @override
  String get fridayStart => 'البداية';

  @override
  String get fridayEnd => 'النهاية';

  @override
  String get iosSilentNotice => 'لا تسمح آبل للتطبيقات بإسكات الجهاز، ويُرسل تنبيه لتشغيل وضع التركيز بدلاً من ذلك.';

  @override
  String get backgroundTasks => 'المزامنة في الخلفية';

  @override
  String get backgroundSyncDesc => 'تُتحقق زوايا الحساب مرة أسبوعياً في الخلفية دون استهلاك ملحوظ للبطارية.';

  @override
  String get tasbih => 'السبحة';

  @override
  String get tasbihCount => 'العدّ';

  @override
  String get tasbihTarget => 'الهدف';

  @override
  String get tasbihReset => 'تصفير';

  @override
  String get tasbihSaved => 'محفوظ';

  @override
  String get seasonGreeting => 'تقبّل الله طاعتكم';

  @override
  String get addons => 'الإضافات';

  @override
  String get dataSources => 'مصادر البيانات';

  @override
  String get dataSourcesDesc => 'المواقيت: adhan_dart محلياً + Aladhan API للتحقق. الأماكن: Google Places / OpenStreetMap. نص القرآن: مصحف Tanzil العثماني عبر quran.com. التفسير: جامعة الملك سعود / quran.com.';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get privacyDesc => 'موقعك وعلاماتك وكتبك المحمّلة تبقى على جهازك. لا حساب ولا تتبّع.';

  @override
  String get licenses => 'تراخيص المصادر المفتوحة';

  @override
  String get aboutDesc => 'تطبيق إسلامي شامل يعمل دون إنترنت، يراعي السكينة والسرعة وعمر البطارية.';

  @override
  String get elderlyModeOn => 'وضع كبار السن مُفعّل';

  @override
  String get turnOffElderly => 'إيقافه';

  @override
  String get permissionNeeded => 'يلزم منح الإذن';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get noNetwork => 'لا يوجد اتصال بالإنترنت — يتم عرض البيانات المحفوظة';

  @override
  String get cachedResults => 'نتائج محفوظة';

  @override
  String updated(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get tomorrow => 'غداً';

  @override
  String get yesterday => 'أمس';

  @override
  String get today => 'اليوم';

  @override
  String get weekdaysShort => 'الإثنين,الثلاثاء,الأربعاء,الخميس,الجمعة,السبت,الأحد';

  @override
  String get zeroCount => '٠';

  @override
  String adhanScheduled(int count) {
    return 'تمت جدولة $count إشعار صلاة قادم';
  }

  @override
  String get adhanCancelled => 'أُلغيت كل إشعارات الصلاة';

  @override
  String get silentNeedsPolicy => 'الصمت التلقائي يحتاج صلاحية «لا تُزعج»';

  @override
  String silentScheduled(int count) {
    return 'جُدِّدت أوقات الصمت لـ$count يومًا';
  }

  @override
  String scheduledCount(int count) {
    return 'عدد الإشعارات المجدولة: $count';
  }

  @override
  String get compassUnavailable => 'هذا الجهاز بلا بوصلة (مغناطيسية)، لذا يبقى القرص موجّهاً للشمال. والزاوية أدناه دقيقة.';

  @override
  String get qiblaAligned => 'أنت متجه إلى القبلة';

  @override
  String turnRight(int degrees) {
    return 'أدر $degrees° يميناً';
  }

  @override
  String turnLeft(int degrees) {
    return 'أدر $degrees° يساراً';
  }

  @override
  String toMakkah(String km) {
    return '$km كم إلى مكة المكرمة';
  }

  @override
  String get compassCalibration => 'حرّك الهاتف على شكل رقم ٨ لمعايرة البوصلة';

  @override
  String get bearingFromTrueNorth => 'الزاوية مقيسة من الشمال الحقيقي';

  @override
  String get liveCompass => 'بوصلة حية';

  @override
  String declinationCorrection(String degrees) {
    return 'تصحيح الانحراف المغناطيسي: $degrees°';
  }

  @override
  String get elderlyQibla => 'اتجه إلى هذا الاتجاه';

  @override
  String get dataFromGoogle => 'بيانات Google Places';

  @override
  String get dataFromOsm => 'بيانات OpenStreetMap';

  @override
  String get dataFromCache => 'من الذاكرة المحلية (أحدث من ٤٨ ساعة)';

  @override
  String searchRadius(String km) {
    return 'نطاق البحث $km كم';
  }

  @override
  String get nearestMosque => 'أقرب مسجد';

  @override
  String get navigateToNearest => 'الانتقال إلى أقرب مسجد';

  @override
  String get openInMaps => 'افتح في الخرائط';

  @override
  String get useMyLocation => 'حدِّد موقعي';

  @override
  String get metersShort => 'م';

  @override
  String get navigateShort => 'الاتجاهات';

  @override
  String get timeSection => 'الوقت';

  @override
  String get daylightSaving => 'التوقيت الصيفي والشتوي';

  @override
  String get dstAuto => 'تلقائي (حسب الجهاز)';

  @override
  String get dstAutoDesc => 'نثق في توقيت الجهاز — وهو الصحيح لمعظم البلدان.';

  @override
  String get dstPlusOne => 'ساعة صيفية (+1)';

  @override
  String get dstPlusOneDesc => 'كل المواقيت والتنبيهات تُقدَّم ساعة واحدة.';

  @override
  String get dstMinusOne => 'ساعة شتوية (−1)';

  @override
  String get dstMinusOneDesc => 'كل المواقيت والتنبيهات تُؤخَّر ساعة واحدة.';

  @override
  String get dstDeviceFixed => 'جهازك لا يغيّر توقيته خلال السنة';

  @override
  String get dstDeviceOnSummer => 'جهازك الآن على التوقيت الصيفي';

  @override
  String get dstDeviceStandard => 'جهازك الآن على التوقيت الشتوي';

  @override
  String get dstNote => 'لبلدان فيها توقيت صيفي وشتوي: إن لم يطبّق جهازك توقيت بلدك (أو كانت قواعد التوقيت فيه قديمة) فاضبطها من هنا. التصحيح يشمل الوقت المعروض وموعد تنبيه الأذان معاً حتى لا يختلفا، ولا يمسّ حساب المواقيت فلكياً.';

  @override
  String get quranTitle => 'القرآن الكريم';

  @override
  String get startReading => 'ابدأ القراءة';

  @override
  String get continueButton => 'متابعة';

  @override
  String get surahIndex => 'فهرس السور';

  @override
  String get stopMarker => 'علامة الوقوف';

  @override
  String get stopMarkerSet => 'تم وضع علامة الوقوف';

  @override
  String get stopMarkerCleared => 'تم مسح علامة الوقوف';

  @override
  String get noStopMarker => 'لم تُحدَّد علامة وقوف بعد — اضغط أيقونة العلامة أثناء القراءة.';

  @override
  String get goToStopMarker => 'اذهب إليها';

  @override
  String get setStopHere => 'ضع علامة الوقوف هنا';

  @override
  String get searchNoResults => 'لا نتائج';

  @override
  String get searchOffline => 'البحث يعمل بدون إنترنت';

  @override
  String get bookmarksTitle => 'المحفوظات';

  @override
  String get noBookmarks => 'لا محفوظات بعد';

  @override
  String get readingSettings => 'إعدادات القراءة';

  @override
  String get ayahFontSize => 'حجم الآيات';

  @override
  String get tafsirFontSize => 'حجم التفسير';

  @override
  String get screenColour => 'لون الشاشة';

  @override
  String get palettePaper => 'ورقي';

  @override
  String get paletteSepia => 'بني فاتح';

  @override
  String get paletteDark => 'ليلي';

  @override
  String get paletteOled => 'أسود صافٍ';

  @override
  String get readerMode => 'طريقة العرض';

  @override
  String get modePages => 'صفحات المصحف';

  @override
  String get modeSurah => 'سورة متصلة';

  @override
  String get makki => 'مكية';

  @override
  String get madani => 'مدنية';

  @override
  String get ayahWord => 'آية';

  @override
  String get sajdaAyah => 'آية سجدة';

  @override
  String get prePrayerReminder => 'تنبيه قبل الصلاة';

  @override
  String get prePrayerHint => 'ساعة رمل تظهر قبل الأذان وتختفي بلمسة ولو لم تلمسها تختفي مع الأذان';

  @override
  String get prePrayerLead => 'قبل الموعد بـ';

  @override
  String get prePrayerSound => 'صوت خفيف';

  @override
  String get prePrayerSoundHint => 'رنة قصيرة مع التنبيه بدل الصمت';

  @override
  String reminderSoonOne(Object prayer) {
    return 'باقي دقيقة على $prayer';
  }

  @override
  String reminderSoonTwo(Object prayer) {
    return 'باقي دقيقتان على $prayer';
  }

  @override
  String reminderSoonFew(Object minutes, Object prayer) {
    return 'باقي $minutes دقائق على $prayer';
  }

  @override
  String reminderSoonMany(Object minutes, Object prayer) {
    return 'باقي $minutes دقيقة على $prayer';
  }

  @override
  String reminderPrepare(String prayer) {
    return 'تجهّز لصلاة $prayer';
  }

  @override
  String get libraryTitle => 'المكتبة';

  @override
  String get librarySubtitle => 'كتب عربية للقراءة دون اتصال';

  @override
  String get libraryDiscover => 'تصفّح';

  @override
  String get libraryShelf => 'مكتبتي';

  @override
  String get librarySearchHint => 'ابحث في العنوان أو المؤلف';

  @override
  String get libraryAllCategories => 'كل التصنيفات';

  @override
  String get librarySync => 'تحديث الفهرس';

  @override
  String get librarySyncing => 'جارٍ تحديث الفهرس…';

  @override
  String get librarySynced => 'الفهرس محدَّث';

  @override
  String librarySyncedDetail(int added, int total) {
    return 'أُضيف $added كتاب · الإجمالي $total';
  }

  @override
  String get librarySyncFailed => 'تعذّر تحديث الفهرس';

  @override
  String get libraryOfflineCached => 'لا اتصال — تُعرض النسخة المحفوظة';

  @override
  String get libraryIndexEmpty => 'الفهرس فارغ';

  @override
  String get libraryIndexEmptyHint => 'حدّث الفهرس لجلب قائمة الكتب، ثم حمّل ما تريد قراءته.';

  @override
  String get libraryNoResults => 'لا نتائج مطابقة';

  @override
  String get libraryShelfEmpty => 'لم تحمّل أي كتاب بعد';

  @override
  String get libraryShelfEmptyHint => 'الكتب المحمّلة تُقرأ كاملة دون اتصال.';

  @override
  String get libraryInstall => 'تحميل';

  @override
  String libraryInstalling(int percent) {
    return 'جارٍ التحميل · $percent٪';
  }

  @override
  String libraryUnpacking(int percent) {
    return 'جارٍ التجهيز · $percent٪';
  }

  @override
  String get libraryInstalled => 'محمَّل';

  @override
  String get libraryRead => 'قراءة';

  @override
  String get libraryContinue => 'متابعة القراءة';

  @override
  String get libraryRemove => 'حذف النسخة المحمّلة';

  @override
  String libraryRemoveQuestion(String title) {
    return 'حذف «$title» من الجهاز؟';
  }

  @override
  String get libraryRemoveHint => 'يبقى الكتاب في الفهرس، ويمكن تحميله مرة أخرى.';

  @override
  String get libraryCancel => 'إلغاء';

  @override
  String get libraryRetry => 'إعادة المحاولة';

  @override
  String get librarySourceHint => 'عنوان خادم الفهرس (https://…)';

  @override
  String get librarySourceSaved => 'تم حفظ المصدر';

  @override
  String get librarySourceInvalid => 'العنوان غير صالح';

  @override
  String get libraryCancelInstall => 'إيقاف التحميل';

  @override
  String libraryLastSync(String when) {
    return 'آخر تحديث: $when';
  }

  @override
  String get libraryNever => 'لم يُحدَّث بعد';

  @override
  String libraryBooksCount(int count) {
    return '$count كتاب';
  }

  @override
  String libraryChaptersCount(int count) {
    return '$count مقطع';
  }

  @override
  String librarySizeKb(int kb) {
    return '$kb ك.ب';
  }

  @override
  String libraryAuthorDied(int year) {
    return 'ت $yearهـ';
  }

  @override
  String get libraryCategoryLabel => 'التصنيف';

  @override
  String get readerTitle => 'قارئ المكتبة';

  @override
  String get readerFontSize => 'حجم الخط';

  @override
  String get readerNight => 'وضع ليلي';

  @override
  String get readerChapterLabel => 'فصل';

  @override
  String readerPageLabel(String page) {
    return 'ص $page';
  }

  @override
  String get readerBackToTop => 'إلى أول الكتاب';

  @override
  String get libraryShortcutEmpty => 'حمّل كتبك للقراءة دون اتصال';

  @override
  String libraryShortcutShelf(int count) {
    return '$count كتاب على جهازك';
  }

  @override
  String libraryShortcutLastRead(String title) {
    return 'آخر قراءة: $title';
  }

  @override
  String get commonClose => 'إغلاق';
}
