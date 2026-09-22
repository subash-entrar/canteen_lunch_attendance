import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/student_model.dart';

/// Profile photo avatar that decodes network images at display size only.
///
/// Without [cacheWidth]/[cacheHeight], Flutter keeps full-resolution bitmaps
/// (often multi‑MB each) and large student lists can OOM the app.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.student,
    this.size = 40,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final StudentModel student;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = student.gender.toLowerCase().startsWith('f')
        ? 'assets/images/girl_avatar.png'
        : 'assets/images/boy_avatar.png';
    final radius = borderRadius ?? BorderRadius.circular(8);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Decode only as many pixels as we paint (plus a small headroom).
    final cachePx = (size * dpr).round().clamp(48, 256);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: student.profilePhoto.trim().isEmpty
            ? Image.asset(placeholder, fit: fit)
            : Image.network(
                student.profilePhoto,
                fit: fit,
                width: size,
                height: size,
                cacheWidth: cachePx,
                cacheHeight: cachePx,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    Image.asset(placeholder, fit: fit),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: Center(
                      child: Text(
                        student.initials,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: size * 0.28,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
