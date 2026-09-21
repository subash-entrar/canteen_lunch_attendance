class MarkAttendanceResponse {
  const MarkAttendanceResponse({
    required this.status,
    required this.message,
    required this.studentId,
    required this.attendanceStatus,
    this.attendanceDate,
  });

  final int status;
  final String message;
  final int studentId;
  final int attendanceStatus;
  final String? attendanceDate;

  bool get isSuccess => status == 1 && attendanceStatus == 1;

  factory MarkAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return MarkAttendanceResponse(
      status: _asInt(json['status']),
      message: (json['message'] ?? '').toString(),
      studentId: _asInt(json['student_id']),
      attendanceStatus: _asInt(json['attendance_status']),
      attendanceDate: json['attendance_date']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
