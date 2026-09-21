import 'dart:developer';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_headers.dart';
import '../models/daily_report_model.dart';
import '../models/mark_attendance_response.dart';
import '../models/monthly_report_model.dart';
import '../models/student_lunch_attendance_report.dart';
import '../models/student_model.dart';

class LunchAttendanceService {
  LunchAttendanceService(this._apiClient);

  final ApiClient _apiClient;

  factory LunchAttendanceService.create() {
    return LunchAttendanceService(ApiClient(ApiHeaders()));
  }

  Future<List<StudentModel>> getStudentList(String date) async {
    final response = await _apiClient.postForm(
      AppConfig.getStudentListUrl,
      data: {'date': date},
    );
    final body = _asMap(response.data);
    log('Student List: $body');
    final status = _asInt(body['status']);
    if (status != AppConfig.successStatus) {
      throw ApiException(
          (body['message'] ?? 'Failed to load students').toString());
    }
    final students = body['students'];
    log('Students: $students');
    if (students is! List) return [];
    return students
        .whereType<Map>()
        .map((e) => StudentModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<MarkAttendanceResponse> markLunchAttendance({
    required int studentId,
    required int academicYearId,
    required String attendanceDate,
  }) async {
    final response = await _apiClient.postForm(
      AppConfig.markLunchAttendanceUrl,
      data: {
        'student_id': studentId,
        'academicyear_id': academicYearId,
        'attendance_date': attendanceDate,
      },
    );
    final body = _asMap(response.data);
    return MarkAttendanceResponse.fromJson(body);
  }

  Future<MonthlyLunchReport> getMonthlyReport(String month) async {
    final response = await _apiClient.postForm(
      AppConfig.getMonthlyLunchReportUrl,
      data: {'month': month},
    );
    final body = _asMap(response.data);
    final report = MonthlyLunchReport.fromJson(body);
    log('Monthly Report: $report');
    if (!report.isSuccess) {
      throw ApiException(report.message.isEmpty
          ? 'Failed to load monthly report'
          : report.message);
    }
    return report;
  }

  Future<DailyLunchReport> getDailyReport(String date) async {
    final response = await _apiClient.postForm(
      AppConfig.getDailyLunchReportUrl,
      data: {'date': date},
    );
    final body = _asMap(response.data);
    final report = DailyLunchReport.fromJson(body);
    log('Daily Report: $report');
    if (!report.isSuccess) {
      throw ApiException(report.message.isEmpty
          ? 'Failed to load daily report'
          : report.message);
    }
    return report;
  }

  Future<StudentLunchAttendanceReport> getStudentLunchAttendanceReport({
    required int studentId,
    required String fromDate,
    required String toDate,
  }) async {
    final response = await _apiClient.postForm(
      AppConfig.getStudentLunchAttendanceReportUrl,
      data: {
        'student_id': studentId,
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    final body = _asMap(response.data);
    final report = StudentLunchAttendanceReport.fromJson(body);
    log('Student lunch attendance report: $body');
    if (!report.isSuccess) {
      throw ApiException(report.message.isEmpty
          ? 'Failed to load student attendance report'
          : report.message);
    }
    return report;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    throw ApiException('Unexpected server response');
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
