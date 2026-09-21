class StudentModel {
  const StudentModel({
    required this.studentId,
    required this.admissionNo,
    required this.profilePhoto,
    required this.gender,
    required this.studentName,
    required this.stdName,
    required this.sectionName,
    required this.academicYearId,
    required this.isLunchAttended,
    this.paymentType = '',
    this.nfcCardDeviceId = '',
  });

  final int studentId;
  final String admissionNo;
  final String profilePhoto;
  final String gender;
  final String studentName;
  final String stdName;
  final String sectionName;
  final int academicYearId;
  final bool isLunchAttended;
  final String paymentType;
  final String nfcCardDeviceId;

  bool get isDailyPayment => paymentType.trim().toLowerCase() == 'daily';

  bool get isTermPayment {
    final raw = paymentType.trim().toLowerCase();
    return raw == 'term_payment' || raw == 'term';
  }

  String get paymentLabel {
    if (isDailyPayment) return 'Daily';
    if (isTermPayment) return 'Term';
    if (paymentType.trim().isEmpty) return '—';
    return paymentType;
  }

  String get classSection {
    final grade = stdName.trim();
    final section = sectionName.trim();
    if (grade.isEmpty) return section;
    if (section.isEmpty) return grade;
    return '$grade - $section';
  }

  String get initials {
    final parts = studentName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  StudentModel copyWith({bool? isLunchAttended}) {
    return StudentModel(
      studentId: studentId,
      admissionNo: admissionNo,
      profilePhoto: profilePhoto,
      gender: gender,
      studentName: studentName,
      stdName: stdName,
      sectionName: sectionName,
      academicYearId: academicYearId,
      isLunchAttended: isLunchAttended ?? this.isLunchAttended,
      paymentType: paymentType,
      nfcCardDeviceId: nfcCardDeviceId,
    );
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: _asInt(json['student_id']),
      admissionNo: (json['admission_no'] ?? '').toString(),
      profilePhoto: (json['profile_photo'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      stdName: (json['std_name'] ?? '').toString(),
      sectionName: (json['section_name'] ?? '').toString(),
      academicYearId: _asInt(json['academicyear_id']),
      isLunchAttended: _asBool(json['is_lunch_attended']),
      paymentType: (json['payment_type'] ?? '').toString().trim().toLowerCase(),
      nfcCardDeviceId: (json['nfc_card_device_id'] ?? '').toString().trim(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == '1' || raw == 'true' || raw == 'yes';
  }
}
