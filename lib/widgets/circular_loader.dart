import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A colorful circular loading indicator based on an SVG animation
/// Original design by Nawsome from Uiverse.io
class CircularLoader extends StatefulWidget {
  /// The size of the loader (both width and height)
  final double size;

  /// Duration of the animation cycle in milliseconds
  final int duration;

  /// Stroke width of the circles
  final double strokeWidth;

  /// Creates a circular loader with customizable size and animation duration
  const CircularLoader({
    Key? key,
    this.size = 100,
    this.duration = 2000,
    this.strokeWidth = 10,
  }) : super(key: key);

  @override
  State<CircularLoader> createState() => _CircularLoaderState();
}

class _CircularLoaderState extends State<CircularLoader>
    with TickerProviderStateMixin {
  late AnimationController _controllerA;
  late AnimationController _controllerB;
  late AnimationController _controllerC;
  late AnimationController _controllerD;

  @override
  void initState() {
    super.initState();
    _controllerA = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    )..repeat();

    _controllerB = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    )..repeat();

    _controllerC = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    )..repeat();

    _controllerD = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    )..repeat();
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _controllerB.dispose();
    _controllerC.dispose();
    _controllerD.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Ring A (outer ring)
          AnimatedBuilder(
            animation: _controllerA,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  color: const Color(0xFFF42F25), // Red
                  controller: _controllerA,
                  radius: widget.size * 0.875, // 105/120
                  strokeWidth: _getStrokeWidth(_controllerA.value, 'A'),
                  dashArray: _getDashArray(_controllerA.value, 'A'),
                  dashOffset: _getDashOffset(_controllerA.value, 'A'),
                ),
              );
            },
          ),

          // Ring B (center ring)
          AnimatedBuilder(
            animation: _controllerB,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  color: const Color(0xFFF49725), // Orange
                  controller: _controllerB,
                  radius: widget.size * 0.292, // 35/120
                  strokeWidth: _getStrokeWidth(_controllerB.value, 'B'),
                  dashArray: _getDashArray(_controllerB.value, 'B'),
                  dashOffset: _getDashOffset(_controllerB.value, 'B'),
                ),
              );
            },
          ),

          // Ring C (left ring)
          AnimatedBuilder(
            animation: _controllerC,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  color: const Color(0xFF255FF4), // Blue
                  controller: _controllerC,
                  radius: widget.size * 0.583, // 70/120
                  strokeWidth: _getStrokeWidth(_controllerC.value, 'C'),
                  dashArray: _getDashArray(_controllerC.value, 'C'),
                  dashOffset: _getDashOffset(_controllerC.value, 'C'),
                  centerOffset: Offset(-widget.size * 0.292, 0), // 35/120
                ),
              );
            },
          ),

          // Ring D (right ring)
          AnimatedBuilder(
            animation: _controllerD,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  color: const Color(0xFFF42582), // Pink
                  controller: _controllerD,
                  radius: widget.size * 0.583, // 70/120
                  strokeWidth: _getStrokeWidth(_controllerD.value, 'D'),
                  dashArray: _getDashArray(_controllerD.value, 'D'),
                  dashOffset: _getDashOffset(_controllerD.value, 'D'),
                  centerOffset: Offset(widget.size * 0.292, 0), // 35/120
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _getStrokeWidth(double value, String ring) {
    final baseStrokeWidth = widget.strokeWidth;
    final thickerStrokeWidth = baseStrokeWidth * 1.5;

    // Different stroke width transitions based on the ring and animation progress
    switch (ring) {
      case 'A':
        if (value > 0.04 && value < 0.32) return thickerStrokeWidth;
        if (value > 0.62 && value < 0.82) return thickerStrokeWidth;
        return baseStrokeWidth;
      case 'B':
        if (value > 0.20 && value < 0.40) return thickerStrokeWidth;
        if (value > 0.70 && value < 0.90) return thickerStrokeWidth;
        return baseStrokeWidth;
      case 'C':
        if (value > 0.08 && value < 0.28) return thickerStrokeWidth;
        if (value > 0.66 && value < 0.86) return thickerStrokeWidth;
        return baseStrokeWidth;
      case 'D':
        if (value > 0.16 && value < 0.36) return thickerStrokeWidth;
        if (value > 0.58 && value < 0.78) return thickerStrokeWidth;
        return baseStrokeWidth;
      default:
        return baseStrokeWidth;
    }
  }

  List<double> _getDashArray(double value, String ring) {
    switch (ring) {
      case 'A':
        final circumference = 2 * math.pi * widget.size * 0.875;
        if (value > 0.04 && value < 0.32) {
          return [
            circumference * 0.09,
            circumference * 0.91,
          ]; // 60/660, 600/660
        }
        if (value > 0.62 && value < 0.82) {
          return [
            circumference * 0.09,
            circumference * 0.91,
          ]; // 60/660, 600/660
        }
        return [0, circumference]; // 0/660, 660/660
      case 'B':
        final circumference = 2 * math.pi * widget.size * 0.292;
        if (value > 0.20 && value < 0.40) {
          return [
            circumference * 0.09,
            circumference * 0.91,
          ]; // 20/220, 200/220
        }
        if (value > 0.70 && value < 0.90) {
          return [
            circumference * 0.09,
            circumference * 0.91,
          ]; // 20/220, 200/220
        }
        return [0, circumference]; // 0/220, 220/220
      case 'C':
      case 'D':
        final circumference = 2 * math.pi * widget.size * 0.583;
        if ((ring == 'C' &&
                ((value > 0.08 && value < 0.28) ||
                    (value > 0.66 && value < 0.86))) ||
            (ring == 'D' &&
                ((value > 0.16 && value < 0.36) ||
                    (value > 0.58 && value < 0.78)))) {
          return [
            circumference * 0.09,
            circumference * 0.91,
          ]; // 40/440, 400/440
        }
        return [0, circumference]; // 0/440, 440/440
      default:
        return [0, 100];
    }
  }

  double _getDashOffset(double value, String ring) {
    switch (ring) {
      case 'A':
        final circumference = 2 * math.pi * widget.size * 0.875;
        if (value < 0.04) return -circumference * 0.5; // -330/660
        if (value < 0.12) return -circumference * 0.507; // -335/660
        if (value < 0.32)
          return -circumference * 0.507 -
              value * 7 * circumference; // animate to -595
        if (value < 0.54) return -circumference; // -660/660
        if (value < 0.62) return -circumference * 1.007; // -665/660
        if (value < 0.82)
          return -circumference * 1.007 -
              (value - 0.62) * 7 * circumference; // animate to -925
        return -circumference * 1.5; // -990/660
      case 'B':
        final circumference = 2 * math.pi * widget.size * 0.292;
        if (value < 0.12) return -circumference * 0.5; // -110/220
        if (value < 0.20) return -circumference * 0.522; // -115/220
        if (value < 0.40)
          return -circumference * 0.522 -
              (value - 0.20) * 4 * circumference; // animate to -195
        if (value < 0.62) return -circumference; // -220/220
        if (value < 0.70) return -circumference * 1.022; // -225/220
        if (value < 0.90)
          return -circumference * 1.022 -
              (value - 0.70) * 4 * circumference; // animate to -305
        return -circumference * 1.5; // -330/220
      case 'C':
        final circumference = 2 * math.pi * widget.size * 0.583;
        if (value < 0.08) return 0;
        if (value < 0.28)
          return -circumference * 0.011 -
              value * 4 * circumference; // animate from -5 to -175
        if (value < 0.58) return -circumference * 0.5; // -220/440
        if (value < 0.66) return -circumference * 0.511; // -225/440
        if (value < 0.86)
          return -circumference * 0.511 -
              (value - 0.66) * 4 * circumference; // animate to -395
        return -circumference; // -440/440
      case 'D':
        final circumference = 2 * math.pi * widget.size * 0.583;
        if (value < 0.08) return 0;
        if (value < 0.16) return -circumference * 0.011; // -5/440
        if (value < 0.36)
          return -circumference * 0.011 -
              (value - 0.16) * 4 * circumference; // animate to -175
        if (value < 0.50) return -circumference * 0.5; // -220/440
        if (value < 0.58) return -circumference * 0.511; // -225/440
        if (value < 0.78)
          return -circumference * 0.511 -
              (value - 0.58) * 4 * circumference; // animate to -395
        return -circumference; // -440/440
      default:
        return 0;
    }
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final AnimationController controller;
  final double radius;
  final double strokeWidth;
  final List<double> dashArray;
  final double dashOffset;
  final Offset centerOffset;

  _RingPainter({
    required this.color,
    required this.controller,
    required this.radius,
    required this.strokeWidth,
    required this.dashArray,
    required this.dashOffset,
    this.centerOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + centerOffset;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Create a path to draw dashed circle
    final Path path =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    // Apply dash pattern
    final dashPath = Path();

    // Simple approximation of dashed path
    if (dashArray[0] > 0) {
      final metrics = path.computeMetrics().first;
      final length = metrics.length;
      final dashLength = dashArray[0];
      final gapLength = dashArray[1];
      final count = length ~/ (dashLength + gapLength);

      double distance = 0;
      double adjustedDashOffset = dashOffset % (dashLength + gapLength);
      distance += adjustedDashOffset;

      for (int i = 0; i < count; i++) {
        final start = distance;
        final end = start + dashLength;

        // Extract the segment from the path
        if (end <= length) {
          dashPath.addPath(metrics.extractPath(start, end), Offset.zero);
        } else {
          // Handle wrap-around
          dashPath.addPath(metrics.extractPath(start, length), Offset.zero);
          dashPath.addPath(metrics.extractPath(0, end - length), Offset.zero);
        }

        distance = (end + gapLength) % length;
      }

      canvas.drawPath(dashPath, paint);
    } else {
      // No dash, just draw the complete circle
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.controller.value != controller.value ||
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
