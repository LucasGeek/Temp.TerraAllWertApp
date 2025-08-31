import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';

class TerraLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final MainAxisAlignment alignment;

  const TerraLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cubo hexagonal geométrico
        CustomPaint(
          size: Size(size, size),
          painter: _HexagonalCubePainter(),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'Terra Allwert',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _HexagonalCubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Criar três faces do cubo hexagonal com cores diferentes
    // Face frontal (mais clara)
    paint.color = AppTheme.primaryColor;
    _drawHexagonFace(canvas, center, radius, 0);

    // Face direita (média)
    paint.color = AppTheme.primaryLight;
    _drawHexagonFace(canvas, center + Offset(radius * 0.3, -radius * 0.2), radius * 0.8, 0);

    // Face superior (mais escura)
    paint.color = AppTheme.primaryDark;
    _drawHexagonFace(canvas, center + Offset(radius * 0.15, -radius * 0.4), radius * 0.9, 0);

    // Adicionar bordas para definição
    paint
      ..style = PaintingStyle.stroke
      ..color = AppTheme.primaryDark.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    _drawHexagonFace(canvas, center, radius, 0);
    _drawHexagonFace(canvas, center + Offset(radius * 0.3, -radius * 0.2), radius * 0.8, 0);
    _drawHexagonFace(canvas, center + Offset(radius * 0.15, -radius * 0.4), radius * 0.9, 0);
  }

  void _drawHexagonFace(Canvas canvas, Offset center, double radius, double rotation) {
    final path = Path();
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + rotation) * (3.14159 / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, Paint()..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Função auxiliar para cos
double cos(double angle) {
  return math.cos(angle);
}

// Função auxiliar para sin  
double sin(double angle) {
  return math.sin(angle);
}