class MonthlyLunchReport {
  const MonthlyLunchReport({
    required this.month,
    required this.summary,
    required this.days,
    required this.message,
    required this.status,
  });

  final int status;
  final String message;
  final String month;
  final MonthlySummary summary;
  final List<DaySummary> days;

  bool get isSuccess => status == 1;

  factory MonthlyLunchReport.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'];
    return MonthlyLunchReport(
      status: _asInt(json['status']),
      message: (json['message'] ?? '').toString(),
      month: (json['month'] ?? '').toString(),
      summary: MonthlySummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      days: daysJson is List
          ? daysJson
              .whereType<Map>()
              .map((e) => DaySummary.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class MonthlySummary {
  const MonthlySummary({
    required this.totalDays,
    required this.totalAttended,
    required this.totalNotAttended,
  });

  final int totalDays;
  final int totalAttended;
  final int totalNotAttended;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      totalDays: _asInt(json['total_days']),
      totalAttended: _asInt(json['total_attended']),
      totalNotAttended: _asInt(json['total_not_attended']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DaySummary {
  const DaySummary({
    required this.date,
    required this.totalStudents,
    required this.attended,
    required this.notAttended,
  });

  final String date;
  final int totalStudents;
  final int attended;
  final int notAttended;

  factory DaySummary.fromJson(Map<String, dynamic> json) {
    return DaySummary(
      date: (json['date'] ?? '').toString(),
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
