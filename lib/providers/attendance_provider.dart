import 'package:flutter/foundation.dart';

import '../core/utils/app_date_utils.dart';
import '../core/utils/feedback_helper.dart';
import '../models/student_model.dart';
import '../services/lunch_attendance_service.dart';
import '../services/nfc_service.dart';

enum AttendanceFilter { all, attended, pending }

enum PaymentFilter { all, daily, term }

enum AttendanceLayout { list, grid }

enum StudentSortOrder { none, nameAsc, nameDesc }

enum MarkResultType { success, alreadyMarked, error }

class MarkResult {
  const MarkResult({
    required this.type,
    required this.message,
    this.student,
  });

  final MarkResultType type;
  final String message;
  final StudentModel? student;
}

/// UI listens to [nfcEventId] changes and reads [lastNfcEvent].
class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider({
    LunchAttendanceService? service,
    NfcService? nfcService,
  })  : _service = service ?? LunchAttendanceService.create(),
        _nfcService = nfcService ?? NfcService();

  final LunchAttendanceService _service;
  final NfcService _nfcService;

  List<StudentModel> _students = [];
  bool _isLoading = false;
  bool _isMarking = false;
  String? _error;
  String _searchQuery = '';
  AttendanceFilter _filter = AttendanceFilter.pending;
  PaymentFilter _paymentFilter = PaymentFilter.all;
  AttendanceLayout _layout = AttendanceLayout.grid;
  StudentSortOrder _sortOrder = StudentSortOrder.none;
  final Set<String> _selectedSections = {};
  final Set<int> _markingIds = {};

  /// User intent: continuous NFC should be on.
  bool _nfcDesired = true;

  /// Session is actively polling.
  bool _isNfcListening = false;

  /// Start/stop in progress — prevents double-taps.
  bool _isNfcBusy = false;

  /// Invalidates in-flight poll loops on stop/restart.
  int _nfcGeneration = 0;

  String? _lastNfcTagKey;
  DateTime? _lastNfcAt;

  MarkResult? _lastNfcEvent;
  int _nfcEventId = 0;

  DateTime get selectedDate => AppDateUtils.today();
  String get selectedDateApi => AppDateUtils.toApiDate(selectedDate);

  List<StudentModel> get students => List.unmodifiable(_students);
  bool get isLoading => _isLoading;
  bool get isMarking => _isMarking;
  bool get isNfcListening => _isNfcListening;
  bool get isNfcBusy => _isNfcBusy;
  bool get nfcDesired => _nfcDesired;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  AttendanceFilter get filter => _filter;
  PaymentFilter get paymentFilter => _paymentFilter;
  AttendanceLayout get layout => _layout;
  StudentSortOrder get sortOrder => _sortOrder;
  Set<String> get selectedSections => Set.unmodifiable(_selectedSections);
  MarkResult? get lastNfcEvent => _lastNfcEvent;
  int get nfcEventId => _nfcEventId;

  /// Unique class-section labels from the loaded list (e.g. "5 - A").
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

  /// Status counts respect the active payment filter.
  Iterable<StudentModel> get _studentsForStatusCounts =>
      _students.where(_matchesPaymentFilter);

  int get totalCount => _studentsForStatusCounts.length;
  int get attendedCount =>
      _studentsForStatusCounts.where((s) => s.isLunchAttended).length;
  int get pendingCount => totalCount - attendedCount;

  int get dailyCount => _students.where((s) => s.isDailyPayment).length;
  int get termCount => _students.where((s) => s.isTermPayment).length;

  List<StudentModel> get visibleStudents {
    final query = _searchQuery.trim().toLowerCase();
    final list = _students.where((s) {
      if (!_matchesPaymentFilter(s)) return false;
      if (!_matchesSectionFilter(s)) return false;
      switch (_filter) {
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

  bool _matchesPaymentFilter(StudentModel s) {
    switch (_paymentFilter) {
      case PaymentFilter.daily:
        return s.isDailyPayment;
      case PaymentFilter.term:
        return s.isTermPayment;
      case PaymentFilter.all:
        return true;
    }
  }

  bool _matchesSectionFilter(StudentModel s) {
    if (_selectedSections.isEmpty) return true;
    return _selectedSections.contains(s.classSection.trim());
  }

  bool isMarkingStudent(int studentId) => _markingIds.contains(studentId);

  Future<void> loadStudents({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final list = await _service.getStudentList(selectedDateApi);
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

  void _pruneSelectedSections() {
    if (_selectedSections.isEmpty) return;
    final available = {
      for (final s in _students)
        if (s.classSection.trim().isNotEmpty) s.classSection.trim(),
    };
    _selectedSections.removeWhere((s) => !available.contains(s));
  }

  /// Loads students, then starts NFC if the user still wants it on.
  Future<void> bootstrap() async {
    await loadStudents();
    if (_nfcDesired) {
      await startNfc();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFilter(AttendanceFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void setPaymentFilter(PaymentFilter value) {
    if (_paymentFilter == value) return;
    _paymentFilter = value;
    notifyListeners();
  }

  void setSortOrder(StudentSortOrder value) {
    if (_sortOrder == value) return;
    _sortOrder = value;
    notifyListeners();
  }

  void setSelectedSections(Set<String> sections) {
    final next =
        sections.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    if (setEquals(_selectedSections, next)) return;
    _selectedSections
      ..clear()
      ..addAll(next);
    notifyListeners();
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

  void clearListFilters() {
    if (_sortOrder == StudentSortOrder.none && _selectedSections.isEmpty) {
      return;
    }
    _sortOrder = StudentSortOrder.none;
    _selectedSections.clear();
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

  /// Called by the shell when the attendance tab is shown/hidden.
  Future<void> setAttendanceTabActive(bool active) async {
    if (!active) {
      await _haltNfcSession();
      return;
    }
    if (_nfcDesired) {
      await startNfc();
    }
  }

  Future<void> toggleNfc() async {
    if (_isNfcBusy) return;

    if (_isNfcListening || _nfcDesired) {
      _isNfcBusy = true;
      notifyListeners();
      try {
        await stopNfc();
        _emitNfcEvent(
          const MarkResult(
            type: MarkResultType.success,
            message: 'NFC stopped',
          ),
        );
      } finally {
        _isNfcBusy = false;
        notifyListeners();
      }
      return;
    }

    final started = await startNfc();
    if (started) {
      _emitNfcEvent(
        const MarkResult(
          type: MarkResultType.success,
          message: 'NFC on — tap cards to mark attendance',
        ),
      );
    }
  }

  /// Returns `true` when listening actually started.
  Future<bool> startNfc() async {
    if (_isNfcListening) return true;
    if (_isNfcBusy) return false;

    _isNfcBusy = true;
    notifyListeners();

    try {
      final available = await _nfcService.isAvailable();
      if (!available) {
        _nfcDesired = false;
        _emitNfcEvent(
          const MarkResult(
            type: MarkResultType.error,
            message:
                'NFC is not available. Please enable NFC in device settings.',
          ),
        );
        return false;
      }

      _nfcDesired = true;
      final generation = ++_nfcGeneration;
      _isNfcListening = true;
      notifyListeners();
      _runNfcLoop(generation);
      return true;
    } finally {
      _isNfcBusy = false;
      notifyListeners();
    }
  }

  Future<void> stopNfc() async {
    _nfcDesired = false;
    await _haltNfcSession();
  }

  Future<void> _haltNfcSession() async {
    _nfcGeneration++;
    _isNfcListening = false;
    notifyListeners();
    await _nfcService.stop();
  }

  Future<void> _runNfcLoop(int generation) async {
    try {
      while (_nfcDesired && generation == _nfcGeneration) {
        final result = await _nfcService.pollStudentPayload(
          timeout: const Duration(seconds: 45),
        );

        if (!_nfcDesired || generation != _nfcGeneration) break;

        if (result.cancelled) continue;

        if (!result.ok) {
          await FeedbackHelper.error();
          _emitNfcEvent(
            MarkResult(
              type: MarkResultType.error,
              message: result.error ?? 'NFC scan failed',
            ),
          );
          continue;
        }

        final tagKey = result.rawTagId.isNotEmpty
            ? result.rawTagId
            : result.payloads.join('|');
        final now = DateTime.now();
        if (_lastNfcTagKey == tagKey &&
            _lastNfcAt != null &&
            now.difference(_lastNfcAt!) < const Duration(seconds: 3)) {
          continue;
        }
        _lastNfcTagKey = tagKey;
        _lastNfcAt = now;

        final mark = await markFromNfcPayloads(result.payloads);
        if (!_nfcDesired || generation != _nfcGeneration) break;
        _emitNfcEvent(mark);

        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    } finally {
      if (generation == _nfcGeneration) {
        _isNfcListening = false;
        notifyListeners();
      }
    }
  }

  StudentModel? findByPayload(String payload) {
    final raw = payload.trim();
    if (raw.isEmpty) return null;

    final asId = int.tryParse(raw);
    if (asId != null) {
      for (final s in _students) {
        if (s.studentId == asId) return s;
      }
    }

    final lower = raw.toLowerCase();
    for (final s in _students) {
      if (s.admissionNo.toLowerCase() == lower) return s;
      if (s.nfcCardDeviceId.isNotEmpty &&
          s.nfcCardDeviceId.toLowerCase() == lower) {
        return s;
      }
    }
    return null;
  }

  StudentModel? findByPayloads(List<String> payloads) {
    for (final p in payloads) {
      final match = findByPayload(p);
      if (match != null) return match;
    }
    return null;
  }

  Future<MarkResult> markStudent(StudentModel student) async {
    if (student.isLunchAttended) {
      return MarkResult(
        type: MarkResultType.alreadyMarked,
        message: '${student.studentName} already marked for lunch',
        student: student,
      );
    }
    if (_markingIds.contains(student.studentId)) {
      return const MarkResult(
        type: MarkResultType.error,
        message: 'Already processing this student',
      );
    }

    _markingIds.add(student.studentId);
    _isMarking = true;
    notifyListeners();

    try {
      final response = await _service.markLunchAttendance(
        studentId: student.studentId,
        academicYearId: student.academicYearId,
        attendanceDate: selectedDateApi,
      );

      if (response.isSuccess) {
        _updateLocalAttended(student.studentId);
        await FeedbackHelper.success();
        return MarkResult(
          type: MarkResultType.success,
          message: response.message.isEmpty
              ? 'Attendance marked successfully'
              : response.message,
          student: student.copyWith(isLunchAttended: true),
        );
      }

      await FeedbackHelper.error();
      return MarkResult(
        type: MarkResultType.error,
        message: response.message.isEmpty
            ? 'Failed to mark attendance'
            : response.message,
        student: student,
      );
    } catch (e) {
      await FeedbackHelper.error();
      return MarkResult(
        type: MarkResultType.error,
        message: e.toString(),
        student: student,
      );
    } finally {
      _markingIds.remove(student.studentId);
      _isMarking = false;
      notifyListeners();
    }
  }

  Future<MarkResult> markFromNfcPayloads(List<String> payloads) async {
    final student = findByPayloads(payloads);
    if (student == null) {
      await FeedbackHelper.error();
      return MarkResult(
        type: MarkResultType.error,
        message:
            'Student not found for scanned tag (${payloads.take(2).join(', ')})',
      );
    }
    return markStudent(student);
  }

  void _emitNfcEvent(MarkResult result) {
    _lastNfcEvent = result;
    _nfcEventId++;
    notifyListeners();
  }

  void _updateLocalAttended(int studentId) {
    final index = _students.indexWhere((s) => s.studentId == studentId);
    if (index == -1) return;
    _students[index] = _students[index].copyWith(isLunchAttended: true);
  }

  @override
  void dispose() {
    _nfcDesired = false;
    _nfcGeneration++;
    _nfcService.stop();
    super.dispose();
  }
}
