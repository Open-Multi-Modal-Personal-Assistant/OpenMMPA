import 'package:flutter/material.dart';
import 'package:inspector_gadget/camera/service/page_state.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:watch_it/watch_it.dart';

class AppPageIndicator extends WatchingStatefulWidget {
  const AppPageIndicator({
    required this.controller,
    super.key,
    this.onDotPressed,
    this.color,
    this.dotSize,
  });

  final PageController controller;
  final void Function(int index)? onDotPressed;
  final Color? color;
  final double? dotSize;

  @override
  State<AppPageIndicator> createState() => AppPageIndicatorState();
}

class AppPageIndicatorState extends State<AppPageIndicator> {
  @override
  Widget build(BuildContext context) {
    final pageCount = watchPropertyValue((PageState p) => p.pageCount);
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Center(
        child: SmoothPageIndicator(
          controller: widget.controller,
          count: pageCount,
          onDotClicked: widget.onDotPressed,
          effect: ExpandingDotsEffect(
            dotWidth: widget.dotSize ?? 6,
            dotHeight: widget.dotSize ?? 6,
            strokeWidth: (widget.dotSize ?? 6) / 2,
            dotColor: widget.color ?? colorScheme.secondary,
            activeDotColor: widget.color ?? colorScheme.primary,
            expansionFactor: 2,
          ),
        ),
      ),
    );
  }
}
