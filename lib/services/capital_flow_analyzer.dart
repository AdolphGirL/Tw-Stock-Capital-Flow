import 'package:tw_stock_capital_flow/models/stock_data.dart';
import 'package:tw_stock_capital_flow/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/core/engines/capital_flow_engine.dart';

class CapitalFlowAnalyzer {
  final List<StockDaySnapshot> snapshots;

  CapitalFlowAnalyzer({required this.snapshots});

  List<CategoryUiModel> analyzeMainCategories({required MarketType market}) {
    if (snapshots.isEmpty) {
      return [];
    }

    final latest = snapshots[0];

    final latestStocks = latest.stocks
        .where((e) => e.market == market)
        .toList();

    final Map<String, List<StockData>> grouped = {};

    for (final stock in latestStocks) {
      grouped.putIfAbsent(stock.mainCategory, () => []);

      grouped[stock.mainCategory]!.add(stock);
    }

    final List<CategoryUiModel> result = [];

    for (final entry in grouped.entries) {
      final categoryName = entry.key;

      final categoryStocks = entry.value;

      final riseCount = categoryStocks.where((e) => e.changePercent > 0).length;

      final fallCount = categoryStocks.where((e) => e.changePercent < 0).length;

      final day1 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 0,
        mainCategory: true,
      );

      final day2 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 1,
        mainCategory: true,
      );

      final day3 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 2,
        mainCategory: true,
      );

      final subCategories = analyzeSubCategories(
        market: market,
        mainCategory: categoryName,
      );

      final trendStrength =
          ((day1 * 0.5) + (day2 * 0.3) + (day3 * 0.2)) +
          ((day1 - day2) + ((day2 - day3) * 0.5));

      result.add(
        CategoryUiModel(
          name: categoryName,

          totalCount: categoryStocks.length,

          riseCount: riseCount,

          fallCount: fallCount,

          score: day1,

          day1Score: day1,

          day2Score: day2,

          day3Score: day3,

          children: subCategories,

          hotScore: trendStrength,

          persistence: (day1 + day2 + day3) / 3,
        ),
      );
    }

    result.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    return result;
  }

  List<CategoryUiModel> analyzeSubCategories({
    required MarketType market,
    required String mainCategory,
  }) {
    if (snapshots.isEmpty) {
      return [];
    }

    final latest = snapshots[0];

    final latestStocks = latest.stocks
        .where((e) => e.market == market && e.mainCategory == mainCategory)
        .toList();

    final Map<String, List<StockData>> grouped = {};

    for (final stock in latestStocks) {
      grouped.putIfAbsent(stock.subCategory, () => []);

      grouped[stock.subCategory]!.add(stock);
    }

    final List<CategoryUiModel> result = [];

    for (final entry in grouped.entries) {
      final categoryName = entry.key;

      final categoryStocks = entry.value;

      final riseCount = categoryStocks.where((e) => e.changePercent > 0).length;

      final fallCount = categoryStocks.where((e) => e.changePercent < 0).length;

      final day1 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 0,
        mainCategory: false,
      );

      final day2 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 1,
        mainCategory: false,
      );

      final day3 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 2,
        mainCategory: false,
      );

      final trendStrength =
          ((day1 * 0.5) + (day2 * 0.3) + (day3 * 0.2)) +
          ((day1 - day2) + ((day2 - day3) * 0.5));

      result.add(
        CategoryUiModel(
          name: categoryName,

          totalCount: categoryStocks.length,

          riseCount: riseCount,

          fallCount: fallCount,

          score: day1,

          day1Score: day1,

          day2Score: day2,

          day3Score: day3,

          stocks: categoryStocks
              .map(
                (e) => StockUiModel(stock: e, score: _calculateStockScore(e)),
              )
              .toList(),
          hotScore: trendStrength,

          persistence: (day1 + day2 + day3) / 3,
        ),
      );
    }

    result.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    return result;
  }

  double _calculateCategoryScore({
    required String categoryName,
    required MarketType market,
    required int dayOffset,
    required bool mainCategory,
  }) {
    if (dayOffset >= snapshots.length) {
      return 0;
    }

    final snapshot = snapshots[dayOffset];

    final stocks = snapshot.stocks.where((e) {
      final matchedCategory = mainCategory
          ? e.mainCategory == categoryName
          : e.subCategory == categoryName;

      return e.market == market && matchedCategory;
    }).toList();

    if (stocks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final stock in stocks) {
      total += _calculateStockScore(stock);
    }

    return total / stocks.length;
  }

  double _calculateStockScore(StockData stock) {
    final engine = CapitalFlowEngine(snapshots: snapshots);

    final signal = engine.analyzeStock(stock);

    return signal.score;
  }

  double calculateMarketScore({required MarketType market}) {
    if (snapshots.isEmpty) {
      return 0;
    }

    final latest = snapshots[0];

    final stocks = latest.stocks.where((e) => e.market == market).toList();

    if (stocks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final stock in stocks) {
      total += _calculateStockScore(stock);
    }

    return total / stocks.length;
  }

  int calculateRiseCount({required MarketType market}) {
    if (snapshots.isEmpty) {
      return 0;
    }

    return snapshots[0].stocks
        .where((e) => e.market == market && e.changePercent > 0)
        .length;
  }

  int calculateFallCount({required MarketType market}) {
    if (snapshots.isEmpty) {
      return 0;
    }

    return snapshots[0].stocks
        .where((e) => e.market == market && e.changePercent < 0)
        .length;
  }
}
