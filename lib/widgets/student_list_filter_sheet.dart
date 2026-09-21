import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../providers/attendance_provider.dart';

/// Result returned when the user applies filters from [showStudentListFilterSheet].
class StudentListFilterResult {
  const StudentListFilterResult({
    required this.sortOrder,
    required this.sections,
  });

  final StudentSortOrder sortOrder;
  final Set<String> sections;
}

Future<StudentListFilterResult?> showStudentListFilterSheet({
  required BuildContext context,
  required StudentSortOrder initialSort,
  required Set<String> initialSections,
  required List<String> availableSections,
  StudentSortOrder defaultSortOrder = StudentSortOrder.none,
}) {
  return showModalBottomSheet<StudentListFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.navy.withValues(alpha: 0.35),
    builder: (ctx) => StudentListFilterSheet(
      initialSort: initialSort,
      initialSections: initialSections,
      availableSections: availableSections,
      defaultSortOrder: defaultSortOrder,
    ),
  );
}

class StudentListFilterSheet extends StatefulWidget {
  const StudentListFilterSheet({
    super.key,
    required this.initialSort,
    required this.initialSections,
    required this.availableSections,
    this.defaultSortOrder = StudentSortOrder.none,
  });

  final StudentSortOrder initialSort;
  final Set<String> initialSections;
  final List<String> availableSections;
  final StudentSortOrder defaultSortOrder;

  @override
  State<StudentListFilterSheet> createState() => _StudentListFilterSheetState();
}

class _StudentListFilterSheetState extends State<StudentListFilterSheet> {
  late StudentSortOrder _sortOrder;
  late Set<String> _sections;

  @override
  void initState() {
    super.initState();
    _sortOrder = widget.initialSort;
    _sections = {...widget.initialSections};
  }

  bool get _hasChanges =>
      _sortOrder != widget.initialSort ||
      !_setEquals(_sections, widget.initialSections);

  bool get _canReset =>
      _sortOrder != widget.defaultSortOrder || _sections.isNotEmpty;

  void _reset() {
    setState(() {
      _sortOrder = widget.defaultSortOrder;
      _sections.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      StudentListFilterResult(
        sortOrder: _sortOrder,
        sections: Set<String>.from(_sections),
      ),
    );
  }

  void _toggleSection(String section) {
    setState(() {
      if (_sections.contains(section)) {
        _sections.remove(section);
      } else {
        _sections.add(section);
      }
    });
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: AppStyles.cardTitleBold.copyWith(fontSize: 18),
                    ),
                  ),
                  if (_canReset)
                    TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reset',
                        style: AppStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Sort by name'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SortOption(
                            label: 'Default',
                            icon: Icons.reorder_rounded,
                            selected: _sortOrder == StudentSortOrder.none,
                            onTap: () => setState(
                              () => _sortOrder = StudentSortOrder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SortOption(
                            label: 'A → Z',
                            icon: Icons.arrow_upward_rounded,
                            selected: _sortOrder == StudentSortOrder.nameAsc,
                            onTap: () => setState(
                              () => _sortOrder = StudentSortOrder.nameAsc,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SortOption(
                            label: 'Z → A',
                            icon: Icons.arrow_downward_rounded,
                            selected: _sortOrder == StudentSortOrder.nameDesc,
                            onTap: () => setState(
                              () => _sortOrder = StudentSortOrder.nameDesc,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _SectionLabel(label: 'Section'),
                        ),
                        if (_sections.isNotEmpty)
                          Text(
                            '${_sections.length} selected',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (widget.availableSections.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          'No sections available',
                          textAlign: TextAlign.center,
                          style: AppStyles.caption.copyWith(fontSize: 13),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final section in widget.availableSections)
                            _SectionChip(
                              label: section,
                              selected: _sections.contains(section),
                              onTap: () => _toggleSection(section),
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Leave sections empty to show all.',
                      style: AppStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, safeBottom + 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _hasChanges ? 'Apply filters' : 'Done',
                    style: AppStyles.cardTitle.copyWith(
                      color: AppColors.white,
                      fontSize: 15,
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppStyles.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.divider,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppStyles.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
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
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.divider,
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
