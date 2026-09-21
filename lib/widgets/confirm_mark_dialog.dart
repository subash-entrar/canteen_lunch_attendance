import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/student_model.dart';

Future<bool> confirmMarkAttendance(
  BuildContext context,
  StudentModel student,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.card,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark Lunch',
              style: AppStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            _StudentAvatar(student: student),
            const SizedBox(height: 14),
            Text(
              student.studentName,
              textAlign: TextAlign.center,
              style: AppStyles.cardTitleBold.copyWith(
                fontSize: 18,
                height: 1.25,
              ),
            ),
            if (student.classSection.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  student.classSection,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            // if (student.admissionNo.isNotEmpty) ...[
            //   const SizedBox(height: 8),
            //   Text(
            //     student.admissionNo,
            //     style: AppStyles.caption.copyWith(
            //       color: AppColors.textSecondary,
            //       fontSize: 12,
            //     ),
            //   ),
            // ],
            const SizedBox(height: 8),
            Text(
              'Confirm lunch attendance for this student?',
              textAlign: TextAlign.center,
              style: AppStyles.subHeading.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.restaurant_rounded, size: 18),
                    label: const Text('Mark'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
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
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 88,
          height: 88,
          child: student.profilePhoto.trim().isEmpty
              ? Image.asset(placeholder, fit: BoxFit.cover)
              : Image.network(
                  student.profilePhoto,
                  fit: BoxFit.fill,
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
                          fontSize: 22,
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
