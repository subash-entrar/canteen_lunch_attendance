import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _apiMonth = DateFormat('yyyy-MM');
  static final DateFormat _displayDate = DateFormat('dd MMM yyyy');
  static final DateFormat _displayDay = DateFormat('EEE, dd MMM');
  static final DateFormat _displayMonth = DateFormat('MMMM yyyy');
  static final DateFormat _displayDayMonth = DateFormat('dd MMM');
  static final DateFormat _displayMonthShort = DateFormat('MMM yy');

  static String toApiDate(DateTime date) => _apiDate.format(date);
  static String toApiMonth(DateTime date) => _apiMonth.format(date);
  static String toDisplayDate(DateTime date) => _displayDate.format(date);
  static String toDisplayDay(DateTime date) => _displayDay.format(date);
  static String toDisplayMonth(DateTime date) => _displayMonth.format(date);
  static String toDisplayDayMonth(DateTime date) =>
      _displayDayMonth.format(date);
  static String toDisplayMonthShort(DateTime date) =>
      _displayMonthShort.format(date);

  static final DateFormat _displayTime = DateFormat('h:mm a');
  static final DateFormat _displayDateTime = DateFormat('dd MMM yyyy, h:mm a');

  static String toDisplayTime(DateTime date) => _displayTime.format(date);
  static String toDisplayDateTime(DateTime date) =>
      _displayDateTime.format(date);

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Inclusive range ending today for the last [days] calendar days.
  static ({DateTime from, DateTime to}) lastDaysRange(int days) {
    final to = today();
    final from = to.subtract(Duration(days: days - 1));
    return (from: from, to: to);
  }

  static DateTime? tryParseApiDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return _apiDate.parseStrict(value.trim());
    } catch (_) {
      return DateTime.tryParse(value.trim());
    }
  }

  static DateTime? tryParseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));
  }
}
