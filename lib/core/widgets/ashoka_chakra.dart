import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Ashoka Chakra widget - the blue wheel from Indian flag
class AshokaChakra extends StatelessWidget {
  final double size;
  final Color color;

  const AshokaChakra({
    super.key,
    this.size = 80,
    this.color = const Color(0xFF000080), // Navy Blue
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: AshokaChakraPainter(color: color),
    );
  }
}

class AshokaChakraPainter extends CustomPainter {
  final Color color;

  AshokaChakraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - paint.strokeWidth;

    // Draw outer circle
    canvas.drawCircle(center, radius, paint);

    // Draw inner circle
    canvas.drawCircle(center, radius * 0.15, paint);

    // Draw 24 spokes (Ashoka Chakra has 24 spokes)
    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final startX = center.dx + (radius * 0.15) * math.cos(angle);
      final startY = center.dy + (radius * 0.15) * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        spokePaint,
      );
    }

    // Draw decorative dots at the end of each spoke
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final dotX = center.dx + (radius * 0.95) * math.cos(angle);
      final dotY = center.dy + (radius * 0.95) * math.sin(angle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        size.width * 0.015,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(AshokaChakraPainter oldDelegate) => false;
}
