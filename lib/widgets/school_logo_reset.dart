import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../core/storage/school_prefs.dart';
import '../providers/attendance_provider.dart';
import '../providers/report_provider.dart';
import '../providers/students_provider.dart';
import '../screens/school_setup_screen.dart';

/// Hidden reset: hold [child] for 5 seconds to clear the saved school ID.
class SchoolLogoReset extends StatefulWidget {
  const SchoolLogoReset({super.key, required this.child});

  final Widget child;

  @override
  State<SchoolLogoReset> createState() => _SchoolLogoResetState();
}

class _SchoolLogoResetState extends State<SchoolLogoReset> {
  Timer? _holdTimer;

  void _startHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _showClearDialog();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  Future<void> _showClearDialog() async {
    final schoolId = await SchoolPrefs.getSchoolId();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear school ID?',
            style: AppStyles.cardTitleBold,
          ),
          content: Text(
            schoolId == null
                ? 'No school ID is saved on this device.'
                : 'Current school ID: $schoolId\n\n'
                    'This will remove it and return to the setup screen.',
            style: AppStyles.subHeading.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: AppStyles.cardTitle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: schoolId == null
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text(
                'Clear',
                style: AppStyles.cardTitle.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _resetToSetup();
  }

  Future<void> _resetToSetup() async {
    final attendance = context.read<AttendanceProvider>();
    final students = context.read<StudentsProvider>();
    final reports = context.read<ReportProvider>();

    await attendance.resetForSchoolChange();
    students.resetForSchoolChange();
    reports.resetForSchoolChange();
    await SchoolPrefs.clearSchoolId();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SchoolSetupScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: widget.child,
    );
  }
}
