import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/core/extensions/list_extension.dart';
import 'package:tw_stock_capital_flow/data/models/flow_signal.dart';

class CapitalFlowEngine {
  final List<StockDaySnapshot> snapshots;

  const CapitalFlowEngine({required this.snapshots});

  FlowSignal analyze(StockData stock) {
    final histories = _findStockHistory(stock.code);

    if (histories.isEmpty) {
      return const FlowSignal(
        score: 0,
        volumeRatio: 0,
        momentumScore: 0,
        persistenceScore: 0,
        direction: FlowDirection.neutral,
      );
    }

    final today = histories.first;

    final avgValue = histories
        .map((e) => e.value.toDouble())
        .toList()
        .average();

    final double volumeRatio = avgValue == 0 ? 0 : today.value / avgValue;

    final priceMomentum = today.changePercent;

    final volatility =
        ((today.high - today.low) / (today.close == 0 ? 1 : today.close)) * 100;

    final momentumScore = (priceMomentum * 0.7) + (volatility * 0.3);

    final persistenceScore = _calculatePersistence(histories);

    final flowScore =
        (volumeRatio * 0.35) +
        (momentumScore * 0.40) +
        (persistenceScore * 0.25);

    final direction = flowScore > 1
        ? FlowDirection.inflow
        : flowScore < -1
        ? FlowDirection.outflow
        : FlowDirection.neutral;

    return FlowSignal(
      score: flowScore,

      volumeRatio: volumeRatio,

      momentumScore: momentumScore,

      persistenceScore: persistenceScore,

      direction: direction,
    );
  }

  List<StockData> _findStockHistory(String code) {
    final List<StockData> result = [];

    for (final snapshot in snapshots) {
      try {
        final stock = snapshot.stocks.firstWhere((e) => e.code == code);

        result.add(stock);
      } catch (_) {}
    }

    return result;
  }

  double _calculatePersistence(List<StockData> histories) {
    if (histories.length <= 1) {
      return 0;
    }

    int positiveDays = 0;

    for (final stock in histories) {
      if (stock.changePercent > 0) {
        positiveDays++;
      }
    }

    final persistence = positiveDays / histories.length;

    final latest = histories.first.changePercent;

    return latest * persistence;
  }
}
