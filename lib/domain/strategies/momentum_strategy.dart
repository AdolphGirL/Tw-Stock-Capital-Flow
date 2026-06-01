import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart'; // 確保路徑對齊
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';

class MomentumStrategy {
  final String name = "板塊七期動量續航策略";

  /// 🚀 核心演算法：精確對齊 LifecycleResult 的所有欄位進行判定
  StrategySignal evaluate(LifecycleResult result, {required String dateKey}) {
    final String category = result.category;
    final LifecycleStage stage = result.stage;
    final double strength = result.strength;
    final double accel = result.acceleration;
    final double persist = result.persistence;
    final double diff = result.diffusion;
    final bool hasHotMoney = result.hotMoneyIn;

    // ==================== 🟢 1. 買進與加碼訊號 (Buy) ====================

    // 點火階段：熱錢剛流入且具備基礎加速度，小資金建立底倉
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

    // 擴散或主升階段：熱錢在，且板塊擴散度高 (共振強)，最強主升段加碼點
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

    // ==================== 🟡 2. 持股續抱與警告訊號 (Hold) ====================

    // 主升或狂熱期：只要熱錢沒走，且延續力還在，就抱緊讓利潤奔跑，但狂熱期禁止追高
    if (hasHotMoney && persist >= 50.0) {
      if (stage == LifecycleStage.euphoric) {
        return StrategySignal(
          category: category,
          action: StrategyAction.hold,
          score: strength,
          trendStrength: strength,
          persistence: persist,
          reason: "🟠【狂熱期・禁止追高】雖然熱錢仍在，但市場情緒已達集體過熱期。持股可續抱，但此處絕對禁止新資金追加追高。",
          dateKey: dateKey,
        );
      }
      return StrategySignal(
        category: category,
        action: StrategyAction.hold,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason: "自由抱牢。延續力達 ${persist.toStringAsFixed(0)}，主力鎖籌穩固，持股續抱。",
        dateKey: dateKey,
      );
    }

    // ==================== 🔴 3. 賣出與出清訊號 (Sell) ====================

    // 出貨期、退潮期、死亡期，或者「熱錢一撤走」或「延續力極度渙散(<40)」，觸發無條件出清風控
    if (stage == LifecycleStage.distribution ||
        stage == LifecycleStage.decline ||
        stage == LifecycleStage.dead ||
        !hasHotMoney ||
        persist < 40.0) {
      String reason = "🔴【風控警示・出清退場】";
      if (stage == LifecycleStage.distribution) reason += "進入出貨期，主力高檔悄悄派發。";
      if (stage == LifecycleStage.decline) reason += "進入退潮期，多殺多開始。";
      if (!hasHotMoney) reason += "最關鍵的熱錢（HotMoney）已撤離，失去資金支撐。";
      if (persist < 40.0) reason += "延續力低於40，盤中開高走低、長上影線拋壓嚴重。";

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

    // ⚪ 4. 中性混沌觀望
    return StrategySignal(
      category: category,
      action: StrategyAction.neutral,
      score: strength,
      trendStrength: strength,
      persistence: persist,
      reason: "⚪【混沌盤整】各項指標處於混沌拉鋸區，無明確方向，建議先觀望。",
      dateKey: dateKey,
    );
  }
}
