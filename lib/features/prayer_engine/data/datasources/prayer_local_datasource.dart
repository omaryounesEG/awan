import 'package:isar/isar.dart';

import 'package:awan/core/services/isar_service.dart';
import 'package:awan/features/prayer_engine/data/models/cached_prayer_day.dart';
import 'package:awan/features/prayer_engine/domain/entities/prayer_entities.dart';
import 'package:awan/features/prayer_engine/domain/usecases/calculate_prayer_times.dart';

/// Local data source of the prayer engine: the calculation plus its Isar cache.
class PrayerLocalDatasource {
  PrayerLocalDatasource(this._isarService, this._calculator);

  final IsarService _isarService;
  final CalculatePrayerTimes _calculator;

  Isar get _db => _isarService.isar;

  static const List<PrayerName> _order = <PrayerName>[
    PrayerName.fajr,
    PrayerName.sunrise,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  ];

  DayPrayerTimes compute(DateTime date, PrayerCalcSpec spec) =>
      _calculator.forDate(date: date, spec: spec);

  List<DayPrayerTimes> computeMonth(int year, int month, PrayerCalcSpec spec) =>
      _calculator.forMonth(year: year, month: month, spec: spec);

  Future<DayPrayerTimes?> cached(DateTime date, PrayerCalcSpec spec) async {
    final String key = '${DayPrayerTimes.dayKey(date)}|${spec.cacheKeyPart}';
    final CachedPrayerDay? row =
        await _db.cachedPrayerDays.filter().keyEqualTo(key).findFirst();
    return row == null ? null : _toEntity(row, spec);
  }

  Future<void> store(DayPrayerTimes day, {int? verifiedDiffMinutes}) async {
    await _db.writeTxn(
      () => _db.cachedPrayerDays.put(
        _toRow(day, verifiedDiffMinutes: verifiedDiffMinutes),
      ),
    );
  }

  Future<void> storeAll(Iterable<DayPrayerTimes> days) async {
    await _db.writeTxn(() async {
      for (final DayPrayerTimes day in days) {
        await _db.cachedPrayerDays.put(_toRow(day));
      }
    });
  }

  /// Cached days of a month that match the current calculation spec.
  Future<Map<String, DayPrayerTimes>> cachedMonth(
    int year,
    int month,
    PrayerCalcSpec spec,
  ) async {
    final DateTime start = DateTime(year, month, 1);
    final DateTime end = DateTime(year, month + 1, 1);
    final List<CachedPrayerDay> rows = await _db.cachedPrayerDays
        .filter()
        .dateGreaterThan(start.subtract(const Duration(days: 1)))
        .and()
        .dateLessThan(end)
        .findAll();

    final Map<String, DayPrayerTimes> out = <String, DayPrayerTimes>{};
    for (final CachedPrayerDay row in rows) {
      if (!row.key.endsWith(spec.cacheKeyPart)) continue;
      out[row.key] = _toEntity(row, spec);
    }
    return out;
  }

  Future<void> prune({int keepDays = 400}) async {
    final DateTime cutoff = DateTime.now().subtract(Duration(days: keepDays));
    await _db.writeTxn(
      () => _db.cachedPrayerDays.filter().dateLessThan(cutoff).deleteAll(),
    );
  }

  CachedPrayerDay _toRow(DayPrayerTimes day, {int? verifiedDiffMinutes}) {
    return CachedPrayerDay()
      ..key = day.cacheKey()
      ..date = day.date
      ..times = <int>[
        for (final PrayerName name in _order) day.times[name]!.millisecondsSinceEpoch,
      ]
      ..latitude = day.spec.latitude
      ..longitude = day.spec.longitude
      ..method = day.spec.method.key
      ..madhab = day.spec.madhab.key
      ..computedAt = day.computedAt
      ..verifiedDiffMinutes = verifiedDiffMinutes ?? day.verifiedDiffMinutes;
  }

  DayPrayerTimes _toEntity(CachedPrayerDay row, PrayerCalcSpec spec) {
    final Map<PrayerName, DateTime> times = <PrayerName, DateTime>{};
    for (int i = 0; i < _order.length && i < row.times.length; i++) {
      times[_order[i]] = DateTime.fromMillisecondsSinceEpoch(row.times[i]);
    }
    return DayPrayerTimes(
      date: row.date,
      times: times,
      spec: spec,
      computedAt: row.computedAt,
      verifiedDiffMinutes: row.verifiedDiffMinutes,
    );
  }
}
