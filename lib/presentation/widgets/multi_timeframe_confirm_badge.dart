import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';

/// 多週期訊號確認徽章。
/// 載入 5 日 trendStrength，比較近 2 日均值 vs 前 3 日均值，判定週線方向。
/// BUY + 週線向上 → "✅ 週期確認"；BUY + 週線向下 → "⚠️ 逆週線"；
/// HOLD + 週線向下 → "週線降溫"。
class MultiTimeframeConfirmBadge extends StatelessWidget {
  final CategoryHistoryRepository historyRepository;
  final String categoryName;
  final StrategyAction action;

  const MultiTimeframeConfirmBadge({
    super.key,
    required this.historyRepository,
    required this.categoryName,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    if (action == StrategyAction.neutral) return const SizedBox.shrink();

    return FutureBuilder(
      future: historyRepository.getCategoryTrend(categoryName, limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.length < 4) {
          return const SizedBox.shrink();
        }
        final scores = snapshot.data!.map((e) => e.trendStrength).toList();
        // scores 由舊到新；比較近 2 日均值 vs 前幾日均值
        final n = scores.length;
        final recentAvg = (scores[n - 1] + scores[n - 2]) / 2;
        final olderSum = scores.take(n - 2).fold(0.0, (s, v) => s + v);
        final olderAvg = olderSum / (n - 2);
        final weeklyUp = recentAvg > olderAvg;

        if (action == StrategyAction.buy) {
          return weeklyUp
              ? _chip('✅ 週期確認', const Color(0xFF1B5E20), const Color(0xFFE8F5E9))
              : _chip('⚠️ 逆週線', const Color(0xFF856404), const Color(0xFFFFF8E1));
        }

        if (action == StrategyAction.hold && !weeklyUp) {
          return _chip('週線降溫', const Color(0xFFE65100), const Color(0xFFFFF3E0));
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _chip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
