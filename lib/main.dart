import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/ui/theme/app_theme.dart';
import 'package:tw_stock_capital_flow/managers/sync_manager.dart';
import 'package:tw_stock_capital_flow/models/stock_data.dart';
import 'package:tw_stock_capital_flow/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/services/storage_service.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/ui/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();

  final syncManager = SyncManager(
    storageService: storageService,
    calendarService: MarketCalendarService(),
  );

  await syncManager.syncTodayData();

  final historyRepository = HistoryRepository(storageService: storageService);

  final snapshots = await historyRepository.loadRecentSnapshots(1);

  if (snapshots.isEmpty) {
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('無歷史資料'))),
      ),
    );

    return;
  }

  final latest = snapshots.first;

  final listedStocks = latest.stocks
      .where((e) => e.market == MarketType.listed)
      .toList();

  final otcStocks = latest.stocks
      .where((e) => e.market == MarketType.otc)
      .toList();

  final listedCategories = buildMainCategoryModels(listedStocks);

  final otcCategories = buildMainCategoryModels(otcStocks);

  runApp(
    MyApp(
      listedCategories: listedCategories,
      otcCategories: otcCategories,
      listedRiseCount: listedStocks.where((e) => e.changePercent > 0).length,
      listedFallCount: listedStocks.where((e) => e.changePercent < 0).length,
      otcRiseCount: otcStocks.where((e) => e.changePercent > 0).length,
      otcFallCount: otcStocks.where((e) => e.changePercent < 0).length,
      listedScore: calculateMarketScore(listedStocks),
      otcScore: calculateMarketScore(otcStocks),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CategoryUiModel> listedCategories;

  final List<CategoryUiModel> otcCategories;

  final int listedRiseCount;

  final int listedFallCount;

  final int otcRiseCount;

  final int otcFallCount;

  final double listedScore;

  final double otcScore;

  const MyApp({
    super.key,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.listedScore,
    required this.otcScore,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: HomePage(
        listedCategories: listedCategories,
        otcCategories: otcCategories,
        listedRiseCount: listedRiseCount,
        listedFallCount: listedFallCount,
        listedScore: listedScore,
        otcRiseCount: otcRiseCount,
        otcFallCount: otcFallCount,
        otcScore: otcScore,
      ),
    );
  }
}

List<CategoryUiModel> buildMainCategoryModels(List<StockData> stocks) {
  final Map<String, List<StockData>> grouped = {};

  for (final stock in stocks) {
    grouped.putIfAbsent(stock.mainCategory, () => []);

    grouped[stock.mainCategory]!.add(stock);
  }

  final List<CategoryUiModel> result = [];

  for (final entry in grouped.entries) {
    final categoryStocks = entry.value;

    final riseCount = categoryStocks.where((e) => e.changePercent > 0).length;

    final fallCount = categoryStocks.where((e) => e.changePercent < 0).length;

    final subCategories = buildSubCategoryModels(categoryStocks);

    result.add(
      CategoryUiModel(
        name: entry.key,

        totalCount: categoryStocks.length,

        riseCount: riseCount,

        fallCount: fallCount,

        score: calculateCategoryScore(categoryStocks),

        children: subCategories,
      ),
    );
  }

  result.sort((a, b) => b.score.compareTo(a.score));

  return result;
}

List<CategoryUiModel> buildSubCategoryModels(List<StockData> stocks) {
  final Map<String, List<StockData>> grouped = {};

  for (final stock in stocks) {
    grouped.putIfAbsent(stock.subCategory, () => []);

    grouped[stock.subCategory]!.add(stock);
  }

  final List<CategoryUiModel> result = [];

  for (final entry in grouped.entries) {
    final categoryStocks = entry.value;

    final riseCount = categoryStocks.where((e) => e.changePercent > 0).length;

    final fallCount = categoryStocks.where((e) => e.changePercent < 0).length;

    result.add(
      CategoryUiModel(
        name: entry.key,

        totalCount: categoryStocks.length,

        riseCount: riseCount,

        fallCount: fallCount,

        score: calculateCategoryScore(categoryStocks),

        stocks: categoryStocks
            .map(
              (e) => StockUiModel(
                stock: e,
                score: e.changePercent * (e.value / 100000000),
              ),
            )
            .toList(),
      ),
    );
  }

  result.sort((a, b) => b.score.compareTo(a.score));

  return result;
}

double calculateCategoryScore(List<StockData> stocks) {
  if (stocks.isEmpty) {
    return 0;
  }

  double total = 0;

  for (final stock in stocks) {
    total += stock.changePercent * (stock.value / 100000000);
  }

  return total / stocks.length;
}

double calculateMarketScore(List<StockData> stocks) {
  if (stocks.isEmpty) {
    return 0;
  }

  double total = 0;

  for (final stock in stocks) {
    total += stock.changePercent * (stock.value / 100000000);
  }

  return total / stocks.length;
}
