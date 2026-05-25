import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TrendSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;

  const TrendSparkline({
    required this.values,
    this.color = AppTheme.sage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.001 ? 1.0 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = AppTheme.textPrimary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = values.length == 1 ? size.width : size.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] - minValue) / range;
      final x = i * stepX;
      final y = size.height - (normalized * (size.height - 14)) - 7;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] - minValue) / range;
      final x = i * stepX;
      final y = size.height - (normalized * (size.height - 14)) - 7;
      canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
