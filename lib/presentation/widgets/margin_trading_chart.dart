import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/margin_trading_result.dart';

enum _Entity { margin, shortSale }

/// 融資融券餘額 N 日每日增減長條圖（單位：張）。
/// history 須由舊到新排序（index 0 = 最舊）。
class MarginTradingChart extends StatefulWidget {
  final List<MarginTradingResult> history;

  const MarginTradingChart({super.key, required this.history});

  @override
  State<MarginTradingChart> createState() => _MarginTradingChartState();
}

class _MarginTradingChartState extends State<MarginTradingChart> {
  _Entity _entity = _Entity.margin;

  // ── 資料存取 ────────────────────────────────────────────────────────────────

  double _changeOf(MarginTradingResult r, _Entity e) {
    switch (e) {
      case _Entity.margin:    return r.margin.changeLots;
      case _Entity.shortSale: return r.shortSale.changeLots;
    }
  }

  String _entityLabel(_Entity e) {
    switch (e) {
      case _Entity.margin:    return '融資';
      case _Entity.shortSale: return '融券';
    }
  }

  // ── 建構 ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final changes = widget.history.map((r) => _changeOf(r, _entity)).toList();
    final cumulative = changes.fold<double>(0.0, (sum, v) => sum + v);
    final isPosCum = cumulative >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Entity 切換 + 累積數字
        Row(
          children: [
            ..._Entity.values.map((e) {
              final sel = _entity == e;
              return GestureDetector(
                onTap: () => setState(() => _entity = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF5C6BC0) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? const Color(0xFF5C6BC0) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _entityLabel(e),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: sel ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              '累計 ${isPosCum ? "+" : ""}${cumulative.toStringAsFixed(0)} 張',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPosCum ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(height: 160, child: _buildBarChart(changes)),
      ],
    );
  }

  // ── BarChart ────────────────────────────────────────────────────────────────

  Widget _buildBarChart(List<double> changes) {
    if (changes.isEmpty) {
      return const Center(
        child: Text('資料不足', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    final maxAbs = changes.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    final maxY = maxAbs == 0 ? 1.0 : maxAbs * 1.25;
    final minY = -maxY;

    final groups = changes.asMap().entries.map((e) {
      final change = e.value;
      final color = change >= 0 ? const Color(0xFFEF5350) : const Color(0xFF43A047);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: change,
            fromY: 0,
            color: color,
            width: _barWidth(changes.length),
            borderRadius: BorderRadius.vertical(
              top: change >= 0 ? const Radius.circular(3) : Radius.zero,
              bottom: change < 0 ? const Radius.circular(3) : Radius.zero,
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        barGroups: groups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.clamp(0, widget.history.length - 1);
              final date = widget.history[idx].date;
              final label = date.length >= 8
                  ? '${date.substring(4, 6)}/${date.substring(6, 8)}'
                  : date;
              final change = rod.toY;
              return BarTooltipItem(
                '$label\n${change >= 0 ? "+" : ""}${change.toStringAsFixed(0)} 張',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 2 : 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= widget.history.length) return const SizedBox.shrink();
                // 只在首、中、末顯示日期避免擁擠
                final n = widget.history.length;
                final showAt = {0, n ~/ 2, n - 1};
                if (!showAt.contains(idx)) return const SizedBox.shrink();
                final date = widget.history[idx].date;
                final label = date.length >= 8
                    ? '${date.substring(4, 6)}/${date.substring(6, 8)}'
                    : date;
                return Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                );
              },
            ),
          ),
        ),
        // 零軸基準線
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 0,
            color: Colors.grey.shade400,
            strokeWidth: 1,
          ),
        ]),
      ),
    );
  }

  double _barWidth(int count) {
    if (count <= 10) return 14;
    if (count <= 20) return 9;
    return 6;
  }
}
