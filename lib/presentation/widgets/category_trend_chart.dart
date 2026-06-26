import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/database/app_database.dart';

enum _Metric { trend, score, persist, breadth }

/// 30 日板塊走勢互動圖（fl_chart LineChart）
/// 支援 4 種指標切換，提供觸碰 tooltip 顯示精確日期與數值。
class CategoryTrendChart extends StatefulWidget {
  /// history 須由舊→新排序（index 0 = 最舊）
  final List<CategoryHistoryData> history;

  const CategoryTrendChart({super.key, required this.history});

  @override
  State<CategoryTrendChart> createState() => _CategoryTrendChartState();
}

class _CategoryTrendChartState extends State<CategoryTrendChart> {
  _Metric _metric = _Metric.trend;

  // ── 資料存取 ──────────────────────────────────────────────────────────────

  List<double> get _values {
    switch (_metric) {
      case _Metric.trend:
        return widget.history.map((e) => e.trendStrength).toList();
      case _Metric.score:
        return widget.history.map((e) => e.score).toList();
      case _Metric.persist:
        return widget.history.map((e) => e.persistence).toList();
      case _Metric.breadth:
        return widget.history
            .map((e) => e.totalCount > 0
                ? e.riseCount / e.totalCount * 100.0
                : 50.0)
            .toList();
    }
  }

  String _metricLabel(_Metric m) {
    switch (m) {
      case _Metric.trend: return '趨勢強度';
      case _Metric.score: return '資金流分';
      case _Metric.persist: return '持續力';
      case _Metric.breadth: return '上漲占比%';
    }
  }

  Color get _lineColor {
    final vals = _values;
    if (vals.isEmpty) return Colors.blueAccent;
    final last = vals.last;
    if (_metric == _Metric.breadth) {
      return last >= 50 ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    }
    return last >= 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
  }

  // ── 主建構 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricTabs(),
        const SizedBox(height: 12),
        SizedBox(height: 180, child: _buildChart()),
      ],
    );
  }

  // ── 指標切換列 ────────────────────────────────────────────────────────────

  Widget _buildMetricTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _Metric.values.map((m) {
          final selected = _metric == m;
          return GestureDetector(
            onTap: () => setState(() => _metric = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? _lineColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? _lineColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                _metricLabel(m),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── fl_chart 主圖 ─────────────────────────────────────────────────────────

  Widget _buildChart() {
    final vals = _values;
    if (vals.length < 2) {
      return const Center(
        child: Text('資料不足，需至少 2 天歷史記錄',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    final spots = vals
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final double minY = vals.reduce((a, b) => a < b ? a : b);
    final double maxY = vals.reduce((a, b) => a > b ? a : b);
    final double padding = ((maxY - minY).abs() < 1.0 ? 1.0 : (maxY - minY) * 0.15);
    final double chartMinY = minY - padding;
    final double chartMaxY = maxY + padding;

    final color = _lineColor;
    final isPositiveTrend = vals.last >= vals.first;

    return LineChart(
      LineChartData(
        minY: chartMinY,
        maxY: chartMaxY,
        clipData: const FlClipData.all(),

        // ── 觸碰 tooltip ──────────────────────────────────────────────────
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            getTooltipItems: (spots) => spots.map((spot) {
              final idx = spot.x.toInt().clamp(0, widget.history.length - 1);
              final raw = widget.history[idx].tradeDate;
              final dateLabel = raw.length >= 8
                  ? '${raw.substring(4, 6)}/${raw.substring(6, 8)}'
                  : raw;
              final valStr = _metric == _Metric.breadth
                  ? '${spot.y.toStringAsFixed(1)}%'
                  : spot.y.toStringAsFixed(2);
              return LineTooltipItem(
                '$dateLabel\n$valStr',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),

        // ── 網格 ────────────────────────────────────────────────────────
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              ((chartMaxY - chartMinY) / 4).abs().clamp(0.5, double.infinity),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
          checkToShowHorizontalLine: (value) {
            // 零軸加深顯示
            if ((value).abs() < 0.01) return true;
            return true;
          },
        ),

        // ── 外框 ────────────────────────────────────────────────────────
        borderData: FlBorderData(show: false),

        // ── 座標軸標題 ────────────────────────────────────────────────
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                final label = _metric == _Metric.breadth
                    ? '${value.toStringAsFixed(0)}%'
                    : value.toStringAsFixed(0);
                return Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (vals.length / 4).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= widget.history.length) {
                  return const SizedBox.shrink();
                }
                final raw = widget.history[idx].tradeDate;
                final label = raw.length >= 8
                    ? '${raw.substring(4, 6)}/${raw.substring(6, 8)}'
                    : raw;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style:
                        TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                );
              },
            ),
          ),
        ),

        // ── 折線資料 ────────────────────────────────────────────────────
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) =>
                  spot.x == barData.spots.last.x, // 只顯示最新端點
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: isPositiveTrend ? 0.18 : 0.10),
                  color.withValues(alpha: 0.00),
                ],
              ),
            ),
          ),
        ],

        // 零參考線（若數值跨越正負）
        extraLinesData: (chartMinY < 0 && chartMaxY > 0)
            ? ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: Colors.grey.shade400,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                    labelResolver: (_) => '零軸',
                  ),
                ),
              ])
            : null,
      ),
    );
  }
}
