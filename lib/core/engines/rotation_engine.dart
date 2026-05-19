import 'package:tw_stock_capital_flow/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/core/extensions/list_extension.dart';
import 'package:tw_stock_capital_flow/models/rotation_result.dart';

class RotationEngine {
  final List<StockDaySnapshot> snapshots;

  const RotationEngine({required this.snapshots});

  List<RotationResult> analyzeMainCategoryRotation() {
    if (snapshots.length < 2) {
      return [];
    }

    final today = snapshots[0];

    final yesterday = snapshots[1];

    final todayScores = _calculateCategoryScores(today);

    final yesterdayScores = _calculateCategoryScores(yesterday);

    final List<MapEntry<String, double>> increases = [];

    final List<MapEntry<String, double>> decreases = [];

    for (final entry in todayScores.entries) {
      final yesterdayScore = yesterdayScores[entry.key] ?? 0;

      final diff = entry.value - yesterdayScore;

      if (diff > 0) {
        increases.add(MapEntry(entry.key, diff));
      } else {
        decreases.add(MapEntry(entry.key, diff.abs()));
      }
    }

    increases.sort((a, b) => b.value.compareTo(a.value));

    decreases.sort((a, b) => b.value.compareTo(a.value));

    final List<RotationResult> result = [];

    final length = increases.length < decreases.length
        ? increases.length
        : decreases.length;

    for (int i = 0; i < length; i++) {
      result.add(
        RotationResult(
          fromCategory: decreases[i].key,

          toCategory: increases[i].key,

          strength: increases[i].value,
        ),
      );
    }

    return result;
  }

  Map<String, double> _calculateCategoryScores(StockDaySnapshot snapshot) {
    final Map<String, List<double>> grouped = {};

    for (final stock in snapshot.stocks) {
      grouped.putIfAbsent(stock.mainCategory, () => []);

      final score = stock.changePercent * (stock.value / 100000000);

      grouped[stock.mainCategory]!.add(score);
    }

    final Map<String, double> result = {};

    for (final entry in grouped.entries) {
      result[entry.key] = entry.value.average();
    }

    return result;
  }
}
