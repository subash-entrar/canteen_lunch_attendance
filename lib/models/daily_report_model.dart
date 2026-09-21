import 'student_model.dart';

class DailyLunchReport {
  const DailyLunchReport({
    required this.status,
    required this.message,
    required this.date,
    required this.summary,
    required this.attendedStudents,
    required this.notAttendedStudents,
  });

  final int status;
  final String message;
  final String date;
  final DailySummary summary;
  final List<StudentModel> attendedStudents;
  final List<StudentModel> notAttendedStudents;

  bool get isSuccess => status == 1;

  factory DailyLunchReport.fromJson(Map<String, dynamic> json) {
    return DailyLunchReport(
      status: _asInt(json['status']),
      message: (json['message'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      summary: DailySummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      attendedStudents: _parseStudents(json['attended_students']),
      notAttendedStudents: _parseStudents(json['not_attended_students']),
    );
  }

  static List<StudentModel> _parseStudents(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => StudentModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DailySummary {
  const DailySummary({
    required this.totalStudents,
    required this.attended,
    required this.notAttended,
  });

  final int totalStudents;
  final int attended;
  final int notAttended;

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalStudents: _asInt(json['total_students']),
      attended: _asInt(json['attended']),
      notAttended: _asInt(json['not_attended']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
