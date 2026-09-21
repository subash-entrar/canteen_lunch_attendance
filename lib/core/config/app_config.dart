class AppConfig {
  AppConfig._();

  static const String baseUrl = 'https://entrar.in';
  static const String apiFolder = 'RUHCTNAa8024205482ca3a9ccd5838d2acefd';
  static const String apiBase = '$baseUrl/$apiFolder';

  static const String markLunchAttendanceUrl =
      '$apiBase/mark_lunch_attendance.php';
  static const String getStudentListUrl = '$apiBase/get_student_list.php';
  static const String getMonthlyLunchReportUrl =
      '$apiBase/get_monthly_lunch_report.php';
  static const String getDailyLunchReportUrl =
      '$apiBase/get_daily_lunch_report.php';
  static const String getStudentLunchAttendanceReportUrl =
      '$apiBase/get_student_lunch_attendance_report.php';

  /// School is fixed server-side; kept here for documentation only.
  static const int schoolId = 260;

  static const int successStatus = 1;
}
