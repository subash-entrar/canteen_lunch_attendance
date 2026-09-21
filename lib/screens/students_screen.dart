import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_layout.dart';
import '../constants/app_styles.dart';
import '../models/student_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/students_provider.dart';
import '../widgets/student_list_filter_sheet.dart';
import '../widgets/student_list_shimmer.dart';
import '../widgets/student_tile.dart';
import '../widgets/summary_stat_card.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openListFilters(StudentsProvider provider) async {
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

  void _openStudentDetail(StudentModel student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 12,
            title: const Text('Students'),
            actions: [
              if (provider.students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    child: Text(
                      '${provider.visibleCount} / ${provider.totalCount}',
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
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadStudents(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Toolbar(provider: provider),
                ),
                SliverToBoxAdapter(
                  child: _PaymentFilterBar(provider: provider),
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
                              onChanged: provider.setSearchQuery,
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
                          color: provider.hasListFiltersActive
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
                                  color: provider.hasListFiltersActive
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
                                    color: provider.hasListFiltersActive
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  if (provider.hasListFiltersActive)
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
                ..._buildStudentSlivers(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStudentSlivers(StudentsProvider provider) {
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
                ? 'No students found'
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
    final bottom = AppLayout.scrollBottomPadding(context);

    if (isGrid) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 2, 12, bottom),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return StudentTile(
                  student: list[index],
                  style: StudentTileStyle.grid,
                  showMarkAction: false,
                  onTap: () => _openStudentDetail(list[index]),
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
        padding: EdgeInsets.fromLTRB(12, 2, 12, bottom),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 5),
          itemBuilder: (context, index) {
            return StudentTile(
              student: list[index],
              style: StudentTileStyle.list,
              showMarkAction: false,
              onTap: () => _openStudentDetail(list[index]),
            );
          },
        ),
      ),
    ];
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.provider});

  final StudentsProvider provider;

  @override
  Widget build(BuildContext context) {
    final isGrid = provider.layout == AttendanceLayout.grid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isGrid ? 'Grid view' : 'List view',
              style: AppStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
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

  final StudentsProvider provider;

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
            _segment('Daily', provider.dailyCount, PaymentFilter.daily),
            _segment('Term', provider.termCount, PaymentFilter.term),
            _segment('All', provider.totalCount, PaymentFilter.all),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, int count, PaymentFilter value) {
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
