import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

/// Universal Hero Card widget - animated gradient card
/// Used for dashboard earnings, shift summaries, job cards, etc.
class HeroCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;

  const HeroCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8), // Slow, elegant animation
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect if we're in light mode by checking background luminance
    final isLightMode = AppTheme.darkBackground.computeLuminance() > 0.5;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animValue = _controller.value;
        final wave = math.sin(animValue * 2 * math.pi) * 0.5 + 0.5;

        return Container(
          margin: widget.margin,
          padding: widget.padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Semi-transparent base that lets background show through slightly
            color: isLightMode
                ? AppTheme.cardBackground.withValues(alpha: 0.6)
                : AppTheme.cardBackground.withValues(alpha: 0.7),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen
                    .withValues(alpha: 0.25 + (wave * 0.1)), // Animated opacity
                AppTheme.accentBlue.withValues(alpha: 0.2 + (wave * 0.08)),
              ],
            ),
            borderRadius:
                BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusXL),
            border: Border.all(
              color: AppTheme.primaryGreen
                  .withValues(alpha: 0.4 + (wave * 0.2)), // Animated border
              width: 1,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
