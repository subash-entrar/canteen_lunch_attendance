import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_layout.dart';
import '../constants/app_styles.dart';
import '../core/utils/app_date_utils.dart';
import '../models/student_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/confirm_mark_dialog.dart';
import '../widgets/nfc_mark_result_dialog.dart';
import '../widgets/student_list_filter_sheet.dart';
import '../widgets/student_list_shimmer.dart';
import '../widgets/student_tile.dart';
import '../widgets/summary_stat_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _searchController = TextEditingController();
  AttendanceProvider? _provider;
  int _seenNfcEventId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<AttendanceProvider>();
      _provider!.addListener(_onProviderChanged);
      _provider!.bootstrap();
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    final provider = _provider;
    if (!mounted || provider == null) return;

    if (provider.nfcEventId != _seenNfcEventId) {
      _seenNfcEventId = provider.nfcEventId;
      final event = provider.lastNfcEvent;
      if (event != null) {
        if (_isNfcCardScanEvent(event)) {
          if (event.type == MarkResultType.success ||
              event.type == MarkResultType.alreadyMarked) {
            context.read<ReportProvider>().markMonthlyStale();
          }
          showNfcMarkResultDialog(context, event);
        } else {
          showAppToast(
            context,
            event.message,
            isError: event.type == MarkResultType.error,
          );
        }
      }
    }
  }

  bool _isNfcCardScanEvent(MarkResult event) {
    return !event.message.startsWith('NFC ');
  }

  Future<void> _handleMark(StudentModel student) async {
    final provider = context.read<AttendanceProvider>();
    if (student.isLunchAttended) {
      showAppToast(context, '${student.studentName} already marked');
      return;
    }

    final confirmed = await confirmMarkAttendance(context, student);
    if (!confirmed || !mounted) return;

    final result = await provider.markStudent(student);
    if (!mounted) return;
    if (result.type == MarkResultType.success ||
        result.type == MarkResultType.alreadyMarked) {
      context.read<ReportProvider>().markMonthlyStale();
    }
    showAppToast(
      context,
      result.message,
      isError: result.type == MarkResultType.error,
    );
  }

  Future<void> _openListFilters(AttendanceProvider provider) async {
    final result = await showStudentListFilterSheet(
      context: context,
      initialSort: provider.sortOrder,
      initialSections: provider.selectedSections,
      availableSections: provider.availableSections,
      defaultSortOrder: StudentSortOrder.none,
    );
    if (result == null || !mounted) return;
    provider.applyListFilters(
      sortOrder: result.sortOrder,
      sections: result.sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final listening = provider.isNfcListening;
        final busy = provider.isNfcBusy;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 12,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/splash_launcher.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Lunch Attendance',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              if (listening)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Center(
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Text(
                    AppDateUtils.toDisplayDayMonth(provider.selectedDate),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: const FabAboveBottomNav(),
          floatingActionButton: FloatingActionButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: busy ? null : () => provider.toggleNfc(),
            backgroundColor: listening ? AppColors.danger : AppColors.accent,
            foregroundColor: listening ? AppColors.white : AppColors.navy,
            tooltip: listening ? 'Stop NFC' : 'Start NFC',
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(listening ? Icons.stop_rounded : Icons.nfc_rounded),
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadStudents(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _FilterSummary(provider: provider),
                ),
                SliverToBoxAdapter(
                  child: _AttendanceProgressBar(provider: provider),
                ),
                SliverToBoxAdapter(
                  child: _PaymentFilterBar(provider: provider),
                ),
                SliverSearch(
                  controller: _searchController,
                  onChanged: provider.setSearchQuery,
                  hasActiveFilters: provider.hasListFiltersActive,
                  onFilterTap: () => _openListFilters(provider),
                ),
                ..._buildStudentSlivers(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStudentSlivers(AttendanceProvider provider) {
    if (provider.isLoading && provider.students.isEmpty) {
      return const [StudentListShimmerSliver()];
    }

    if (provider.error != null && provider.students.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: provider.error!,
            icon: Icons.wifi_off_rounded,
            onRetry: () => provider.loadStudents(),
          ),
        ),
      ];
    }

    final list = provider.visibleStudents;
    if (list.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            message: provider.students.isEmpty
                ? 'No students found for today'
                : 'No students match your filters',
            icon: Icons.people_outline_rounded,
            onRetry: provider.students.isEmpty
                ? () => provider.loadStudents()
                : null,
          ),
        ),
      ];
    }

    final isGrid = provider.layout == AttendanceLayout.grid;

    if (isGrid) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              12, 2, 12, AppLayout.scrollBottomPadding(context)),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final student = list[index];
                return StudentTile(
                  student: student,
                  style: StudentTileStyle.grid,
                  isMarking: provider.isMarkingStudent(student.studentId),
                  onTap: () => _handleMark(student),
                );
              },
              childCount: list.length,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
            12, 2, 12, AppLayout.scrollBottomPadding(context)),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 5),
          itemBuilder: (context, index) {
            final student = list[index];
            return StudentTile(
              student: student,
              style: StudentTileStyle.list,
              isMarking: provider.isMarkingStudent(student.studentId),
              onTap: () => _handleMark(student),
            );
          },
        ),
      ),
    ];
  }
}

class SliverSearch extends StatelessWidget {
  const SliverSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
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
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
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
              color: hasActiveFilters
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasActiveFilters
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.divider,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: hasActiveFilters
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      if (hasActiveFilters)
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
    );
  }
}

class _AttendanceProgressBar extends StatelessWidget {
  const _AttendanceProgressBar({required this.provider});

  final AttendanceProvider provider;

  @override
  Widget build(BuildContext context) {
    final total = provider.totalCount;
    final done = provider.attendedCount;
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Text(
            '$percent %',
            style: AppStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(color: AppColors.warning.withValues(alpha: 0.2)),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({required this.provider});

  final AttendanceProvider provider;

  @override
  Widget build(BuildContext context) {
    final isGrid = provider.layout == AttendanceLayout.grid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          _FilterStatChip(
            value: '${provider.pendingCount}',
            label: 'Pending',
            color: AppColors.warning,
            selected: provider.filter == AttendanceFilter.pending,
            onTap: () => provider.setFilter(AttendanceFilter.pending),
          ),
          const SizedBox(width: 6),
          _FilterStatChip(
            value: '${provider.attendedCount}',
            label: 'Done',
            color: AppColors.success,
            selected: provider.filter == AttendanceFilter.attended,
            onTap: () => provider.setFilter(AttendanceFilter.attended),
          ),
          const SizedBox(width: 6),
          _FilterStatChip(
            value: '${provider.totalCount}',
            label: 'All',
            color: AppColors.primary,
            selected: provider.filter == AttendanceFilter.all,
            onTap: () => provider.setFilter(AttendanceFilter.all),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: provider.toggleLayout,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(
                  isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  size: 18,
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

class _PaymentFilterBar extends StatelessWidget {
  const _PaymentFilterBar({required this.provider});

  final AttendanceProvider provider;

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
            _segment(
              label: 'Daily',
              count: provider.dailyCount,
              value: PaymentFilter.daily,
            ),
            _segment(
              label: 'Term',
              count: provider.termCount,
              value: PaymentFilter.term,
            ),
            _segment(
              label: 'All',
              count: provider.students.length,
              value: PaymentFilter.all,
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required String label,
    required int count,
    required PaymentFilter value,
  }) {
    final selected = provider.paymentFilter == value;
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => provider.setPaymentFilter(value),
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

class _FilterStatChip extends StatelessWidget {
  const _FilterStatChip({
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
