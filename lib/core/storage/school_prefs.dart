import 'package:shared_preferences/shared_preferences.dart';

class SchoolPrefs {
  SchoolPrefs._();

  static const String _keySchoolId = 'school_id';

  static Future<int?> getSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySchoolId);
  }

  static Future<bool> hasSchoolId() async {
    final id = await getSchoolId();
    return id != null && id > 0;
  }

  static Future<void> setSchoolId(int schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySchoolId, schoolId);
  }

  static Future<void> clearSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySchoolId);
  }
}
