import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Color baseColor;
  final Color? gradientColor1;
  final Color? gradientColor2;
  final bool isGradient;
  final Color? accentColor; // For light theme gradients

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.baseColor,
    this.gradientColor1,
    this.gradientColor2,
    this.isGradient = false,
    this.enabled = true,
    this.accentColor,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // Slower animation
      vsync: this,
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
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

  Color _adjustColor(Color color, double factor) {
    return Color.fromRGBO(
      ((color.r * 255) * factor).clamp(0, 255).toInt(),
      ((color.g * 255) * factor).clamp(0, 255).toInt(),
      ((color.b * 255) * factor).clamp(0, 255).toInt(),
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Static gradient mode (no animation)
    if (widget.isGradient &&
        widget.gradientColor1 != null &&
        widget.gradientColor2 != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.gradientColor1!, widget.gradientColor2!],
          ),
        ),
        child: widget.child,
      );
    }

    // Solid color (no animation) - but use gradient for light themes with accent
    if (!widget.enabled) {
      if (widget.accentColor != null) {
        // Use static gradient when accent color is provided
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.baseColor, widget.accentColor!],
            ),
          ),
          child: widget.child,
        );
      }

      // Default solid color
      return Container(
        color: widget.baseColor,
        child: widget.child,
      );
    }

    // Animated gradient
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        // Check if we're in a light theme by checking background luminance
        final isLightTheme = widget.baseColor.computeLuminance() > 0.5;

        // Create color variations based on theme type
        final color1 = widget.baseColor;
        final color2 = isLightTheme
            ? (widget.accentColor != null
                ? Color.lerp(widget.baseColor, widget.accentColor!, 0.5)!
                : Color.lerp(widget.baseColor, Colors.white, 0.5)!)
            : _adjustColor(widget.baseColor, 0.75);
        final color3 = isLightTheme
            ? (widget.accentColor != null
                ? Color.lerp(widget.baseColor, widget.accentColor!, 0.8)!
                : Color.lerp(widget.baseColor, Colors.white, 0.7)!)
            : _adjustColor(widget.baseColor, 0.55);

        // Interpolate between colors
        final t = math.sin(value * 2 * math.pi) * 0.5 + 0.5;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color.lerp(color1, color2, t)!,
                widget.baseColor,
                Color.lerp(color2, color3, t)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
