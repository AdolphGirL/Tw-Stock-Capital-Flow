// import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';

/// 策略建議之行動型別
enum StrategyAction {
  buy, // 🟢 買進 / 進場
  hold, // 🟡 續抱 / 加碼
  sell, // 🔴 賣出 / 出清
  neutral, // ⚪ 觀望 / 無訊號
}

/// 單一板塊當前觸發的策略訊號
class StrategySignal {
  final String category;
  final StrategyAction action;
  final double score;
  final double trendStrength;
  final double persistence;
  final String reason;
  final String dateKey;

  StrategySignal({
    required this.category,
    required this.action,
    required this.score,
    required this.trendStrength,
    required this.persistence,
    required this.reason,
    required this.dateKey,
  });
}

/// 策略回測統計效能結果
class BacktestSummary {
  final String strategyName;
  final double totalReturn; // 總報酬率 (例如 0.25 代表 25%)
  final double winRate; // 勝率 (0.0 ~ 1.0)
  final int totalTrades; // 總交易次數
  final double maxDrawdown; // 最大回撤 (MDD)
  final List<StrategySignal> signalHistory;

  BacktestSummary({
    required this.strategyName,
    required this.totalReturn,
    required this.winRate,
    required this.totalTrades,
    required this.maxDrawdown,
    required this.signalHistory,
  });
}
