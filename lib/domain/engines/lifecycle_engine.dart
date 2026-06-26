import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_timeline.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/trend_metrics.dart';
import 'package:tw_stock_capital_flow/domain/engines/trend_metrics_engine.dart';

class LifecycleEngine {
  final List<StockDaySnapshot> snapshots;

  final List<MainstreamResult> mainstreams;

  const LifecycleEngine({required this.snapshots, required this.mainstreams});

  List<LifecycleResult> analyze() {
    if (snapshots.isEmpty) {
      return [];
    }

    final trendEngine = TrendMetricsEngine();

    final List<LifecycleResult> results = [];

    for (final mainstream in mainstreams) {
      final timeline = _buildTimeline(mainstream.category);

      final scoreTrend = trendEngine.analyze(timeline.scores);

      final flowTrend = trendEngine.analyze(timeline.flows);

      final diffusionTrend = trendEngine.analyze(timeline.diffusions);

      final stage = _resolveStage(
        mainstream: mainstream,

        scoreTrend: scoreTrend,

        flowTrend: flowTrend,

        diffusionTrend: diffusionTrend,
      );

      final acceleration = scoreTrend.acceleration;

      // 使用方向性更明確的指標：漲幅×成交額加權積(flowScore) + 上漲家數比例(diffusion)
      // 原定義依賴 flowTrend.acceleration（量的加速度）和 diffusionTrend.slope，
      // 基於 5 天頭尾差，單日整理即翻轉，造成大量誤判出清訊號。
      final hotMoneyIn =
          mainstream.flowScore > 0 && mainstream.diffusionScore > 45;

      results.add(
        LifecycleResult(
          category: mainstream.category,

          stage: stage,

          strength: mainstream.mainstreamScore,

          acceleration: acceleration,

          persistence: mainstream.persistenceScore,

          diffusion: mainstream.diffusionScore,

          hotMoneyIn: hotMoneyIn,
        ),
      );
    }

    results.sort((a, b) => b.strength.compareTo(a.strength));

    return results;
  }

  LifecycleTimeline _buildTimeline(String category) {
    final List<double> scores = [];

    final List<double> flows = [];

    final List<double> diffusions = [];

    for (final snapshot in snapshots.reversed) {
      final categoryStocks = snapshot.stocks
          .where((e) => e.mainCategory == category)
          .toList();

      if (categoryStocks.isEmpty) {
        continue;
      }

      double score = 0;

      double flow = 0;

      int riseCount = 0;

      for (final stock in categoryStocks) {
        final valueScore = stock.value / 100000000;

        score += stock.changePercent * valueScore;

        flow += valueScore;

        if (stock.changePercent > 0) {
          riseCount++;
        }
      }

      score /= categoryStocks.length;

      flow /= categoryStocks.length;

      final diffusion = riseCount / categoryStocks.length * 100;

      scores.add(score);

      flows.add(flow);

      diffusions.add(diffusion);
    }

    return LifecycleTimeline(
      category: category,

      scores: scores,

      flows: flows,

      diffusions: diffusions,
    );
  }

  LifecycleStage _resolveStage({
    required MainstreamResult mainstream,

    required TrendMetrics scoreTrend,

    required TrendMetrics flowTrend,

    required TrendMetrics diffusionTrend,
  }) {
    final score = mainstream.mainstreamScore;

    final slope = scoreTrend.slope;

    final acceleration = scoreTrend.acceleration;

    final stability = scoreTrend.stability;

    final volatility = scoreTrend.volatility;

    final diffusion = mainstream.diffusionScore;

    final flow = mainstream.flowScore;

    // 死亡
    if (score < 10 && slope < 0 && flow < 0) {
      return LifecycleStage.dead;
    }

    // 退潮
    if (slope < 0 && acceleration < 0 && flow < 0) {
      return LifecycleStage.decline;
    }

    // 出貨
    if (score > 70 && acceleration < 0 && volatility > 15) {
      return LifecycleStage.distribution;
    }

    // 狂熱
    if (score > 85 && diffusion > 75 && volatility > 20) {
      return LifecycleStage.euphoric;
    }

    // 主升
    if (score > 60 && slope > 20 && stability > 70 && volatility < 18) {
      return LifecycleStage.markup;
    }

    // 擴散
    if (diffusion > 45 && slope > 10 && flowTrend.slope > 0) {
      return LifecycleStage.expansion;
    }

    // 點火：有明確加速訊號
    if (acceleration > 5 || flowTrend.acceleration > 0) {
      return LifecycleStage.ignition;
    }

    // 盤整：無明確訊號的板塊，觀望為主（原先錯誤地預設為「點火」）
    return LifecycleStage.consolidation;
  }
}
