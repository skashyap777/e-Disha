import 'package:flutter/material.dart';
import 'dart:math' as math;

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawLocationDots(canvas, size);
    _drawSubtleLines(canvas, size);
  }

  // Clean coordinate grid
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;

    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  // Simple location markers
  void _drawLocationDots(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    
    // Place 12 subtle dots across the canvas
    for (int i = 0; i < 12; i++) {
      final position = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      
      canvas.drawCircle(position, 3, dotPaint);
    }
  }

  // Minimal connecting lines
  void _drawSubtleLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final random = math.Random(84);
    
    // Draw 4 subtle diagonal lines
    for (int i = 0; i < 4; i++) {
      final start = Offset(
        random.nextDouble() * size.width * 0.3,
        random.nextDouble() * size.height,
      );
      
      final end = Offset(
        size.width * 0.7 + random.nextDouble() * size.width * 0.3,
        random.nextDouble() * size.height,
      );
      
      canvas.drawLine(start, end, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
