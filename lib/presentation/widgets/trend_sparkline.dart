import 'package:flutter/material.dart';

class TrendSparkline extends StatelessWidget {
  final List<double> values;
  final double? max;
  final double? min;
  final double height;
  final double width;

  const TrendSparkline({
    super.key,
    required this.values,
    this.max,
    this.min,
    this.height = 40,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(width: width, height: height);

    // 計算最大最小值以供歸一化坐標系使用
    double computedMax = max ?? values.reduce((a, b) => a > b ? a : b);
    double computedMin = min ?? values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          max: computedMax,
          min: computedMin,
        ),
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
    if (values.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 頭尾數值對比判定趨勢顏色（漲紅跌綠，符合台股文化）
    final positive = values.last >= values.first;
    paint.color = positive ? Colors.redAccent : Colors.green;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x =
          (i / (values.length - 1 == 0 ? 1 : values.length - 1)) * size.width;

      final range = max - min;
      final normalized = (range == 0) ? 0.5 : (values[i] - min) / range;

      // 畫布座標 Y 軸向下，需用高度相減進行反轉
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
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    // 🚀 【性能優化核心：精準重繪屏障】
    // 只有在最大、最小值發生變動，或者數據源長度、內容不一致時，才允許 Canvas 重新繪製
    if (oldDelegate.max != max || oldDelegate.min != min) return true;
    if (oldDelegate.values.length != values.length) return true;

    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }

    return false; // 資料完全相同，直接複用上一幀緩衝（Bitmap Cache），達到 0% 運算浪費
  }
}
