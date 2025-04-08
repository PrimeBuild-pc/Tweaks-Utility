import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/theme_provider.dart';

class ParticleModel {
  Offset position;
  Color color;
  double size;
  double speed;
  double angle;

  ParticleModel({
    required this.position,
    required this.color,
    required this.size,
    required this.speed,
    required this.angle,
  });

  void update(Size canvasSize) {
    final dx = cos(angle) * speed;
    final dy = sin(angle) * speed;
    position = Offset(position.dx + dx, position.dy + dy);

    // Wrap around the screen
    if (position.dx < 0) {
      position = Offset(canvasSize.width, position.dy);
    } else if (position.dx > canvasSize.width) {
      position = Offset(0, position.dy);
    }

    if (position.dy < 0) {
      position = Offset(position.dx, canvasSize.height);
    } else if (position.dy > canvasSize.height) {
      position = Offset(position.dx, 0);
    }
  }
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool isDarkMode;

  const AnimatedBackground({
    Key? key,
    required this.child,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ParticleModel> _particles = [];
  final Random _random = Random();
  final int _particleCount = 30;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          // Update particles
          for (var particle in _particles) {
            particle.update(MediaQuery.of(context).size);
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeParticles();
    });
  }

  void _initializeParticles() {
    final size = MediaQuery.of(context).size;
    _particles.clear();

    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        ParticleModel(
          position: Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * size.height,
          ),
          color: widget.isDarkMode
              ? AppColors.darkAccent
                  .withAlpha((_random.nextDouble() * 50).toInt())
              : AppColors.lightAccent
                  .withAlpha((_random.nextDouble() * 50).toInt()),
          size: _random.nextDouble() * 4 + 1,
          speed: _random.nextDouble() * 0.5 + 0.1,
          angle: _random.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDarkMode != oldWidget.isDarkMode) {
      _initializeParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.isDarkMode
            ? AppColors.darkGradient
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF5F5F5)],
              ),
      ),
      child: Stack(
        children: [
          // Particles
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ParticlePainter(particles: _particles),
          ),

          // Content
          widget.child,
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// Glass Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDarkMode;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.white.withAlpha(13),
                  Colors.white.withAlpha(5),
                ]
              : [
                  Colors.white.withAlpha(230),
                  Colors.white.withAlpha(179),
                ],
        ),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withAlpha(25)
              : Colors.white.withAlpha(128),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
