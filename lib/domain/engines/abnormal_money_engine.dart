import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/domain/models/abnormal_money_result.dart';

class AbnormalMoneyEngine {
  final List<StockDaySnapshot> snapshots;

  const AbnormalMoneyEngine({required this.snapshots});

  List<AbnormalMoneyResult> analyze() {
    if (snapshots.length < 3) {
      return [];
    }

    final latest = snapshots[0];

    final prev1 = snapshots[1];

    final prev2 = snapshots[2];

    final List<AbnormalMoneyResult> results = [];

    for (final stock in latest.stocks) {
      final old1 = _findStock(prev1, stock.code);

      final old2 = _findStock(prev2, stock.code);

      if (old1 == null || old2 == null) {
        continue;
      }

      final avgVolume = (old1.volume + old2.volume) / 2;

      final avgValue = (old1.value + old2.value) / 2;

      if (avgVolume <= 0 || avgValue <= 0) {
        continue;
      }

      final volumeRatio = stock.volume / avgVolume;

      final valueRatio = stock.value / avgValue;

      final momentumScore = stock.changePercent;

      final continuous =
          stock.changePercent > 0 &&
          old1.changePercent > 0 &&
          old2.changePercent > 0;

      final breakout = volumeRatio > 2 && momentumScore > 3;

      final moneyScore =
          (volumeRatio * 35) +
          (valueRatio * 35) +
          (momentumScore * 20) +
          (continuous ? 10 : 0);

      if (moneyScore < 80) {
        continue;
      }

      results.add(
        AbnormalMoneyResult(
          stock: stock,

          moneyScore: moneyScore,

          volumeRatio: volumeRatio,

          valueRatio: valueRatio,

          momentumScore: momentumScore,

          continuous: continuous,

          breakout: breakout,
        ),
      );
    }

    results.sort((a, b) => b.moneyScore.compareTo(a.moneyScore));

    return results;
  }

  StockData? _findStock(StockDaySnapshot snapshot, String code) {
    try {
      return snapshot.stocks.firstWhere((e) => e.code == code);
    } catch (_) {
      return null;
    }
  }
}
