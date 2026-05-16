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
    this.children = const [],
    this.stocks = const [],
  });

  double get trendStrength {
    return (day1Score * 0.5) + (day2Score * 0.3) + (day3Score * 0.2);
  }
}

class StockUiModel {
  final StockData stock;

  final double score;

  StockUiModel({required this.stock, required this.score});
}
