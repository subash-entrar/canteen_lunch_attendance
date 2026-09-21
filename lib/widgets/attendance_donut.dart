import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

/// Compact donut showing lunch attendance share with center percentage.
class AttendanceDonut extends StatelessWidget {
  const AttendanceDonut({
    super.key,
    required this.attended,
    required this.pending,
    this.size = 112,
    this.strokeWidth = 12,
  });

  final int attended;
  final int pending;
  final double size;
  final double strokeWidth;

  int get total => attended + pending;

  double get attendedRatio => total == 0 ? 0 : attended / total;

  int get percent => total == 0 ? 0 : (attendedRatio * 100).round();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          attendedRatio: attendedRatio,
          attendedColor: AppColors.success,
          pendingColor: AppColors.warning,
          trackColor: AppColors.divider,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  fontFamily: AppStyles.heading.fontFamily,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Attended',
                style: AppStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.attendedRatio,
    required this.attendedColor,
    required this.pendingColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double attendedRatio;
  final Color attendedColor;
  final Color pendingColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, trackPaint);

    const start = -math.pi / 2;

    if (attendedRatio <= 0) {
      final pendingPaint = Paint()
        ..color = pendingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, math.pi * 2, false, pendingPaint);
      return;
    }

    if (attendedRatio >= 1) {
      final attendedPaint = Paint()
        ..color = attendedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, math.pi * 2, false, attendedPaint);
      return;
    }

    final attendedSweep = attendedRatio * math.pi * 2;
    final pendingSweep = (1 - attendedRatio) * math.pi * 2;

    final attendedPaint = Paint()
      ..color = attendedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final pendingPaint = Paint()
      ..color = pendingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, attendedSweep, false, attendedPaint);
    canvas.drawArc(
      rect,
      start + attendedSweep,
      pendingSweep,
      false,
      pendingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.attendedRatio != attendedRatio ||
        oldDelegate.attendedColor != attendedColor ||
        oldDelegate.pendingColor != pendingColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
