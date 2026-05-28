import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';

import 'package:tw_stock_capital_flow/domain/enums/sentiment_level.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';

class MarketSentimentEngine {
  final List<StockDaySnapshot> snapshots;

  final List<MainstreamResult> mainstreams;

  const MarketSentimentEngine({
    required this.snapshots,
    required this.mainstreams,
  });

  MarketSentimentResult analyze() {
    if (snapshots.isEmpty) {
      return const MarketSentimentResult(
        score: 0,
        level: SentimentLevel.neutral,
        riseCount: 0,
        fallCount: 0,
        strongCategoryCount: 0,
        mainstreamAverage: 0,
        hotMoneyStrength: 0,
      );
    }

    final latest = snapshots.first;

    final riseCount = latest.stocks.where((e) => e.changePercent > 0).length;

    final fallCount = latest.stocks.where((e) => e.changePercent < 0).length;

    final riseRatio = latest.stocks.isEmpty
        ? 0
        : riseCount / latest.stocks.length;

    final strongCategoryCount = mainstreams
        .where((e) => e.mainstreamScore > 30)
        .length;

    double mainstreamAverage = 0;

    if (mainstreams.isNotEmpty) {
      mainstreamAverage =
          mainstreams.map((e) => e.mainstreamScore).reduce((a, b) => a + b) /
          mainstreams.length;
    }

    final hotMoneyStrength = _calculateHotMoney(latest);

    final score =
        (riseRatio * 30) +
        (strongCategoryCount * 8) +
        (mainstreamAverage * 0.35) +
        (hotMoneyStrength * 0.25);

    final level = _resolveLevel(score);

    return MarketSentimentResult(
      score: score,

      level: level,

      riseCount: riseCount,

      fallCount: fallCount,

      strongCategoryCount: strongCategoryCount,

      mainstreamAverage: mainstreamAverage,

      hotMoneyStrength: hotMoneyStrength,
    );
  }

  double _calculateHotMoney(StockDaySnapshot snapshot) {
    double total = 0;

    for (final stock in snapshot.stocks) {
      final valueScore = stock.value / 100000000;

      final momentum = stock.changePercent;

      total += valueScore * momentum;
    }

    return total / snapshot.stocks.length;
  }

  SentimentLevel _resolveLevel(double score) {
    if (score >= 85) {
      return SentimentLevel.euphoric;
    }

    if (score >= 65) {
      return SentimentLevel.optimistic;
    }

    if (score >= 40) {
      return SentimentLevel.neutral;
    }

    if (score >= 20) {
      return SentimentLevel.weak;
    }

    return SentimentLevel.panic;
  }
}
