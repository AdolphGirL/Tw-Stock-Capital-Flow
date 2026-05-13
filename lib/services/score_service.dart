import 'dart:math';

import 'package:tw_stock_capital_flow/models/stock_data.dart';
import 'package:tw_stock_capital_flow/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/models/stock_score.dart';

class ScoreService {
  List<StockScore> calculateScores({
    required List<StockData> today,
    required List<StockDaySnapshot> history,
  }) {
    final List<StockScore> result = [];

    for (final stock in today) {
      final avgAmount = _calculateAverageAmount(
        code: stock.code,
        history: history,
      );

      if (avgAmount <= 0) {
        continue;
      }

      final amountRatio = stock.value / avgAmount;

      final priceScore = tanh(stock.changePercent / 5);

      final finalScore = amountRatio * priceScore;

      result.add(
        StockScore(
          code: stock.code,
          name: stock.name,
          amountRatio: amountRatio,
          priceScore: priceScore,
          finalScore: finalScore,
        ),
      );
    }

    result.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    return result;
  }

  double _calculateAverageAmount({
    required String code,
    required List<StockDaySnapshot> history,
  }) {
    double total = 0;

    int count = 0;

    for (final day in history) {
      try {
        final stock = day.stocks.firstWhere((e) => e.code == code);

        total += stock.value;

        count++;
      } catch (_) {}
    }

    if (count == 0) {
      return 0;
    }

    return total / count;
  }

  double tanh(double x) {
    return (exp(x) - exp(-x)) / (exp(x) + exp(-x));
  }
}
