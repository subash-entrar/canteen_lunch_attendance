import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_layout.dart';
import '../constants/app_styles.dart';
import '../core/utils/app_date_utils.dart';
import '../models/monthly_report_model.dart';
import '../providers/report_provider.dart';
import '../widgets/summary_stat_card.dart';
import 'daily_report_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        final report = provider.monthlyReport;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 12,
            title: const Text('Lunch Reports'),
            actions: [
              if (report != null && report.days.isNotEmpty)
                IconButton(
                  tooltip: provider.monthlyNewestFirst
                      ? 'Show oldest first'
                      : 'Show newest first',
                  onPressed: provider.toggleMonthlyDayOrder,
                  icon: Icon(
                    provider.monthlyNewestFirst
                        ? Icons.south_rounded
                        : Icons.north_rounded,
                    size: 20,
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadMonthly(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _MonthToolbar(provider: provider, report: report),
                ),
                ..._buildBodySlivers(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildBodySlivers(ReportProvider provider) {
    if (provider.isLoadingMonthly && provider.monthlyReport == null) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }

    if (provider.monthlyError != null && provider.monthlyReport == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: provider.monthlyError!,
            icon: Icons.error_outline_rounded,
            onRetry: () => provider.loadMonthly(),
          ),
        ),
      ];
    }

    final days = provider.visibleMonthlyDays;
    if (days.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: 'No lunch report data for this month',
            icon: Icons.calendar_month_outlined,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Text(
                provider.monthlyNewestFirst ? 'Latest days' : 'Earliest days',
                style: AppStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${days.length} days',
                style: AppStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, AppLayout.scrollBottomPadding(context)),
        sliver: SliverList.separated(
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final day = days[index];
            return _DayRow(
              day: day,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyReportScreen(date: day.date),
                  ),
                );
              },
            );
          },
        ),
      ),
    ];
  }
}

class _MonthToolbar extends StatelessWidget {
  const _MonthToolbar({required this.provider, required this.report});

  final ReportProvider provider;
  final MonthlyLunchReport? report;

  @override
  Widget build(BuildContext context) {
    final canNext = provider.canGoToNextMonth && !provider.isLoadingMonthly;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: provider.isLoadingMonthly
                      ? null
                      : () => provider.changeMonth(-1),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: provider.isLoadingMonthly
                        ? AppColors.textSecondary.withValues(alpha: 0.35)
                        : AppColors.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppDateUtils.toDisplayMonth(provider.selectedMonth),
                    textAlign: TextAlign.center,
                    style: AppStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                ),
                IconButton(
                  onPressed: canNext ? () => provider.changeMonth(1) : null,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: canNext
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (report != null)
            Row(
              children: [
                _SummaryPill(
                  label: 'Days',
                  value: '${report!.summary.totalDays}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: 'Done',
                  value: '${report!.summary.totalAttended}',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: 'Missed',
                  value: '${report!.summary.totalNotAttended}',
                  color: AppColors.danger,
                ),
              ],
            )
          else if (provider.isLoadingMonthly)
            const SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: AppStyles.heading.fontFamily,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppStyles.caption.copyWith(
                color: color.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.onTap});

  final DaySummary day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parsed = AppDateUtils.tryParseApiDate(day.date);
    final dayNum = parsed?.day.toString() ?? '—';
    final weekday = parsed != null
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][parsed.weekday - 1]
        : '';
    final total = day.totalStudents <= 0 ? 1 : day.totalStudents;
    final ratio = (day.attended / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Text(
                      dayNum,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppStyles.heading.fontFamily,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weekday,
                      style: AppStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$percent% attended',
                            style: AppStyles.cardTitle.copyWith(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${day.attended}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFamily: AppStyles.heading.fontFamily,
                          ),
                        ),
                        Text(
                          ' / ${day.totalStudents}',
                          style: AppStyles.caption.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(
                                color:
                                    AppColors.danger.withValues(alpha: 0.18)),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${day.attended} done  ·  ${day.notAttended} missed',
                      style: AppStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
