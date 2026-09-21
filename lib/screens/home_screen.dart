import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_layout.dart';
import '../providers/attendance_provider.dart';
import '../providers/report_provider.dart';
import '../providers/students_provider.dart';
import 'attendance_screen.dart';
import 'monthly_report_screen.dart';
import 'students_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _pages = const [
    AttendanceScreen(),
    StudentsScreen(),
    MonthlyReportScreen(),
  ];

  Future<void> _onTabSelected(int i) async {
    if (i == _index) return;

    final attendance = context.read<AttendanceProvider>();
    final students = context.read<StudentsProvider>();
    final reports = context.read<ReportProvider>();

    setState(() => _index = i);

    // NFC only while Attendance tab is active.
    await attendance.setAttendanceTabActive(i == 0);

    if (i == 1) {
      await students.refreshIfNeeded();
    }

    if (i == 2) {
      await reports.refreshMonthlyIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _MinimalNavBar(
        index: _index,
        onSelected: _onTabSelected,
      ),
    );
  }
}

class _MinimalNavBar extends StatelessWidget {
  const _MinimalNavBar({
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding:
          EdgeInsets.fromLTRB(20, 0, 20, bottom + AppLayout.bottomNavBottomGap),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: AppLayout.bottomNavHeight,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.restaurant_menu_outlined,
                  selectedIcon: Icons.restaurant_menu_rounded,
                  selected: index == 0,
                  onTap: () => onSelected(0),
                ),
                _NavItem(
                  icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded,
                  selected: index == 1,
                  onTap: () => onSelected(1),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart_rounded,
                  selected: index == 2,
                  onTap: () => onSelected(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 22,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 4 : 0,
                  height: selected ? 4 : 0,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
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
