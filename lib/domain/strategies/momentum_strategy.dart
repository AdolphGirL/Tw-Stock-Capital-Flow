import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';

class MomentumStrategy {
  final String name = "板塊七期動量續航策略";

  StrategySignal evaluate(LifecycleResult result, {required String dateKey}) {
    final String category = result.category;
    final LifecycleStage stage = result.stage;
    final double strength = result.strength;
    final double accel = result.acceleration;
    final double persist = result.persistence;
    final double diff = result.diffusion;
    final bool hasHotMoney = result.hotMoneyIn;

    // ==================== 🔴 0. 結構性出清（最高優先，不受其他指標影響）====================

    // 出貨期、退潮期、死亡期 → 無條件出清，這三個階段代表主力行為已反轉
    if (stage == LifecycleStage.distribution ||
        stage == LifecycleStage.decline ||
        stage == LifecycleStage.dead) {
      String reason = "🔴【風控警示・出清退場】";
      if (stage == LifecycleStage.distribution) {
        reason += "進入出貨期，主力已在高檔悄悄派發籌碼，切勿追高。";
      } else if (stage == LifecycleStage.decline) {
        reason += "進入退潮期，資金加速出走，多殺多恐慌盤開始。";
      } else {
        reason += "板塊進入死亡期，資金潰散，建議空倉回避。";
      }
      return StrategySignal(
        category: category,
        action: StrategyAction.sell,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason: reason,
        dateKey: dateKey,
      );
    }

    // ==================== 🟢 1. 買進與加碼訊號 ====================

    // 點火階段：熱錢剛流入且具備基礎加速度，建立底倉
    if (stage == LifecycleStage.ignition && hasHotMoney && accel > 0) {
      return StrategySignal(
        category: category,
        action: StrategyAction.buy,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason:
            "🟢【點火期・初試啼聲】熱錢實質流入，且動能具備正加速度(+${accel.toStringAsFixed(1)})，建議建立基本試單倉。",
        dateKey: dateKey,
      );
    }

    // 擴散或主升階段：熱錢在，板塊擴散度高（共振強），最強主升段加碼點
    if ((stage == LifecycleStage.expansion || stage == LifecycleStage.markup) &&
        hasHotMoney &&
        diff >= 50.0) {
      return StrategySignal(
        category: category,
        action: StrategyAction.buy,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason:
            "🟢🟢【主升擴張・全面加碼】熱錢持續駐留且板塊內部個股擴散度高達 ${diff.toStringAsFixed(0)}%，屬於結構極健康的共振噴出段，建議積極加碼。",
        dateKey: dateKey,
      );
    }

    // ==================== 🟡 2. 持股續抱訊號 ====================

    // 熱錢仍在，延續力達標 → 持股續抱（持續力門檻從 50 降至 40，避免誤殺震盪行情）
    if (hasHotMoney && persist >= 40.0) {
      if (stage == LifecycleStage.euphoric) {
        return StrategySignal(
          category: category,
          action: StrategyAction.hold,
          score: strength,
          trendStrength: strength,
          persistence: persist,
          reason:
              "🟠【狂熱期・禁止追高】雖然熱錢仍在，但市場情緒已達集體過熱期。持股可續抱，但此處絕對禁止新資金追加追高。",
          dateKey: dateKey,
        );
      }
      return StrategySignal(
        category: category,
        action: StrategyAction.hold,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason:
            "🟡【鎖籌續抱】延續力達 ${persist.toStringAsFixed(0)}，熱錢仍在板塊，主力籌碼穩固，持股續抱待噴。",
        dateKey: dateKey,
      );
    }

    // ==================== 🔴 3. 動能渙散出清（需兩項指標同時惡化）====================

    // 熱錢已撤 且 延續力極低 → 動能雙殺，出清
    // 注意：不再以 !hasHotMoney 單一條件觸發 SELL（修正過度敏感問題）
    if (!hasHotMoney && persist < 40.0) {
      return StrategySignal(
        category: category,
        action: StrategyAction.sell,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason:
            "🔴【動能渙散・出清退場】熱錢已撤離（資金方向轉負、上漲家數不足），且延續力跌至 ${persist.toStringAsFixed(0)}，拋壓嚴重，建議出清。",
        dateKey: dateKey,
      );
    }

    // ==================== ⚪ 4. 觀望盤整（無明確訊號）====================

    // 熱錢不足但延續力尚可（正在整理）；或盤整階段；或點火但無熱錢支撐
    String neutralReason = "⚪【盤整觀望】";
    if (stage == LifecycleStage.consolidation) {
      neutralReason += "板塊目前無明確方向，資金觀望為主，等待突破訊號再行動。";
    } else if (!hasHotMoney && persist >= 40.0) {
      neutralReason +=
          "資金方向尚未明朗，但延續力 ${persist.toStringAsFixed(0)} 仍在合理區間，可觀察是否有熱錢重新回流。";
    } else {
      neutralReason += "各項指標處於混沌拉鋸區，無明確多空方向，建議先觀望。";
    }

    return StrategySignal(
      category: category,
      action: StrategyAction.neutral,
      score: strength,
      trendStrength: strength,
      persistence: persist,
      reason: neutralReason,
      dateKey: dateKey,
    );
  }
}
