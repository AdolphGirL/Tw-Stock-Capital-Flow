import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/institutional_flow_result.dart';

enum _Entity { foreign, trust, dealer, total }

/// 三大法人 N 日每日淨流向長條圖。
/// history 須由舊到新排序（index 0 = 最舊）。
class InstitutionalFlowChart extends StatefulWidget {
  final List<InstitutionalFlowResult> history;

  const InstitutionalFlowChart({super.key, required this.history});

  @override
  State<InstitutionalFlowChart> createState() => _InstitutionalFlowChartState();
}

class _InstitutionalFlowChartState extends State<InstitutionalFlowChart> {
  _Entity _entity = _Entity.total;

  // ── 資料存取 ────────────────────────────────────────────────────────────────

  double _netOf(InstitutionalFlowResult r, _Entity e) {
    switch (e) {
      case _Entity.foreign: return r.foreign.netYi;
      case _Entity.trust:   return r.trust.netYi;
      case _Entity.dealer:  return r.dealer.netYi;
      case _Entity.total:   return r.total.netYi;
    }
  }

  String _entityLabel(_Entity e) {
    switch (e) {
      case _Entity.foreign: return '外資';
      case _Entity.trust:   return '投信';
      case _Entity.dealer:  return '自營商';
      case _Entity.total:   return '合計';
    }
  }

  // ── 建構 ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nets = widget.history.map((r) => _netOf(r, _entity)).toList();
    final cumulative = nets.fold<double>(0.0, (sum, v) => sum + v);
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
              '累計 ${isPosCum ? "+" : ""}${cumulative.toStringAsFixed(1)} 億',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPosCum ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(height: 160, child: _buildBarChart(nets)),
      ],
    );
  }

  // ── BarChart ────────────────────────────────────────────────────────────────

  Widget _buildBarChart(List<double> nets) {
    if (nets.isEmpty) {
      return const Center(
        child: Text('資料不足', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    final maxAbs = nets.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    final maxY = maxAbs * 1.25;
    final minY = -maxY;

    final groups = nets.asMap().entries.map((e) {
      final net = e.value;
      final color = net >= 0 ? const Color(0xFFEF5350) : const Color(0xFF43A047);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: net,
            fromY: 0,
            color: color,
            width: _barWidth(nets.length),
            borderRadius: BorderRadius.vertical(
              top: net >= 0 ? const Radius.circular(3) : Radius.zero,
              bottom: net < 0 ? const Radius.circular(3) : Radius.zero,
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
              final net = rod.toY;
              return BarTooltipItem(
                '$label\n${net >= 0 ? "+" : ""}${net.toStringAsFixed(2)} 億',
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
              reservedSize: 36,
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
