import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';

/// 代表一次訊號異動事件
class SignalChange {
  final String category;
  final String? previousAction; // null = 首次追蹤（新加入 watchlist 後第一次有記錄）
  final String newAction;

  const SignalChange({
    required this.category,
    required this.previousAction,
    required this.newAction,
  });

  /// 訊號等級：buy=3 > hold=2 > neutral=1 > sell=0
  static int _rank(String action) {
    switch (action) {
      case 'buy': return 3;
      case 'hold': return 2;
      case 'neutral': return 1;
      case 'sell': return 0;
      default: return 1;
    }
  }

  bool get isFirstTracking => previousAction == null;
  bool get isUpgrade =>
      !isFirstTracking && _rank(newAction) > _rank(previousAction!);
  bool get isDowngrade =>
      !isFirstTracking && _rank(newAction) < _rank(previousAction!);

  String get previousLabel => _label(previousAction ?? 'neutral');
  String get newLabel => _label(newAction);

  static String _label(String action) {
    switch (action) {
      case 'buy': return '買進';
      case 'hold': return '續抱';
      case 'sell': return '出清';
      case 'neutral': return '觀望';
      default: return action;
    }
  }
}

/// 純邏輯比對：傳入前次訊號記錄 + 今日演算結果 + 關注清單，回傳所有有異動的板塊
class SignalChangeDetector {
  List<SignalChange> detect({
    required Map<String, String> previousSignals,
    required List<StrategySignal> todaySignals,
    required List<String> watchedNames,
  }) {
    final watchedSet = watchedNames.toSet();
    final changes = <SignalChange>[];

    for (final signal in todaySignals) {
      if (!watchedSet.contains(signal.category)) continue;

      final prev = previousSignals[signal.category];
      final curr = signal.action.name;

      // 首次追蹤（沒有上次紀錄）：一律通知，讓使用者知道初始訊號
      // 有上次紀錄但訊號相同：不通知
      if (prev == null || prev != curr) {
        changes.add(SignalChange(
          category: signal.category,
          previousAction: prev,
          newAction: curr,
        ));
      }
    }

    // 升級的放前面（好消息先看），降級的放後面
    changes.sort((a, b) {
      final aScore = a.isFirstTracking ? 1 : (a.isUpgrade ? 2 : 0);
      final bScore = b.isFirstTracking ? 1 : (b.isUpgrade ? 2 : 0);
      return bScore.compareTo(aScore);
    });

    return changes;
  }
}
