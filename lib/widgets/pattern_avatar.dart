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
          stops: const [0.0, 1.0], // Ensure full gradient coverage
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
      case 'gradient':
        _paintGradient(canvas, size, paint, random);
        break;
      case 'abstract':
        _paintAbstract(canvas, size, paint, random);
        break;
      default:
        _paintGeometric(canvas, size, paint, random);
    }
  }

  void _paintGeometric(Canvas canvas, Size size, Paint paint, Random random) {
    // Draw geometric triangles with multiple colors
    for (int i = 0; i < 3; i++) {
      paint.color = colors[i % colors.length].withOpacity(0.7);

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

  void _paintGradient(Canvas canvas, Size size, Paint paint, Random random) {
    // For gradient pattern, we want minimal foreground painting
    // to let the LinearGradient background show through clearly
    // Add very subtle texture or let it be pure gradient

    if (colors.length >= 2) {
      // Add very subtle geometric accents that enhance rather than compete with the gradient
      paint.color = colors[0].withOpacity(0.15);

      // Draw subtle diamond shape in the center
      final centerX = size.width * 0.5;
      final centerY = size.height * 0.5;
      final diamondSize = size.width * 0.2;

      final path = Path();
      path.moveTo(centerX, centerY - diamondSize * 0.5);
      path.lineTo(centerX + diamondSize * 0.5, centerY);
      path.lineTo(centerX, centerY + diamondSize * 0.5);
      path.lineTo(centerX - diamondSize * 0.5, centerY);
      path.close();

      canvas.drawPath(path, paint);

      // Add a second subtle accent with the second color
      paint.color = colors[1].withOpacity(0.1);
      canvas.drawCircle(Offset(centerX, centerY), diamondSize * 0.3, paint);
    }
    // The main visual effect comes from the LinearGradient in the Container's decoration
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
