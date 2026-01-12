import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Animated logo with independent shimmer, sparkle, and gradient effects
class AnimatedLogo extends StatefulWidget {
  final bool isTablet;

  const AnimatedLogo({
    super.key,
    this.isTablet = false,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _shimmerController;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();

    // Gradient animation - continuous color change (12 seconds cycle - faster)
    _gradientController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    // Shimmer animation - runs every ~20 seconds, faster sweep
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500), // 2.5 second sweep (faster)
      vsync: this,
    );
    _scheduleShimmer();

    // Sparkle animation - only for the icon
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 600), // Quick sparkle
      vsync: this,
    );
    _scheduleSparkle();
  }

  void _scheduleShimmer() {
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        _shimmerController.forward(from: 0).then((_) {
          _scheduleShimmer(); // Schedule next shimmer
        });
      }
    });
  }

  void _scheduleSparkle() {
    Future.delayed(const Duration(seconds: 24), () {
      if (mounted) {
        _sparkleController.forward(from: 0).then((_) {
          _scheduleSparkle(); // Schedule next sparkle
        });
      }
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _shimmerController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _gradientController,
        _shimmerController,
        _sparkleController,
      ]),
      builder: (context, child) {
        final gradientValue = _gradientController.value;
        final shimmerValue = _shimmerController.value;
        final sparkleValue = _sparkleController.value;

        // Gradient color that slowly changes
        final gradientT = math.sin(gradientValue * 2 * math.pi) * 0.5 + 0.5;
        final color1 = Color.lerp(
          AppTheme.primaryGreen,
          AppTheme.accentBlue,
          gradientT,
        )!;
        final color2 = Color.lerp(
          AppTheme.accentBlue,
          AppTheme.primaryGreen,
          gradientT,
        )!;

        return Stack(
          children: [
            // Base text with animated gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [color1, color2, color1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'In The Biz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 28 : 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Icon with sparkle overlay (fixed size, no movement)
                  SizedBox(
                    width: isTablet ? 22 : 14,
                    height: isTablet ? 22 : 14,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: isTablet ? 22 : 14,
                          color: Colors.white,
                        ),
                        // Subtle glow sparkle (no size change, just brightness)
                        if (sparkleValue > 0 && sparkleValue < 1)
                          Icon(
                            Icons.auto_awesome,
                            size: isTablet ? 22 : 14, // Same size, no growth
                            color: Colors.white.withValues(alpha: 
                              (sparkleValue < 0.5
                                      ? sparkleValue * 2
                                      : (1 - sparkleValue) * 2) *
                                  0.8, // Subtle glow
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Shimmer overlay (white highlight that sweeps across)
            if (shimmerValue > 0)
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: shimmerValue,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        stops: [
                          math.max(0, shimmerValue - 0.3),
                          shimmerValue,
                          math.min(1, shimmerValue + 0.3),
                        ],
                      ).createShader(bounds);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'In The Biz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 28 : 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.auto_awesome,
                          size: isTablet ? 22 : 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
