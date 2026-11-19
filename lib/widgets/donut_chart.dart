import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutSlice {
  final String label;
  final double value;
  final Color color;

  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const DonutChart({
    super.key,
    required this.slices,
    this.size = 210,
    this.strokeWidth = 26,
    this.center,
  });

  static const List<Color> palette = [
    Color(0xFF0F766E), // Teal
    Color(0xFFD94848), // Coral Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Indigo
  ];

  static Color colorForIndex(int index) => palette[index % palette.length];

  @override
  Widget build(BuildContext context) {
    final trackColor =
        Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(180);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutChartPainter(
              slices: slices,
              strokeWidth: strokeWidth,
              trackColor: trackColor,
            ),
          ),
          if (center != null)
            Padding(
              padding: EdgeInsets.all(strokeWidth + 10),
              child: center!,
            ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double strokeWidth;
  final Color trackColor;

  _DonutChartPainter({
    required this.slices,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final validSlices = slices.where((s) => s.value > 0).toList();
    final total = validSlices.fold<double>(0.0, (sum, s) => sum + s.value);
    if (total <= 0 || validSlices.isEmpty) return;

    const fullCircle = 2 * math.pi;
    final gapAngle = validSlices.length > 1 ? 0.035 : 0.0;
    double startAngle = -math.pi / 2;

    for (final slice in validSlices) {
      final rawSweep = (slice.value / total) * fullCircle;
      final sweepAngle = math.max(0.02, rawSweep - gapAngle);

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle + (gapAngle / 2),
        sweepAngle,
        false,
        paint,
      );

      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}
