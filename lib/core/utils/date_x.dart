import 'package:hijri/hijri_calendar.dart';

/// Manual, dependency-free date formatting.
///
/// `intl`'s locale data for Arabic is only guaranteed after the localizations
/// delegate loads, and the app formats dates in background isolates too — so
/// the tables live here, deterministically, in both languages.

const List<String> _hijriMonthsAr = <String>[
  'محرّم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوّال',
  'ذو القعدة',
  'ذو الحجة',
];

const List<String> _hijriMonthsEn = <String>[
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Thani",
  'Jumada al-Ula',
  'Jumada al-Akhirah',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qi'dah",
  'Dhu al-Hijjah',
];

const List<String> _monthsAr = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> _monthsEn = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdaysAr = <String>[
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> _weekdaysEn = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String monthName(int month, String localeCode) =>
    (localeCode == 'ar' ? _monthsAr : _monthsEn)[(month - 1).clamp(0, 11)];

String weekdayName(DateTime date, String localeCode) =>
    (localeCode == 'ar' ? _weekdaysAr : _weekdaysEn)[date.weekday - 1];

String hijriMonthName(int month, String localeCode) =>
    (localeCode == 'ar' ? _hijriMonthsAr : _hijriMonthsEn)[(month - 1).clamp(0, 11)];

/// e.g. `12 ربيع الأول 1447 هـ` / `12 Rabi' al-Awwal 1447 AH`.
String hijriLabel(
  DateTime date, {
  required String localeCode,
  int offsetDays = 0,
}) {
  final HijriCalendar hijri = HijriCalendar.fromDate(
    // Shift by calendar fields; `date + Duration(days: n)` would land on the
    // wrong date next to a DST transition (23:00 the previous day).
    DateTime(
      date.year,
      date.month,
      date.day + offsetDays,
      date.hour,
      date.minute,
      date.second,
    ),
  );
  final String month = hijriMonthName(hijri.hMonth, localeCode);
  return localeCode == 'ar'
      ? '${hijri.hDay} $month ${hijri.hYear} هـ'
      : '${hijri.hDay} $month ${hijri.hYear} AH';
}

/// e.g. `الجمعة 10 أكتوبر 2026` / `Friday 10 October 2026`.
String gregorianLabel(DateTime date, String localeCode) {
  final String weekday = weekdayName(date, localeCode);
  final String month = monthName(date.month, localeCode);
  return '$weekday ${date.day} $month ${date.year}';
}

/// Short form used in tables: `10 أكتوبر`.
String shortDate(DateTime date, String localeCode) =>
    '${date.day} ${monthName(date.month, localeCode)}';

/// hh:mm with seconds only when needed.
String clockLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

String countdownLabel(Duration duration, String localeCode) {
  final Duration d = duration.isNegative ? Duration.zero : duration;
  final String hh = d.inHours.toString().padLeft(2, '0');
  final String mm = (d.inMinutes % 60).toString().padLeft(2, '0');
  final String ss = (d.inSeconds % 60).toString().padLeft(2, '0');
  // A plain colon: digits form an LTR run and a colon between digits is a
  // "common separator", so bidi keeps the pair intact even inside an RTL line —
  // no need for the spaced-out form.
  const String separator = ':';
  return d.inHours > 0
      ? '$hh$separator$mm$separator$ss'
      : '$mm$separator$ss';
}

/// Walking / driving-ish duration for the mosque radar.
String humanDuration(Duration duration, String localeCode) {
  final int minutes = duration.inMinutes;
  if (minutes < 60) {
    return localeCode == 'ar' ? '$minutes دقيقة' : '$minutes min';
  }
  final int hours = minutes ~/ 60;
  final int rest = minutes % 60;
  if (localeCode == 'ar') {
    return rest == 0 ? '$hours ساعة' : '$hours ساعة و$rest دقيقة';
  }
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

String humanDistance(double meters, String localeCode) {
  if (meters < 1000) {
    return '${meters.round()} ${localeCode == 'ar' ? 'م' : 'm'}';
  }
  final String value = (meters / 1000).toStringAsFixed(1);
  return '$value ${localeCode == 'ar' ? 'كم' : 'km'}';
}
