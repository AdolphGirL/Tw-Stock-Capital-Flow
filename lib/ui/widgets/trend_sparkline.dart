import 'package:flutter/material.dart';

class TrendSparkline extends StatelessWidget {
  final List<double> values;

  const TrendSparkline({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox();
    }

    final max = values.reduce((a, b) => a > b ? a : b);

    final min = values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: 70,
      height: 32,

      child: CustomPaint(
        painter: _SparklinePainter(values: values, max: max, min: min),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;

  final double max;

  final double min;

  _SparklinePainter({
    required this.values,
    required this.max,
    required this.min,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final positive = values.last >= values.first;

    paint.color = positive ? Colors.redAccent : Colors.green;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;

      final normalized =
          (values[i] - min) / ((max - min) == 0 ? 1 : (max - min));

      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
