import 'package:flutter/material.dart';
import 'dart:math' as math;

class ShimmerCard extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ShimmerCard({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5), // Slower
      vsync: this,
    );

    if (widget.enabled) {
      // Start shimmer after random delay to stagger cards
      Future.delayed(Duration(milliseconds: math.Random().nextInt(3000)), () {
        if (mounted && widget.enabled) {
          _startShimmerCycle();
        }
      });
    }
  }

  // Run shimmer once, then wait 9 seconds before repeating
  void _startShimmerCycle() {
    if (!mounted || !widget.enabled) return;

    _controller.forward(from: 0).then((_) {
      if (mounted && widget.enabled) {
        // Wait 9 seconds before next shimmer
        Future.delayed(const Duration(seconds: 9), () {
          if (mounted && widget.enabled) {
            _startShimmerCycle();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(ShimmerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startShimmerCycle();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: CustomPaint(
                  painter: ShimmerPainter(
                    animation: _controller,
                    color: Colors.white.withOpacity(0.03), // Much more subtle
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShimmerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  ShimmerPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final gradientWidth = size.width * 0.5; // Wider sweep
    final left = -gradientWidth + (size.width + gradientWidth * 2) * progress;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.05), // Very subtle peak
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(left, 0, gradientWidth, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.plus; // Additive blending for subtlety

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant ShimmerPainter oldDelegate) => false;
}
