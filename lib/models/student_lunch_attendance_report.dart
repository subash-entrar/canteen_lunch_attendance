class StudentLunchAttendanceReport {
  const StudentLunchAttendanceReport({
    required this.status,
    required this.message,
    required this.studentId,
    required this.fromDate,
    required this.toDate,
    required this.student,
    required this.totalDaysAttended,
    required this.attendanceDays,
  });

  final int status;
  final String message;
  final int studentId;
  final String fromDate;
  final String toDate;
  final StudentReportProfile student;
  final int totalDaysAttended;
  final List<StudentAttendanceDay> attendanceDays;

  bool get isSuccess => status == 1;

  factory StudentLunchAttendanceReport.fromJson(Map<String, dynamic> json) {
    return StudentLunchAttendanceReport(
      status: _asInt(json['status']),
      message: (json['message'] ?? '').toString(),
      studentId: _asInt(json['student_id']),
      fromDate: (json['from_date'] ?? '').toString(),
      toDate: (json['to_date'] ?? '').toString(),
      student: StudentReportProfile.fromJson(
        (json['student'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      totalDaysAttended: _asInt(
        (json['summary'] as Map?)?['total_days_attended'],
      ),
      attendanceDays: _parseDays(json['attendance_days']),
    );
  }

  static List<StudentAttendanceDay> _parseDays(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => StudentAttendanceDay.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class StudentReportProfile {
  const StudentReportProfile({
    required this.studentId,
    required this.admissionNo,
    required this.studentName,
    required this.stdName,
    required this.sectionName,
  });

  final int studentId;
  final String admissionNo;
  final String studentName;
  final String stdName;
  final String sectionName;

  String get classSection {
    final grade = stdName.trim();
    final section = sectionName.trim();
    if (grade.isEmpty) return section;
    if (section.isEmpty) return grade;
    return '$grade - $section';
  }

  factory StudentReportProfile.fromJson(Map<String, dynamic> json) {
    return StudentReportProfile(
      studentId: _asInt(json['student_id']),
      admissionNo: (json['admission_no'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      stdName: (json['std_name'] ?? '').toString(),
      sectionName: (json['section_name'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class StudentAttendanceDay {
  const StudentAttendanceDay({
    required this.date,
    required this.attendanceStatus,
    required this.markedTime,
  });

  final String date;
  final int attendanceStatus;
  final String markedTime;

  bool get isAttended => attendanceStatus == 1;

  factory StudentAttendanceDay.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceDay(
      date: (json['date'] ?? '').toString(),
      attendanceStatus: _asInt(json['attendance_status']),
      markedTime: (json['marked_time'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
