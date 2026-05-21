import 'package:tw_stock_capital_flow/models/stock_data.dart';
import 'package:tw_stock_capital_flow/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/core/models/mainstream_result.dart';

class MainstreamEngine {
  final List<StockDaySnapshot> snapshots;

  const MainstreamEngine({required this.snapshots});

  List<MainstreamResult> analyzeMainstreams() {
    if (snapshots.isEmpty) {
      return [];
    }

    final latest = snapshots.first;

    final Map<String, List<StockData>> grouped = {};

    for (final stock in latest.stocks) {
      grouped.putIfAbsent(stock.mainCategory, () => []);

      grouped[stock.mainCategory]!.add(stock);
    }

    final List<MainstreamResult> results = [];

    for (final entry in grouped.entries) {
      final category = entry.key;

      final stocks = entry.value;

      final flowScore = _calculateFlowScore(stocks);

      final persistenceScore = _calculatePersistence(category);

      final diffusionScore = _calculateDiffusion(stocks);

      final leaderScore = _calculateLeaderScore(stocks);

      final mainstreamScore =
          (flowScore * 0.35) +
          (persistenceScore * 0.30) +
          (diffusionScore * 0.20) +
          (leaderScore * 0.15);

      final strengthening = persistenceScore > 0 && flowScore > 0;

      final weakening = persistenceScore < 0 && flowScore < 0;

      results.add(
        MainstreamResult(
          category: category,

          mainstreamScore: mainstreamScore,

          flowScore: flowScore,

          persistenceScore: persistenceScore,

          diffusionScore: diffusionScore,

          leaderScore: leaderScore,

          strengthening: strengthening,

          weakening: weakening,
        ),
      );
    }

    results.sort((a, b) => b.mainstreamScore.compareTo(a.mainstreamScore));

    return results;
  }

  double _calculateFlowScore(List<StockData> stocks) {
    if (stocks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final stock in stocks) {
      final score = stock.changePercent * (stock.value / 100000000);

      total += score;
    }

    return total / stocks.length;
  }

  double _calculatePersistence(String category) {
    if (snapshots.length < 3) {
      return 0;
    }

    final List<double> scores = [];

    for (final snapshot in snapshots.take(3)) {
      final stocks = snapshot.stocks
          .where((e) => e.mainCategory == category)
          .toList();

      if (stocks.isEmpty) {
        continue;
      }

      double score = 0;

      for (final stock in stocks) {
        score += stock.changePercent * (stock.value / 100000000);
      }

      scores.add(score / stocks.length);
    }

    if (scores.length < 3) {
      return 0;
    }

    return (scores[0] * 0.5) + (scores[1] * 0.3) + (scores[2] * 0.2);
  }

  double _calculateDiffusion(List<StockData> stocks) {
    if (stocks.isEmpty) {
      return 0;
    }

    final rising = stocks.where((e) => e.changePercent > 0).length;

    return rising / stocks.length * 100;
  }

  double _calculateLeaderScore(List<StockData> stocks) {
    if (stocks.isEmpty) {
      return 0;
    }

    stocks.sort((a, b) => b.value.compareTo(a.value));

    final leader = stocks.first;

    final valueScore = leader.value / 100000000;

    final momentumScore = leader.changePercent;

    return (valueScore * 0.6) + (momentumScore * 0.4);
  }
}
