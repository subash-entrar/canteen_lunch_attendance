import 'package:flutter/material.dart';

abstract final class AppLayout {
  static const double bottomNavHeight = 56;
  static const double bottomNavBottomGap = 12;

  /// Floating nav bar height above the system safe area.
  static const double bottomNavOverlay = bottomNavHeight + bottomNavBottomGap;

  static double scrollBottomPadding(BuildContext context) =>
      bottomNavOverlay + MediaQuery.paddingOf(context).bottom + 16;
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
