import 'package:flutter/material.dart';
import 'dart:math' as math;

class ComicPattern extends StatefulWidget {
  final Widget child;
  const ComicPattern({super.key, required this.child});

  @override
  State<ComicPattern> createState() => _ComicPatternState();
}

class _ComicPatternState extends State<ComicPattern> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create an animation controller that repeats indefinitely
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Create rotation animation for diagonal lines
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi, // Full rotation over animation duration
    ).animate(_animationController);
    
    // Create pulse animation for elements
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Create color animation for elements
    _colorAnimation = ColorTween(
      begin: Colors.black.withOpacity(0.1),
      end: Colors.blue.withOpacity(0.1),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated pattern in the background
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: AnimatedComicPatternPainter(
                rotationValue: _rotationAnimation.value,
                pulseValue: _pulseAnimation.value,
                colorValue: _colorAnimation.value ?? Colors.black.withOpacity(0.1),
                animationController: _animationController,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Child content on top
        widget.child,
      ],
    );
  }
}

class AnimatedComicPatternPainter extends CustomPainter {
  final double rotationValue;
  final double pulseValue;
  final Color colorValue;
  final AnimationController animationController;

  AnimatedComicPatternPainter({
    required this.rotationValue,
    required this.pulseValue,
    required this.colorValue,
    required this.animationController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Animated color for dots - cycles through shades
    final dotPaint = Paint()
      ..color = HSVColor.fromAHSV(
        0.1, // Alpha
        (animationController.value * 360) % 360, // Hue cycles through all colors
        0.3, // Low saturation for subtle effect
        0.7, // Good brightness value
      ).toColor()
      ..strokeWidth = 1.5;

    // Animated color for lines - different cycle timing
    final linePaint = Paint()
      ..color = HSVColor.fromAHSV(
        0.07, // Alpha
        ((animationController.value * 360) + 180) % 360, // Opposite hue from dots
        0.4, // Low saturation
        0.8, // Brightness
      ).toColor()
      ..strokeWidth = 1.2;

    // Background grid pattern
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.8;
    
    // Animated spacing that varies slightly
    final spacing = 16.0 + (math.sin(animationController.value * math.pi * 2) * 2);
    
    // Draw horizontal grid lines with wave effect
    for (double y = 0; y < size.height; y += spacing * 2) {
      // Add a subtle wave effect to horizontal lines
      final path = Path();
      for (double x = 0; x < size.width; x += 5) {
        final waveFactor = math.sin((x / size.width * math.pi * 4) + (animationController.value * math.pi * 2)) * 2;
        if (x == 0) {
          path.moveTo(x, y + waveFactor);
        } else {
          path.lineTo(x, y + waveFactor);
        }
      }
      canvas.drawPath(path, gridPaint);
    }
    
    // Draw vertical grid lines with slight swaying
    for (double x = 0; x < size.width; x += spacing * 2) {
      // Add a subtle sway effect to vertical lines
      final path = Path();
      for (double y = 0; y < size.height; y += 5) {
        final swayFactor = math.sin((y / size.height * math.pi * 2) + (animationController.value * math.pi * 2)) * 2;
        if (y == 0) {
          path.moveTo(x + swayFactor, y);
        } else {
          path.lineTo(x + swayFactor, y);
        }
      }
      canvas.drawPath(path, gridPaint);
    }
    
    // Save canvas state to restore after rotation
    canvas.save();
    
    // Rotate canvas for animated diagonal lines
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationValue * 0.05); // Slow rotation
    canvas.translate(-size.width / 2, -size.height / 2);
    
    // Draw diagonal lines with rotation effect
    for (double i = -size.width; i < size.width * 2; i += spacing * 3) {
      // Diagonal lines (top-left to bottom-right)
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.width, size.height),
        linePaint,
      );
      
      // Diagonal lines (top-right to bottom-left)
      canvas.drawLine(
        Offset(size.width - i, 0),
        Offset(-i, size.height),
        linePaint,
      );
    }
    
    // Restore canvas to original state
    canvas.restore();

    // Draw moving dots at intersections
    final time = animationController.value;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Calculate motion offset based on sine waves with different phases
        final offsetX = math.sin((x / size.width * 2) + time * math.pi * 2) * 2;
        final offsetY = math.cos((y / size.height * 2) + time * math.pi * 2) * 2;
        
        // Draw dots with pulsing size
        final dotSize = 1.0 + (math.sin(time * math.pi * 2 + (x + y) / 200) * 0.3);
        canvas.drawCircle(
          Offset(x + offsetX, y + offsetY), 
          dotSize,
          dotPaint,
        );
      }
    }
    
    // Add animated decorative elements - stars/bursts
    final burstPaint = Paint()
      ..color = HSVColor.fromAHSV(
        0.1,
        (animationController.value * 360 + 120) % 360, // Another hue cycle
        0.5,
        0.8,
      ).toColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Deterministic pattern for bursts with animated movements
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 12; j++) {
        if ((i + j) % 5 == 0) {
          // Calculate position with slight motion
          double x = size.width * (i + 1) / 9 + (math.sin(time * math.pi * 2 + i) * 5);
          double y = size.height * (j + 1) / 13 + (math.cos(time * math.pi * 2 + j) * 5);
          
          // Calculate size with pulse effect
          double burstSize = 5 + (i % 3) * 2 + (math.sin(time * math.pi * 2 + (i * j)) * 2);
          
          // Draw animated burst
          _drawBurst(canvas, Offset(x, y), burstSize, burstPaint, time);
        }
      }
    }
  }
  
  // Enhanced burst drawing with rotation
  void _drawBurst(Canvas canvas, Offset center, double size, Paint paint, double time) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * math.pi); // Rotate burst over time
    
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4); // 45-degree increments
      // Animated ray length
      final rayLength = size * (1.0 + math.sin(time * math.pi * 2 + i) * 0.2);
      canvas.drawLine(
        Offset.zero,
        Offset(
          rayLength * math.cos(angle),
          rayLength * math.sin(angle),
        ),
        paint,
      );
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnimatedComicPatternPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.colorValue != colorValue;
  }
}
