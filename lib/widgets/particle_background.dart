import 'package:flutter/material.dart';
import 'dart:math' as math;

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Color particleColor;

  const ParticleBackground({
    super.key,
    required this.child,
    required this.particleColor,
    this.enabled = true,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60), // Slower animation
      vsync: this,
    );

    // Only 10 particles for better performance
    particles = List.generate(10, (index) => Particle());

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ParticleBackground oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  animation: _controller,
                  color: widget.particleColor,
                ),
                child: Container(),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double speedX;
  late double speedY;
  late double size;
  late double opacity;

  Particle() {
    final random = math.Random();
    x = random.nextDouble();
    y = random.nextDouble();
    speedX = (random.nextDouble() - 0.5) * 0.0002; // Very slow movement
    speedY = (random.nextDouble() - 0.5) * 0.0002;
    size = random.nextDouble() * 2 + 1; // 1-3px
    opacity = random.nextDouble() * 0.3 + 0.1; // 10-40% opacity
  }

  void update() {
    x += speedX;
    y += speedY;

    // Wrap around edges
    if (x < 0) x = 1;
    if (x > 1) x = 0;
    if (y < 0) y = 1;
    if (y > 1) y = 0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      animation.value != oldDelegate.animation.value;
}
