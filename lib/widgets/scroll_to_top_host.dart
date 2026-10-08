import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_layout.dart';

/// Wraps a scrollable [builder] and shows a bottom-center scroll-to-top control
/// after the user scrolls down.
class ScrollToTopHost extends StatefulWidget {
  const ScrollToTopHost({
    super.key,
    required this.builder,
    this.aboveHomeBottomNav = true,
    this.showAfterOffset = 280,
  });

  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  /// When true, insets above the home screen floating bottom nav (lowest safe spot).
  final bool aboveHomeBottomNav;

  final double showAfterOffset;

  @override
  State<ScrollToTopHost> createState() => _ScrollToTopHostState();
}

class _ScrollToTopHostState extends State<ScrollToTopHost> {
  late final ScrollController _controller;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final show = _controller.offset > widget.showAfterOffset;
    if (show != _visible) {
      setState(() => _visible = show);
    }
  }

  Future<void> _scrollToTop() async {
    if (!_controller.hasClients) return;
    await _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = AppLayout.scrollToTopBottomInset(
      context,
      aboveHomeBottomNav: widget.aboveHomeBottomNav,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.builder(context, _controller),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, 0.35),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Center(
                  child: _ScrollToTopButton(onPressed: _scrollToTop),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollToTopButton extends StatelessWidget {
  const _ScrollToTopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.25),
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: AppColors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
