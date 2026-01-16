import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps any widget with a pulsing glow animation
/// Used for nav buttons during tour transitions
class PulsingButton extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Color? pulseColor;

  const PulsingButton({
    super.key,
    required this.child,
    this.isPulsing = false,
    this.pulseColor,
  });

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulsingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
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
    if (!widget.isPulsing) {
      return widget.child;
    }

    final pulseColor = widget.pulseColor ?? AppTheme.primaryGreen;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing glow effect
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pulseColor,
                  ),
                ),
              ),
            );
          },
        ),
        // The actual widget
        widget.child,
      ],
    );
  }
}
