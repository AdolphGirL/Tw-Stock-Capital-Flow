import 'package:tw_stock_capital_flow/models/stock_data.dart';

class CategoryUiModel {
  final String name;

  final int totalCount;

  final int riseCount;

  final int fallCount;

  final double score;

  final double day1Score;

  final double day2Score;

  final double day3Score;

  final double hotScore;

  final double persistence;

  final List<CategoryUiModel> children;

  final List<StockUiModel> stocks;

  CategoryUiModel({
    required this.name,
    required this.totalCount,
    required this.riseCount,
    required this.fallCount,
    required this.score,
    required this.day1Score,
    required this.day2Score,
    required this.day3Score,
    required this.hotScore,
    required this.persistence,
    this.children = const [],
    this.stocks = const [],
  });

  // 真正三日趨勢強度
  double get trendStrength {
    // 權重：
    // 今日 50%
    // 昨日 30%
    // 前日 20%

    final weighted = (day1Score * 0.5) + (day2Score * 0.3) + (day3Score * 0.2);

    // 趨勢加速度
    final acceleration =
        (day1Score - day2Score) + ((day2Score - day3Score) * 0.5);

    return weighted + acceleration;
  }

  // 是否為持續增強
  bool get isStrengthening {
    return day1Score > day2Score && day2Score > day3Score;
  }

  // 是否為持續衰退
  bool get isWeakening {
    return day1Score < day2Score && day2Score < day3Score;
  }

  String get hotLevel {
    final score = hotScore;

    if (score >= 80) {
      return '爆發';
    }

    if (score >= 50) {
      return '強勢';
    }

    if (score >= 20) {
      return '偏強';
    }

    if (score >= 0) {
      return '整理';
    }

    return '退潮';
  }
}

class StockUiModel {
  final StockData stock;

  final double score;

  StockUiModel({required this.stock, required this.score});
}
