import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/student_model.dart';
import '../providers/attendance_provider.dart';

/// Shows a compact result dialog after an NFC card scan.
/// Auto-closes after [autoCloseDuration] or when tapped outside.
Future<void> showNfcMarkResultDialog(
  BuildContext context,
  MarkResult result, {
  Duration autoCloseDuration = const Duration(seconds: 2),
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _NfcMarkResultDialog(
      result: result,
      autoCloseDuration: autoCloseDuration,
    ),
  );
}

class _NfcMarkResultDialog extends StatefulWidget {
  const _NfcMarkResultDialog({
    required this.result,
    required this.autoCloseDuration,
  });

  final MarkResult result;
  final Duration autoCloseDuration;

  @override
  State<_NfcMarkResultDialog> createState() => _NfcMarkResultDialogState();
}

class _NfcMarkResultDialogState extends State<_NfcMarkResultDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoCloseDuration, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.result.student;
    final config = _configFor(widget.result.type);

    return Dialog(
      backgroundColor: AppColors.card,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, color: config.color, size: 36),
            const SizedBox(height: 10),
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: AppStyles.cardTitleBold.copyWith(
                fontSize: 16,
                color: config.color,
              ),
            ),
            if (student != null) ...[
              const SizedBox(height: 12),
              _StudentAvatar(student: student),
              const SizedBox(height: 10),
              Text(
                student.studentName,
                textAlign: TextAlign.center,
                style: AppStyles.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              widget.result.message,
              textAlign: TextAlign.center,
              style: AppStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ResultConfig _configFor(MarkResultType type) {
    return switch (type) {
      MarkResultType.success => const _ResultConfig(
          title: 'Marked',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
      MarkResultType.alreadyMarked => const _ResultConfig(
          title: 'Already marked',
          color: AppColors.warning,
          icon: Icons.info_rounded,
        ),
      MarkResultType.error => const _ResultConfig(
          title: 'Failed',
          color: AppColors.danger,
          icon: Icons.error_rounded,
        ),
    };
  }
}

class _ResultConfig {
  const _ResultConfig({
    required this.title,
    required this.color,
    required this.icon,
  });

  final String title;
  final Color color;
  final IconData icon;
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    final placeholder = student.gender.toLowerCase().startsWith('f')
        ? 'assets/images/girl_avatar.png'
        : 'assets/images/boy_avatar.png';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.75),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 64,
          height: 64,
          child: student.profilePhoto.trim().isEmpty
              ? Image.asset(placeholder, fit: BoxFit.cover)
              : Image.network(
                  student.profilePhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset(placeholder, fit: BoxFit.cover),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      alignment: Alignment.center,
                      child: Text(
                        student.initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
