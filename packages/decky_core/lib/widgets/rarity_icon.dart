import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays Magic card-like rarity icons
class RarityIcon extends StatelessWidget {
  final String rarity;
  final double size;
  final bool isSelected;

  const RarityIcon({super.key, required this.rarity, this.size = 16.0, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RarityIconPainter(rarity: rarity.toLowerCase(), isSelected: isSelected),
    );
  }
}

class _RarityIconPainter extends CustomPainter {
  final String rarity;
  final bool isSelected;

  _RarityIconPainter({required this.rarity, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _getRarityColor();

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (rarity) {
      case 'common':
        // Draw a simple circle (like common symbol)
        canvas.drawCircle(center, radius, paint);
        break;

      case 'uncommon':
        // Draw a shield-like shape (more angular than circle)
        _drawShield(canvas, size, paint);
        break;

      case 'rare':
        // Draw a pointed star/gem shape
        _drawStar(canvas, size, paint);
        break;

      case 'mythic':
        // Draw a diamond shape
        _drawDiamond(canvas, size, paint);
        break;

      default:
        // Default to circle for unknown rarities
        canvas.drawCircle(center, radius, paint);
        break;
    }

    // Add a subtle border if selected
    if (isSelected) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = _getRarityColor().withOpacity(0.8)
        ..strokeWidth = 1.5;

      switch (rarity) {
        case 'common':
          canvas.drawCircle(center, radius, borderPaint);
          break;
        case 'uncommon':
          _drawShield(canvas, size, borderPaint);
          break;
        case 'rare':
          _drawStar(canvas, size, borderPaint);
          break;
        case 'mythic':
          _drawDiamond(canvas, size, borderPaint);
          break;
        default:
          canvas.drawCircle(center, radius, borderPaint);
          break;
      }
    }
  }

  void _drawShield(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create a shield-like shape
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.7, center.dy - radius * 0.3);
    path.lineTo(center.dx + radius * 0.7, center.dy + radius * 0.3);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius * 0.7, center.dy + radius * 0.3);
    path.lineTo(center.dx - radius * 0.7, center.dy - radius * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.5;
    const pi = 3.14159265359;

    // Create a 5-pointed star
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36.0 - 90.0) * (pi / 180.0); // Start from top
      final radius = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create a diamond shape
    path.moveTo(center.dx, center.dy - radius); // top
    path.lineTo(center.dx + radius, center.dy); // right
    path.lineTo(center.dx, center.dy + radius); // bottom
    path.lineTo(center.dx - radius, center.dy); // left
    path.close();

    canvas.drawPath(path, paint);
  }

  Color _getRarityColor() {
    switch (rarity) {
      case 'common':
        return Colors.black; // Black circle like on actual cards
      case 'uncommon':
        return const Color(0xFFB8B8B8); // Silver color
      case 'rare':
        return const Color(0xFFD4AF37); // Gold color
      case 'mythic':
        return const Color(0xFFFF8C00); // Dark orange/red orange
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _RarityIconPainter && other.rarity == rarity && other.isSelected == isSelected;
  }

  @override
  int get hashCode => Object.hash(rarity, isSelected);
}
