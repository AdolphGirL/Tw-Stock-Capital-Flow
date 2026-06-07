import 'package:flutter/foundation.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/domain/engines/lifecycle_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/mainstream_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/market_sentiment_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/rotation_engine.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/services/capital_flow_analyzer.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

// ── Isolate 傳入參數包裝型別 ────────────────────────────────────────────────
// compute() 僅接受單一參數，需以下型別將多參數打包後傳入 Isolate。

class _CapitalFlowBundle {
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final int listedRiseCount;
  final int listedFallCount;
  final int otcRiseCount;
  final int otcFallCount;
  final double listedScore;
  final double otcScore;

  const _CapitalFlowBundle({
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.listedScore,
    required this.otcScore,
  });
}

class _LifecyclePayload {
  final List<StockDaySnapshot> snapshots;
  final List<MainstreamResult> mainstreams;
  const _LifecyclePayload(this.snapshots, this.mainstreams);
}

class _SentimentPayload {
  final List<StockDaySnapshot> snapshots;
  final List<MainstreamResult> mainstreams;
  const _SentimentPayload(this.snapshots, this.mainstreams);
}

// ── Isolate 入口函數（compute() 要求 top-level 或 static function）──────────

_CapitalFlowBundle _runCapitalFlow(List<StockDaySnapshot> snapshots) {
  final a = CapitalFlowAnalyzer(snapshots: snapshots);
  return _CapitalFlowBundle(
    listedCategories: a.analyzeMainCategories(market: MarketType.listed),
    otcCategories: a.analyzeMainCategories(market: MarketType.otc),
    listedRiseCount: a.calculateRiseCount(market: MarketType.listed),
    listedFallCount: a.calculateFallCount(market: MarketType.listed),
    otcRiseCount: a.calculateRiseCount(market: MarketType.otc),
    otcFallCount: a.calculateFallCount(market: MarketType.otc),
    listedScore: a.calculateMarketScore(market: MarketType.listed),
    otcScore: a.calculateMarketScore(market: MarketType.otc),
  );
}

List<MainstreamResult> _runMainstream(List<StockDaySnapshot> snapshots) =>
    MainstreamEngine(snapshots: snapshots).analyze();

List<RotationResult> _runRotation(List<StockDaySnapshot> snapshots) =>
    RotationEngine(snapshots: snapshots).analyze();

List<LifecycleResult> _runLifecycle(_LifecyclePayload p) =>
    LifecycleEngine(snapshots: p.snapshots, mainstreams: p.mainstreams).analyze();

MarketSentimentResult _runSentiment(_SentimentPayload p) =>
    MarketSentimentEngine(snapshots: p.snapshots, mainstreams: p.mainstreams).analyze();

// ── BootstrapAnalyzer ───────────────────────────────────────────────────────

class BootstrapAnalyzer {
  /// 同步路徑：五引擎順序執行於同一 Isolate（向下相容，由 [analyzeAsync] 取代）。
  static AppBootstrapResult analyze(List<StockDaySnapshot> snapshots) {
    final analyzer = CapitalFlowAnalyzer(snapshots: snapshots);
    final mainstreams = MainstreamEngine(snapshots: snapshots).analyze();
    return AppBootstrapResult(
      listedCategories: analyzer.analyzeMainCategories(market: MarketType.listed),
      otcCategories: analyzer.analyzeMainCategories(market: MarketType.otc),
      listedRiseCount: analyzer.calculateRiseCount(market: MarketType.listed),
      listedFallCount: analyzer.calculateFallCount(market: MarketType.listed),
      otcRiseCount: analyzer.calculateRiseCount(market: MarketType.otc),
      otcFallCount: analyzer.calculateFallCount(market: MarketType.otc),
      listedScore: analyzer.calculateMarketScore(market: MarketType.listed),
      otcScore: analyzer.calculateMarketScore(market: MarketType.otc),
      mainstreams: mainstreams,
      lifecycles: LifecycleEngine(
        snapshots: snapshots,
        mainstreams: mainstreams,
      ).analyze(),
      rotations: RotationEngine(snapshots: snapshots).analyze(),
      sentiment: MarketSentimentEngine(
        snapshots: snapshots,
        mainstreams: mainstreams,
      ).analyze(),
    );
  }

  /// 並行異步路徑：依引擎依賴圖分兩階段，每個引擎獨立跑在自己的 Isolate 中。
  ///
  /// Phase 1（並行）：CapitalFlow、Mainstream、Rotation 三者互不依賴，同時啟動。
  /// Phase 2（並行）：Lifecycle 與 Sentiment 皆依賴 Phase 1 的 mainstreams，
  ///                 等 Phase 1 完成後同時啟動。
  static Future<AppBootstrapResult> analyzeAsync(
    List<StockDaySnapshot> snapshots,
  ) async {
    final (capitalFlow, mainstreams, rotations) = await (
      compute(_runCapitalFlow, snapshots),
      compute(_runMainstream, snapshots),
      compute(_runRotation, snapshots),
    ).wait;

    final (lifecycles, sentiment) = await (
      compute(_runLifecycle, _LifecyclePayload(snapshots, mainstreams)),
      compute(_runSentiment, _SentimentPayload(snapshots, mainstreams)),
    ).wait;

    return AppBootstrapResult(
      listedCategories: capitalFlow.listedCategories,
      otcCategories: capitalFlow.otcCategories,
      listedRiseCount: capitalFlow.listedRiseCount,
      listedFallCount: capitalFlow.listedFallCount,
      otcRiseCount: capitalFlow.otcRiseCount,
      otcFallCount: capitalFlow.otcFallCount,
      listedScore: capitalFlow.listedScore,
      otcScore: capitalFlow.otcScore,
      mainstreams: mainstreams,
      lifecycles: lifecycles,
      rotations: rotations,
      sentiment: sentiment,
    );
  }
}
