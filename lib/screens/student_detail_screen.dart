import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../core/utils/app_date_utils.dart';
import '../models/student_lunch_attendance_report.dart';
import '../models/student_model.dart';
import '../services/lunch_attendance_service.dart';
import '../widgets/summary_stat_card.dart';

enum _ReportPeriod { days7, days15, days30, custom }

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.student});

  final StudentModel student;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _service = LunchAttendanceService.create();

  _ReportPeriod _period = _ReportPeriod.days30;
  late DateTime _fromDate;
  late DateTime _toDate;

  StudentLunchAttendanceReport? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final range = AppDateUtils.lastDaysRange(30);
    _fromDate = range.from;
    _toDate = range.to;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await _service.getStudentLunchAttendanceReport(
        studentId: widget.student.studentId,
        fromDate: AppDateUtils.toApiDate(_fromDate),
        toDate: AppDateUtils.toApiDate(_toDate),
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPeriod(_ReportPeriod period) async {
    if (period == _ReportPeriod.custom) {
      await _pickCustomRange();
      return;
    }

    final days = switch (period) {
      _ReportPeriod.days7 => 7,
      _ReportPeriod.days15 => 15,
      _ReportPeriod.days30 => 30,
      _ReportPeriod.custom => 30,
    };
    final range = AppDateUtils.lastDaysRange(days);
    setState(() {
      _period = period;
      _fromDate = range.from;
      _toDate = range.to;
    });
    await _loadReport();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: AppDateUtils.today(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      helpText: 'Select period',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: AppColors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = _ReportPeriod.custom;
      _fromDate =
          DateTime(picked.start.year, picked.start.month, picked.start.day);
      _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
    await _loadReport();
  }

  List<StudentAttendanceDay> get _sortedDays {
    final days = List<StudentAttendanceDay>.from(
      _report?.attendanceDays ?? const [],
    );
    days.sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student details'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadReport,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _ProfileHeader(student: student)),
            SliverToBoxAdapter(
              child: _PeriodSelector(
                period: _period,
                fromDate: _fromDate,
                toDate: _toDate,
                onSelected: _selectPeriod,
              ),
            ),
            SliverToBoxAdapter(
              child: _SummaryRow(
                attended: _report?.totalDaysAttended ?? 0,
                isLoading: _isLoading,
              ),
            ),
            ..._buildAttendanceSlivers(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttendanceSlivers() {
    if (_isLoading && _report == null) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }

    if (_error != null && _report == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: _error!,
            icon: Icons.wifi_off_rounded,
            onRetry: _loadReport,
          ),
        ),
      ];
    }

    final days = _sortedDays;
    if (days.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: 'No lunch attendance in this period',
            icon: Icons.event_busy_rounded,
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Attendance days',
            style: AppStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        sliver: SliverList.separated(
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _AttendanceDayTile(day: days[index]),
        ),
      ),
    ];
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            _DetailAvatar(student: student),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
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
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (student.admissionNo.isNotEmpty)
                  _InfoChip(
                    icon: Icons.badge_outlined,
                    label: student.admissionNo,
                  ),
                if (student.paymentLabel != '—')
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: student.paymentLabel,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailAvatar extends StatelessWidget {
  const _DetailAvatar({required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    final placeholder = student.gender.toLowerCase().startsWith('f')
        ? 'assets/images/girl_avatar.png'
        : 'assets/images/boy_avatar.png';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 96,
          height: 96,
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
                          fontSize: 24,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.period,
    required this.fromDate,
    required this.toDate,
    required this.onSelected,
  });

  final _ReportPeriod period;
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<_ReportPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERIOD',
            style: AppStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PeriodChip(
                  label: '7 days',
                  selected: period == _ReportPeriod.days7,
                  onTap: () => onSelected(_ReportPeriod.days7),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: '15 days',
                  selected: period == _ReportPeriod.days15,
                  onTap: () => onSelected(_ReportPeriod.days15),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: '30 days',
                  selected: period == _ReportPeriod.days30,
                  onTap: () => onSelected(_ReportPeriod.days30),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: period == _ReportPeriod.custom ? 'Custom' : 'Custom…',
                  selected: period == _ReportPeriod.custom,
                  onTap: () => onSelected(_ReportPeriod.custom),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppDateUtils.toDisplayDate(fromDate)} – ${AppDateUtils.toDisplayDate(toDate)}',
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.attended,
    required this.isLoading,
  });

  final int attended;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Days attended',
                    style: AppStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading ? '…' : '$attended',
                    style: AppStyles.cardTitleBold.copyWith(
                      fontSize: 22,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceDayTile extends StatelessWidget {
  const _AttendanceDayTile({required this.day});

  final StudentAttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final date = AppDateUtils.tryParseApiDate(day.date);
    final marked = AppDateUtils.tryParseDateTime(day.markedTime);
    final dateLabel = date != null ? AppDateUtils.toDisplayDay(date) : day.date;
    final timeLabel = marked != null
        ? AppDateUtils.toDisplayTime(marked)
        : (day.markedTime.isEmpty ? '—' : day.markedTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: AppStyles.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Marked at $timeLabel',
                  style: AppStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Present',
              style: AppStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
