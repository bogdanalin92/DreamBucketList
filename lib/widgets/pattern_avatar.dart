import 'dart:math';
import 'package:flutter/material.dart';

class PatternAvatar extends StatelessWidget {
  final Map<String, dynamic> patternData;
  final double size;

  const PatternAvatar({Key? key, required this.patternData, required this.size})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pattern = patternData['pattern'] as String? ?? 'geometric';
    final colorValues = patternData['colors'] as List<dynamic>? ?? [];
    final colors = colorValues.map((c) => Color(c as int)).toList();
    final seed = patternData['seed'] as String? ?? 'default';

    if (colors.isEmpty) {
      colors.add(Colors.blue); // fallback color
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _createGradient(pattern, colors),
      ),
      child: CustomPaint(
        painter: PatternPainter(pattern: pattern, colors: colors, seed: seed),
      ),
    );
  }

  Gradient _createGradient(String pattern, List<Color> colors) {
    switch (pattern) {
      case 'gradient':
        return LinearGradient(
          colors:
              colors.length >= 2
                  ? colors.take(2).toList()
                  : [colors[0], colors[0]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'abstract':
        return RadialGradient(
          colors: colors.isNotEmpty ? colors : [Colors.blue],
          center: Alignment.center,
        );
      default:
        return LinearGradient(
          colors: [colors[0], colors[0]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

class PatternPainter extends CustomPainter {
  final String pattern;
  final List<Color> colors;
  final String seed;

  PatternPainter({
    required this.pattern,
    required this.colors,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed.hashCode);
    final paint = Paint()..style = PaintingStyle.fill;

    switch (pattern) {
      case 'geometric':
        _paintGeometric(canvas, size, paint, random);
        break;
      case 'abstract':
        _paintAbstract(canvas, size, paint, random);
        break;
      case 'shapes':
        _paintShapes(canvas, size, paint, random);
        break;
      case 'patterns':
        _paintPatterns(canvas, size, paint, random);
        break;
      case 'modern':
        _paintModern(canvas, size, paint, random);
        break;
      case 'minimal':
        _paintMinimal(canvas, size, paint, random);
        break;
      case 'artistic':
        _paintArtistic(canvas, size, paint, random);
        break;
      default:
        _paintGeometric(canvas, size, paint, random);
    }
  }

  void _paintGeometric(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw geometric triangles
    paint.color =
        colors.length > 1
            ? colors[1].withOpacity(0.7)
            : colors[0].withOpacity(0.7);

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final centerX = size.width * (0.3 + random.nextDouble() * 0.4);
      final centerY = size.height * (0.3 + random.nextDouble() * 0.4);
      final radius = size.width * (0.1 + random.nextDouble() * 0.2);

      path.moveTo(centerX, centerY - radius);
      path.lineTo(centerX - radius * 0.866, centerY + radius * 0.5);
      path.lineTo(centerX + radius * 0.866, centerY + radius * 0.5);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  void _paintAbstract(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw abstract circles
    for (int i = 0; i < colors.length && i < 4; i++) {
      paint.color = colors[i % colors.length].withOpacity(0.6);
      final centerX = size.width * random.nextDouble();
      final centerY = size.height * random.nextDouble();
      final radius = size.width * (0.1 + random.nextDouble() * 0.3);

      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  void _paintShapes(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw various shapes
    paint.color =
        colors.length > 1
            ? colors[1].withOpacity(0.8)
            : colors[0].withOpacity(0.8);

    // Rectangle
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.2,
        size.width * 0.3,
        size.height * 0.3,
      ),
      paint,
    );

    // Circle
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.15,
      paint,
    );
  }

  void _paintPatterns(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw dot pattern
    paint.color =
        colors.length > 1
            ? colors[1].withOpacity(0.7)
            : colors[0].withOpacity(0.7);

    for (
      double x = size.width * 0.2;
      x < size.width * 0.8;
      x += size.width * 0.15
    ) {
      for (
        double y = size.height * 0.2;
        y < size.height * 0.8;
        y += size.height * 0.15
      ) {
        canvas.drawCircle(Offset(x, y), size.width * 0.03, paint);
      }
    }
  }

  void _paintModern(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw modern lines
    paint.color =
        colors.length > 1
            ? colors[1].withOpacity(0.8)
            : colors[0].withOpacity(0.8);
    paint.strokeWidth = size.width * 0.05;
    paint.style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.3),
      paint,
    );
  }

  void _paintMinimal(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw single shape
    paint.color = colors[0].withOpacity(0.9);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.2,
      paint,
    );
  }

  void _paintArtistic(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw artistic curves
    paint.color =
        colors.length > 1
            ? colors[1].withOpacity(0.7)
            : colors[0].withOpacity(0.7);
    paint.strokeWidth = size.width * 0.03;
    paint.style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width * 0.8,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.8,
      size.width * 0.2,
      size.height * 0.5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
