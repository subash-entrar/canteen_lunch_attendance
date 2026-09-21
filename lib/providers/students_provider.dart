import 'package:flutter/foundation.dart';

import '../core/utils/app_date_utils.dart';
import '../models/student_model.dart';
import '../services/lunch_attendance_service.dart';
import 'attendance_provider.dart';

/// Directory of all students (search, sort, section, layout).
class StudentsProvider extends ChangeNotifier {
  StudentsProvider({LunchAttendanceService? service})
      : _service = service ?? LunchAttendanceService.create();

  final LunchAttendanceService _service;

  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  PaymentFilter _paymentFilter = PaymentFilter.all;
  AttendanceLayout _layout = AttendanceLayout.list;
  StudentSortOrder _sortOrder = StudentSortOrder.none;
  final Set<String> _selectedSections = {};

  List<StudentModel> get students => List.unmodifiable(_students);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  PaymentFilter get paymentFilter => _paymentFilter;
  AttendanceLayout get layout => _layout;
  StudentSortOrder get sortOrder => _sortOrder;
  Set<String> get selectedSections => Set.unmodifiable(_selectedSections);

  List<String> get availableSections {
    final sections = <String>{};
    for (final s in _students) {
      final label = s.classSection.trim();
      if (label.isNotEmpty) sections.add(label);
    }
    final list = sections.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  bool get hasListFiltersActive =>
      _sortOrder != StudentSortOrder.none || _selectedSections.isNotEmpty;

  int get totalCount => _students.length;
  int get dailyCount => _students.where((s) => s.isDailyPayment).length;
  int get termCount => _students.where((s) => s.isTermPayment).length;

  int get visibleCount => visibleStudents.length;

  List<StudentModel> get visibleStudents {
    final query = _searchQuery.trim().toLowerCase();
    final list = _students.where((s) {
      if (!_matchesPayment(s)) return false;
      if (!_matchesSection(s)) return false;
      if (query.isEmpty) return true;
      return s.studentName.toLowerCase().contains(query) ||
          s.admissionNo.toLowerCase().contains(query) ||
          s.classSection.toLowerCase().contains(query) ||
          s.studentId.toString().contains(query) ||
          s.nfcCardDeviceId.toLowerCase().contains(query);
    }).toList();

    if (_sortOrder != StudentSortOrder.none) {
      list.sort((a, b) {
        final cmp =
            a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
        return _sortOrder == StudentSortOrder.nameAsc ? cmp : -cmp;
      });
    }
    return list;
  }

  bool _matchesPayment(StudentModel s) {
    switch (_paymentFilter) {
      case PaymentFilter.daily:
        return s.isDailyPayment;
      case PaymentFilter.term:
        return s.isTermPayment;
      case PaymentFilter.all:
        return true;
    }
  }

  bool _matchesSection(StudentModel s) {
    if (_selectedSections.isEmpty) return true;
    return _selectedSections.contains(s.classSection.trim());
  }

  Future<void> loadStudents({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final list = await _service.getStudentList(AppDateUtils.toApiDate(
        AppDateUtils.today(),
      ));
      _students = list;
      _pruneSelectedSections();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (!silent) _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads once; subsequent opens skip unless [force].
  Future<void> refreshIfNeeded({bool force = false}) async {
    if (!force && _students.isNotEmpty && _error == null) return;
    await loadStudents(silent: _students.isNotEmpty);
  }

  void _pruneSelectedSections() {
    if (_selectedSections.isEmpty) return;
    final available = {
      for (final s in _students)
        if (s.classSection.trim().isNotEmpty) s.classSection.trim(),
    };
    _selectedSections.removeWhere((s) => !available.contains(s));
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setPaymentFilter(PaymentFilter value) {
    if (_paymentFilter == value) return;
    _paymentFilter = value;
    notifyListeners();
  }

  void setLayout(AttendanceLayout value) {
    if (_layout == value) return;
    _layout = value;
    notifyListeners();
  }

  void toggleLayout() {
    setLayout(
      _layout == AttendanceLayout.list
          ? AttendanceLayout.grid
          : AttendanceLayout.list,
    );
  }

  void applyListFilters({
    required StudentSortOrder sortOrder,
    required Set<String> sections,
  }) {
    final next =
        sections.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final sortChanged = _sortOrder != sortOrder;
    final sectionsChanged = !setEquals(_selectedSections, next);
    if (!sortChanged && !sectionsChanged) return;
    _sortOrder = sortOrder;
    _selectedSections
      ..clear()
      ..addAll(next);
    notifyListeners();
  }
}
