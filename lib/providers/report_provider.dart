import 'package:flutter/foundation.dart';

import '../core/utils/app_date_utils.dart';
import '../models/daily_report_model.dart';
import '../models/monthly_report_model.dart';
import '../models/student_model.dart';
import '../services/lunch_attendance_service.dart';
import 'attendance_provider.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({LunchAttendanceService? service})
      : _service = service ?? LunchAttendanceService.create();

  final LunchAttendanceService _service;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  MonthlyLunchReport? _monthlyReport;
  DailyLunchReport? _dailyReport;
  bool _isLoadingMonthly = false;
  bool _isLoadingDaily = false;
  String? _monthlyError;
  String? _dailyError;

  AttendanceFilter _dailyStatusFilter = AttendanceFilter.pending;
  PaymentFilter _dailyPaymentFilter = PaymentFilter.all;
  String _dailySearchQuery = '';
  StudentSortOrder _dailySortOrder = StudentSortOrder.none;
  final Set<String> _dailySelectedSections = {};

  /// When true, later dates appear first (month end → start).
  bool _monthlyNewestFirst = true;

  /// True after attendance changes until reports are refreshed.
  bool _monthlyStale = false;

  DateTime get selectedMonth => _selectedMonth;
  String get selectedMonthApi => AppDateUtils.toApiMonth(_selectedMonth);
  MonthlyLunchReport? get monthlyReport => _monthlyReport;
  DailyLunchReport? get dailyReport => _dailyReport;
  bool get isLoadingMonthly => _isLoadingMonthly;
  bool get isLoadingDaily => _isLoadingDaily;
  String? get monthlyError => _monthlyError;
  String? get dailyError => _dailyError;

  AttendanceFilter get dailyStatusFilter => _dailyStatusFilter;
  PaymentFilter get dailyPaymentFilter => _dailyPaymentFilter;
  String get dailySearchQuery => _dailySearchQuery;
  StudentSortOrder get dailySortOrder => _dailySortOrder;
  Set<String> get dailySelectedSections =>
      Set.unmodifiable(_dailySelectedSections);
  bool get monthlyNewestFirst => _monthlyNewestFirst;
  bool get monthlyStale => _monthlyStale;

  List<String> get dailyAvailableSections {
    final sections = <String>{};
    for (final s in dailyStudents) {
      final label = s.classSection.trim();
      if (label.isNotEmpty) sections.add(label);
    }
    final list = sections.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  bool get hasDailyListFiltersActive =>
      _dailySortOrder != StudentSortOrder.none ||
      _dailySelectedSections.isNotEmpty;

  /// Human-readable note when exporting a filtered on-screen list.
  String? get dailyExportFilterNote {
    final parts = <String>[];
    switch (_dailyStatusFilter) {
      case AttendanceFilter.pending:
        parts.add('Pending');
      case AttendanceFilter.attended:
        parts.add('Done');
      case AttendanceFilter.all:
        break;
    }
    switch (_dailyPaymentFilter) {
      case PaymentFilter.daily:
        parts.add('Daily pay');
      case PaymentFilter.term:
        parts.add('Term pay');
      case PaymentFilter.all:
        break;
    }
    if (_dailySelectedSections.isNotEmpty) {
      parts.add('Sections: ${_dailySelectedSections.join(', ')}');
    }
    final query = _dailySearchQuery.trim();
    if (query.isNotEmpty) {
      parts.add('Search: "$query"');
    }
    switch (_dailySortOrder) {
      case StudentSortOrder.nameAsc:
        parts.add('Sort: A→Z');
      case StudentSortOrder.nameDesc:
        parts.add('Sort: Z→A');
      case StudentSortOrder.none:
        break;
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  List<DaySummary> get visibleMonthlyDays {
    final raw = _monthlyReport?.days ?? const <DaySummary>[];
    final days = List<DaySummary>.from(raw);
    days.sort((a, b) => a.date.compareTo(b.date));
    if (_monthlyNewestFirst) {
      return days.reversed.toList();
    }
    return days;
  }

  void toggleMonthlyDayOrder() {
    _monthlyNewestFirst = !_monthlyNewestFirst;
    notifyListeners();
  }

  void setMonthlyNewestFirst(bool value) {
    if (_monthlyNewestFirst == value) return;
    _monthlyNewestFirst = value;
    notifyListeners();
  }

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get canGoToNextMonth =>
      _selectedMonth.year < _currentMonth.year ||
      (_selectedMonth.year == _currentMonth.year &&
          _selectedMonth.month < _currentMonth.month);

  bool get isCurrentMonth =>
      _selectedMonth.year == _currentMonth.year &&
      _selectedMonth.month == _currentMonth.month;

  List<StudentModel> get dailyStudents {
    final report = _dailyReport;
    if (report == null) return const [];
    return [...report.attendedStudents, ...report.notAttendedStudents];
  }

  Iterable<StudentModel> get _dailyForStatusCounts =>
      dailyStudents.where(_matchesDailyPayment);

  int get dailyTotalCount => _dailyForStatusCounts.length;
  int get dailyAttendedCount =>
      _dailyForStatusCounts.where((s) => s.isLunchAttended).length;
  int get dailyPendingCount => dailyTotalCount - dailyAttendedCount;

  int get dailyDailyPayCount =>
      dailyStudents.where((s) => s.isDailyPayment).length;
  int get dailyTermPayCount =>
      dailyStudents.where((s) => s.isTermPayment).length;

  List<StudentModel> get visibleDailyStudents {
    final query = _dailySearchQuery.trim().toLowerCase();
    final list = dailyStudents.where((s) {
      if (!_matchesDailyPayment(s)) return false;
      if (!_matchesDailySectionFilter(s)) return false;
      switch (_dailyStatusFilter) {
        case AttendanceFilter.attended:
          if (!s.isLunchAttended) return false;
        case AttendanceFilter.pending:
          if (s.isLunchAttended) return false;
        case AttendanceFilter.all:
          break;
      }
      if (query.isEmpty) return true;
      return s.studentName.toLowerCase().contains(query) ||
          s.admissionNo.toLowerCase().contains(query) ||
          s.classSection.toLowerCase().contains(query) ||
          s.studentId.toString().contains(query);
    }).toList();

    if (_dailySortOrder != StudentSortOrder.none) {
      list.sort((a, b) {
        final cmp =
            a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
        return _dailySortOrder == StudentSortOrder.nameAsc ? cmp : -cmp;
      });
    }
    return list;
  }

  bool _matchesDailyPayment(StudentModel s) {
    switch (_dailyPaymentFilter) {
      case PaymentFilter.daily:
        return s.isDailyPayment;
      case PaymentFilter.term:
        return s.isTermPayment;
      case PaymentFilter.all:
        return true;
    }
  }

  bool _matchesDailySectionFilter(StudentModel s) {
    if (_dailySelectedSections.isEmpty) return true;
    return _dailySelectedSections.contains(s.classSection.trim());
  }

  Future<void> loadMonthly({DateTime? month, bool silent = false}) async {
    if (month != null) {
      final requested = DateTime(month.year, month.month);
      _selectedMonth =
          requested.isAfter(_currentMonth) ? _currentMonth : requested;
    }

    if (!silent || _monthlyReport == null) {
      _isLoadingMonthly = true;
      _monthlyError = null;
      notifyListeners();
    }

    try {
      _monthlyReport = await _service.getMonthlyReport(selectedMonthApi);
      _monthlyError = null;
      _monthlyStale = false;
    } catch (e) {
      _monthlyError = e.toString();
      if (!silent) _monthlyReport = null;
    } finally {
      _isLoadingMonthly = false;
      notifyListeners();
    }
  }

  /// Call after marking attendance so Reports refetch on next open.
  void markMonthlyStale() {
    _monthlyStale = true;
  }

  Future<void> refreshMonthlyIfNeeded() async {
    if (!_monthlyStale && _monthlyReport != null) return;
    await loadMonthly(silent: _monthlyReport != null);
  }

  Future<void> changeMonth(int offset) async {
    final next = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
    );
    if (next.isAfter(_currentMonth)) return;
    _selectedMonth = next;
    await loadMonthly();
  }

  Future<void> selectMonth(DateTime month) async {
    final requested = DateTime(month.year, month.month);
    if (requested.isAfter(_currentMonth)) return;
    if (requested.year == _selectedMonth.year &&
        requested.month == _selectedMonth.month) {
      return;
    }
    _selectedMonth = requested;
    await loadMonthly();
  }

  /// Recent months ending at the current month (inclusive), oldest → newest.
  List<DateTime> recentMonths({int count = 12}) {
    final current = _currentMonth;
    return List.generate(
      count,
      (i) => DateTime(current.year, current.month - (count - 1 - i)),
    );
  }

  Future<void> loadDaily(String date) async {
    _isLoadingDaily = true;
    _dailyError = null;
    _dailyReport = null;
    _dailyStatusFilter = AttendanceFilter.pending;
    _dailyPaymentFilter = PaymentFilter.all;
    _dailySearchQuery = '';
    _dailySortOrder = StudentSortOrder.none;
    _dailySelectedSections.clear();
    notifyListeners();

    try {
      _dailyReport = await _service.getDailyReport(date);
      _pruneDailySelectedSections();
    } catch (e) {
      _dailyError = e.toString();
    } finally {
      _isLoadingDaily = false;
      notifyListeners();
    }
  }

  void _pruneDailySelectedSections() {
    if (_dailySelectedSections.isEmpty) return;
    final available = {
      for (final s in dailyStudents)
        if (s.classSection.trim().isNotEmpty) s.classSection.trim(),
    };
    _dailySelectedSections.removeWhere((s) => !available.contains(s));
  }

  void setDailyStatusFilter(AttendanceFilter value) {
    if (_dailyStatusFilter == value) return;
    _dailyStatusFilter = value;
    notifyListeners();
  }

  void setDailyPaymentFilter(PaymentFilter value) {
    if (_dailyPaymentFilter == value) return;
    _dailyPaymentFilter = value;
    notifyListeners();
  }

  void setDailySearchQuery(String value) {
    _dailySearchQuery = value;
    notifyListeners();
  }

  void applyDailyListFilters({
    required StudentSortOrder sortOrder,
    required Set<String> sections,
  }) {
    final next =
        sections.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final sortChanged = _dailySortOrder != sortOrder;
    final sectionsChanged = !setEquals(_dailySelectedSections, next);
    if (!sortChanged && !sectionsChanged) return;
    _dailySortOrder = sortOrder;
    _dailySelectedSections
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  void clearDaily() {
    _dailyReport = null;
    _dailyError = null;
    _dailySearchQuery = '';
    _dailyStatusFilter = AttendanceFilter.pending;
    _dailyPaymentFilter = PaymentFilter.all;
    _dailySortOrder = StudentSortOrder.none;
    _dailySelectedSections.clear();
  }
}
