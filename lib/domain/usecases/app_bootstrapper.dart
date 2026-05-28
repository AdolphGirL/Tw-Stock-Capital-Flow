import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/domain/engines/lifecycle_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/mainstream_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/market_sentiment_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/rotation_engine.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/data/services/capital_flow_analyzer.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';

class AppBootstrapper {
  static Future<AppBootstrapResult> bootstrap() async {
    final storageService = StorageService();

    final historyRepository = HistoryRepository(storageService: storageService);

    final snapshots = await historyRepository.loadRecentSnapshots(5);

    if (snapshots.isEmpty) {
      throw Exception('無歷史資料');
    }

    final analyzer = CapitalFlowAnalyzer(snapshots: snapshots);

    final listedCategories = analyzer.analyzeMainCategories(
      market: MarketType.listed,
    );

    final otcCategories = analyzer.analyzeMainCategories(
      market: MarketType.otc,
    );

    final mainstreams = MainstreamEngine(snapshots: snapshots).analyze();

    final lifecycles = LifecycleEngine(
      snapshots: snapshots,
      mainstreams: mainstreams,
    ).analyze();

    final rotations = RotationEngine(snapshots: snapshots).analyze();

    final sentiment = MarketSentimentEngine(
      snapshots: snapshots,
      mainstreams: mainstreams,
    ).analyze();

    return AppBootstrapResult(
      listedCategories: listedCategories,

      otcCategories: otcCategories,

      listedRiseCount: analyzer.calculateRiseCount(market: MarketType.listed),

      listedFallCount: analyzer.calculateFallCount(market: MarketType.listed),

      otcRiseCount: analyzer.calculateRiseCount(market: MarketType.otc),

      otcFallCount: analyzer.calculateFallCount(market: MarketType.otc),

      listedScore: analyzer.calculateMarketScore(market: MarketType.listed),

      otcScore: analyzer.calculateMarketScore(market: MarketType.otc),

      mainstreams: mainstreams,

      lifecycles: lifecycles,

      rotations: rotations,

      sentiment: sentiment,
    );
  }
}
