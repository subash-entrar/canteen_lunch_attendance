import 'package:flutter/material.dart';

abstract final class AppLayout {
  static const double bottomNavHeight = 56;
  static const double bottomNavBottomGap = 12;

  /// Floating nav bar height above the system safe area.
  static const double bottomNavOverlay = bottomNavHeight + bottomNavBottomGap;

  static double scrollBottomPadding(BuildContext context) =>
      bottomNavOverlay + MediaQuery.paddingOf(context).bottom + 16;

  /// Matches [FabAboveBottomNav] — distance from scaffold bottom to FAB bottom.
  static const double floatingEndPadding = 16;

  static double fabBottomInset(BuildContext context) =>
      floatingEndPadding +
      bottomNavOverlay +
      MediaQuery.paddingOf(context).bottom;

  /// Bottom inset so [controlHeight] is vertically centered with the FAB.
  static double fabAlignedBottomInset(
    BuildContext context, {
    required double controlHeight,
    double fabSize = 56,
  }) {
    return fabBottomInset(context) + (fabSize - controlHeight) / 2;
  }

  /// Scroll-to-top button — bottom center, just above the floating home nav.
  static double scrollToTopBottomInset(
    BuildContext context, {
    required bool aboveHomeBottomNav,
  }) {
    final safe = MediaQuery.paddingOf(context).bottom;
    if (aboveHomeBottomNav) {
      return safe + bottomNavBottomGap + bottomNavHeight + 4;
    }
    return safe + floatingEndPadding;
  }

  /// Horizontal space reserved for a right-side FAB (width + trailing padding).
  static double fabHorizontalReserve({double fabSize = 56}) =>
      fabSize + floatingEndPadding;
}

/// Positions the FAB above the home screen's floating bottom nav bar.
class FabAboveBottomNav extends FloatingActionButtonLocation {
  const FabAboveBottomNav();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    const endPadding = 16.0;
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final scaffoldSize = scaffoldGeometry.scaffoldSize;
    final minInsets = scaffoldGeometry.minInsets;

    final x = scaffoldSize.width - fabSize.width - endPadding;
    final y = scaffoldSize.height -
        fabSize.height -
        endPadding -
        minInsets.bottom -
        AppLayout.bottomNavOverlay;

    return Offset(x, y);
  }
}
