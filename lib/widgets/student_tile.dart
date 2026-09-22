import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/student_model.dart';
import 'student_avatar.dart';

enum StudentTileStyle { list, grid }

class StudentTile extends StatelessWidget {
  const StudentTile({
    super.key,
    required this.student,
    this.onTap,
    this.isMarking = false,
    this.showMarkAction = true,
    this.style = StudentTileStyle.list,
  });

  final StudentModel student;
  final VoidCallback? onTap;
  final bool isMarking;
  final bool showMarkAction;
  final StudentTileStyle style;

  @override
  Widget build(BuildContext context) {
    return style == StudentTileStyle.grid
        ? _GridTile(
            student: student,
            onTap: onTap,
            isMarking: isMarking,
            showMarkAction: showMarkAction,
          )
        : _ListTile(
            student: student,
            onTap: onTap,
            isMarking: isMarking,
            showMarkAction: showMarkAction,
          );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.student,
    required this.onTap,
    required this.isMarking,
    required this.showMarkAction,
  });

  final StudentModel student;
  final VoidCallback? onTap;
  final bool isMarking;
  final bool showMarkAction;

  @override
  Widget build(BuildContext context) {
    final attended = student.isLunchAttended;
    final bg =
        attended ? AppColors.success.withValues(alpha: 0.1) : AppColors.card;
    final border =
        attended ? AppColors.success.withValues(alpha: 0.4) : AppColors.divider;
    final canTap = onTap != null &&
        !isMarking &&
        (!showMarkAction || !attended);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              StudentAvatar(student: student, size: 48),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: AppStyles.cardTitle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      [
                        if (student.admissionNo.isNotEmpty) student.admissionNo,
                        if (student.classSection.isNotEmpty)
                          student.classSection,
                      ].join(' • '),
                      style: AppStyles.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showMarkAction) ...[
                const SizedBox(width: 4),
                if (isMarking)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (attended)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  )
                else
                  IconButton(
                    onPressed: onTap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.08),
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.restaurant_rounded, size: 18),
                    tooltip: 'Mark lunch',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.student,
    required this.onTap,
    required this.isMarking,
    required this.showMarkAction,
  });

  final StudentModel student;
  final VoidCallback? onTap;
  final bool isMarking;
  final bool showMarkAction;

  @override
  Widget build(BuildContext context) {
    final attended = student.isLunchAttended;
    final bg =
        attended ? AppColors.success.withValues(alpha: 0.12) : AppColors.card;
    final border = attended
        ? AppColors.success.withValues(alpha: 0.45)
        : AppColors.divider;
    final canTap = onTap != null &&
        !isMarking &&
        (!showMarkAction || !attended);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  StudentAvatar(
                    student: student,
                    size: 58,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  if (isMarking)
                    const Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (attended)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      student.studentName,
                      textAlign: TextAlign.center,
                      style: AppStyles.cardTitle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (student.classSection.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        student.classSection,
                        textAlign: TextAlign.center,
                        style: AppStyles.caption.copyWith(
                          fontSize: 10,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
