import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../core/utils/app_date_utils.dart';
import '../providers/attendance_provider.dart';
import '../providers/report_provider.dart';
import '../services/daily_report_pdf_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/attendance_donut.dart';
import '../widgets/student_list_filter_sheet.dart';
import '../widgets/student_list_shimmer.dart';
import '../widgets/student_tile.dart';
import '../widgets/summary_stat_card.dart';
import 'student_detail_screen.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key, required this.date});

  final String date;

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _searchController = TextEditingController();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadDaily(widget.date);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openListFilters(ReportProvider provider) async {
    final result = await showStudentListFilterSheet(
      context: context,
      initialSort: provider.dailySortOrder,
      initialSections: provider.dailySelectedSections,
      availableSections: provider.dailyAvailableSections,
      defaultSortOrder: StudentSortOrder.none,
    );
    if (result == null || !mounted) return;
    provider.applyDailyListFilters(
      sortOrder: result.sortOrder,
      sections: result.sections,
    );
  }

  Future<void> _exportPdf(ReportProvider provider) async {
    final report = provider.dailyReport;
    if (report == null || _isExporting) return;

    final students = provider.visibleDailyStudents;
    if (students.isEmpty) {
      showAppToast(context, 'No students to export', isError: true);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final bytes = await DailyReportPdfService.build(
        report: report,
        students: students,
        filterNote: provider.dailyExportFilterNote,
      );
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: DailyReportPdfService.filenameFor(report.date),
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        'Failed to export PDF: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = AppDateUtils.tryParseApiDate(widget.date);
    final title =
        parsed != null ? AppDateUtils.toDisplayDay(parsed) : widget.date;

    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        final hasReport = provider.dailyReport != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (hasReport)
                IconButton(
                  tooltip: 'Export PDF',
                  onPressed: _isExporting ? null : () => _exportPdf(provider),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadDaily(widget.date),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (hasReport)
                  SliverToBoxAdapter(
                    child: _DailyInsightCard(provider: provider),
                  ),
                if (hasReport) ...[
                  SliverToBoxAdapter(
                    child: _DailyStatusFilters(provider: provider),
                  ),
                  SliverToBoxAdapter(
                    child: _DailyPaymentFilters(provider: provider),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchController,
                                onChanged: provider.setDailySearchQuery,
                                style: AppStyles.subHeading.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: AppStyles.searchDecoration(
                                  hintText: 'Search name, admission…',
                                ).copyWith(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: provider.hasDailyListFiltersActive
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _openListFilters(provider),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: provider.hasDailyListFiltersActive
                                        ? AppColors.primary
                                            .withValues(alpha: 0.35)
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 20,
                                      color: provider.hasDailyListFiltersActive
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    if (provider.hasDailyListFiltersActive)
                                      Positioned(
                                        top: 7,
                                        right: 7,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                ..._buildBodySlivers(provider, hasReport: hasReport),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildBodySlivers(
    ReportProvider provider, {
    required bool hasReport,
  }) {
    if (provider.isLoadingDaily) {
      return const [StudentListShimmerSliver()];
    }

    if (provider.dailyError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: provider.dailyError!,
            onRetry: () => provider.loadDaily(widget.date),
          ),
        ),
      ];
    }

    if (!hasReport) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(message: 'No data'),
        ),
      ];
    }

    final list = provider.visibleDailyStudents;
    if (list.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: 'No students match your filters',
            icon: Icons.people_outline_rounded,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 28),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 5),
          itemBuilder: (context, index) {
            return StudentTile(
              student: list[index],
              showMarkAction: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentDetailScreen(student: list[index]),
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

class _DailyInsightCard extends StatelessWidget {
  const _DailyInsightCard({required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    final attended = provider.dailyAttendedCount;
    final pending = provider.dailyPendingCount;
    final total = provider.dailyTotalCount;
    final dailyPay = provider.dailyDailyPayCount;
    final termPay = provider.dailyTermPayCount;
    final payTotal = provider.dailyStudents.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AttendanceDonut(
                attended: attended,
                pending: pending,
                size: 108,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lunch overview',
                      style: AppStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LegendRow(
                      color: AppColors.success,
                      label: 'Done',
                      value: '$attended',
                      onTap: () => provider
                          .setDailyStatusFilter(AttendanceFilter.attended),
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: AppColors.warning,
                      label: 'Pending',
                      value: '$pending',
                      onTap: () => provider
                          .setDailyStatusFilter(AttendanceFilter.pending),
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: AppColors.primary,
                      label: 'Total',
                      value: '$total',
                      onTap: () =>
                          provider.setDailyStatusFilter(AttendanceFilter.all),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (payTotal > 0) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Payment mix',
                  style: AppStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$dailyPay daily · $termPay term',
                  style: AppStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (dailyPay > 0)
                      Expanded(
                        flex: dailyPay,
                        child: Container(color: AppColors.info),
                      ),
                    if (termPay > 0)
                      Expanded(
                        flex: termPay,
                        child: Container(color: AppColors.primary),
                      ),
                    if (dailyPay == 0 && termPay == 0)
                      Expanded(
                        child: Container(color: AppColors.divider),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _PayDot(color: AppColors.info, label: 'Daily'),
                const SizedBox(width: 12),
                _PayDot(color: AppColors.primary, label: 'Term'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppStyles.subHeading.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: AppStyles.heading.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayDot extends StatelessWidget {
  const _PayDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppStyles.caption.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _DailyStatusFilters extends StatelessWidget {
  const _DailyStatusFilters({required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          _StatChip(
            value: '${provider.dailyPendingCount}',
            label: 'Pending',
            color: AppColors.warning,
            selected: provider.dailyStatusFilter == AttendanceFilter.pending,
            onTap: () =>
                provider.setDailyStatusFilter(AttendanceFilter.pending),
          ),
          const SizedBox(width: 6),
          _StatChip(
            value: '${provider.dailyAttendedCount}',
            label: 'Done',
            color: AppColors.success,
            selected: provider.dailyStatusFilter == AttendanceFilter.attended,
            onTap: () =>
                provider.setDailyStatusFilter(AttendanceFilter.attended),
          ),
          const SizedBox(width: 6),
          _StatChip(
            value: '${provider.dailyTotalCount}',
            label: 'All',
            color: AppColors.primary,
            selected: provider.dailyStatusFilter == AttendanceFilter.all,
            onTap: () => provider.setDailyStatusFilter(AttendanceFilter.all),
          ),
        ],
      ),
    );
  }
}

class _DailyPaymentFilters extends StatelessWidget {
  const _DailyPaymentFilters({required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            _segment('Daily', provider.dailyDailyPayCount, PaymentFilter.daily),
            _segment('Term', provider.dailyTermPayCount, PaymentFilter.term),
            _segment(
              'All',
              provider.dailyStudents.length,
              PaymentFilter.all,
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, int count, PaymentFilter value) {
    final selected = provider.dailyPaymentFilter == value;
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => provider.setDailyPaymentFilter(value),
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              '$label $count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                fontFamily: AppStyles.caption.fontFamily,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: selected ? AppColors.white : color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppStyles.heading.fontFamily,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.white.withValues(alpha: 0.95)
                          : color.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppStyles.caption.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
