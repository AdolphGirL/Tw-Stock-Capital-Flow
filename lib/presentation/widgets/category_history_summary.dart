import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

/// 顯示板塊最近 N 天歷史趨勢摘要（vs 昨日、均值比較、連漲/跌天數）。
/// 使用 FutureBuilder 異步加載，不影響頁面主渲染。
class CategoryHistorySummary extends StatelessWidget {
  final CategoryHistoryRepository historyRepository;
  final String categoryName;
  final int days;

  const CategoryHistorySummary({
    super.key,
    required this.historyRepository,
    required this.categoryName,
    this.days = 5,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: historyRepository.getCategoryTrend(categoryName, limit: days),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final history = snapshot.data!; // 由舊到新
        final scores = history.map((e) => e.trendStrength).toList();
        final latest = scores.last;
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        final delta = scores.length >= 2
            ? latest - scores[scores.length - 2]
            : 0.0;
        final vsAvg = latest - avg;

        // 計算連漲/跌天數
        int streak = 0;
        if (scores.length >= 2) {
          final goingUp = scores.last > scores[scores.length - 2];
          for (int i = scores.length - 1; i > 0; i--) {
            if (goingUp && scores[i] > scores[i - 1]) {
              streak++;
            } else if (!goingUp && scores[i] < scores[i - 1]) {
              streak++;
            } else {
              break;
            }
          }
        }
        final isUp = delta >= 0;
        final streakLabel = streak >= 2
            ? '連${isUp ? "升" : "跌"}$streak日'
            : null;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip(
                isUp ? '▲ 較昨日 +${delta.toStringAsFixed(1)}' : '▼ 較昨日 ${delta.toStringAsFixed(1)}',
                isUp ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                isUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              ),
              _chip(
                vsAvg >= 0
                    ? '優於${scores.length}日均 +${vsAvg.toStringAsFixed(1)}'
                    : '低於${scores.length}日均 ${vsAvg.toStringAsFixed(1)}',
                vsAvg >= 0 ? const Color(0xFF0D47A1) : const Color(0xFF4E342E),
                vsAvg >= 0 ? const Color(0xFFE3F2FD) : const Color(0xFFFBE9E7),
              ),
              if (streakLabel != null)
                _chip(
                  streakLabel,
                  streak >= 3
                      ? (isUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828))
                      : const Color(0xFF616161),
                  streak >= 3
                      ? (isUp ? const Color(0xFFF1F8E9) : const Color(0xFFFFF3E0))
                      : const Color(0xFFF5F5F5),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
