import 'package:tw_stock_capital_flow/models/stock_data.dart';

class CategoryUiModel {
  final String name;

  final int totalCount;

  final int riseCount;

  final int fallCount;

  final double score;

  final List<CategoryUiModel> children;

  final List<StockUiModel> stocks;

  CategoryUiModel({
    required this.name,
    required this.totalCount,
    required this.riseCount,
    required this.fallCount,
    required this.score,
    this.children = const [],
    this.stocks = const [],
  });
}

class StockUiModel {
  final StockData stock;

  final double score;

  StockUiModel({required this.stock, required this.score});
}
