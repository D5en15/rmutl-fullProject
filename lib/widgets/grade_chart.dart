import 'package:flutter/material.dart';
import '../models/grade_entry.dart';

class GradeChart extends StatelessWidget {
  final List<GradeEntry> data;
  const GradeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CustomPaint(painter: _BarPainter(data), child: Container()),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<GradeEntry> data;
  _BarPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEFF1F5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bg,
    );

    if (data.isEmpty) return;
    final barPaint = Paint()..color = const Color(0xFF4F46E5);
    final maxScore = 100.0;
    final gap = 12.0;
    final barWidth = (size.width - gap * (data.length + 1)) / data.length;
    for (var i = 0; i < data.length; i++) {
      final h = (data[i].score / maxScore) * (size.height - 24);
      final dx = gap + i * (barWidth + gap);
      final rect = Rect.fromLTWH(dx, size.height - h - 12, barWidth, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.data != data;
}
