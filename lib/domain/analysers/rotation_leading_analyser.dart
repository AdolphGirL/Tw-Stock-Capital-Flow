import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/domain/models/leading_indicator_result.dart';

class RotationLeadingAnalyser {
  /// 🚀 核心計算方法：將滯後的輪動路徑，轉化為產業領先動能指標
  List<LeadingIndicatorResult> calculateLeadingIndicators(
    List<RotationResult> rotations,
  ) {
    if (rotations.isEmpty) return [];

    // Map 結構：Category -> _RotationMetrics
    final Map<String, _RotationMetrics> registry = {};

    // 1. 遍歷所有輪動軌跡，統計每個產業的「流入」與「流出」加總
    for (var r in rotations) {
      final fromCat = r.fromCategory;
      final toCat = r.toCategory;
      final score = r.score;

      // 累加 From 產業 (資金抽離)
      registry.putIfAbsent(fromCat, () => _RotationMetrics(name: fromCat));
      registry[fromCat]!.outflowSum += score;

      // 累加 To 產業 (資金灌入)
      registry.putIfAbsent(toCat, () => _RotationMetrics(name: toCat));
      registry[toCat]!.inflowSum += score;
      registry[toCat]!.feederCount += 1;
    }

    // 2. 根據淨動能 (RNM) 計算領先訊號與白話指南
    List<LeadingIndicatorResult> results = [];

    registry.forEach((category, metrics) {
      final double rnm = metrics.inflowSum - metrics.outflowSum;
      LeadingSignalType signal = LeadingSignalType.neutral;
      String guidance = "⚪ 市場資金對該板塊無明顯搬移傾向，暫時以區間盤整視之。";

      // 訊號量化評級模型
      if (rnm >= 45.0 && metrics.feederCount >= 2) {
        signal = LeadingSignalType.strongAccumulation;
        guidance =
            "🟢【核心提示：主力暗中吸籌】全市場有高達 ${metrics.feederCount} 個產業的資金正在集體『化整為零』秘密灌入此板塊。目前股價可能尚未大漲，是極具勝率的領先埋伏進場點！";
      } else if (rnm > 15.0) {
        signal = LeadingSignalType.mildInflow;
        guidance = "🍏【資金穩步潛伏】輪動淨動能為正，多方大資金正在溫和流入，可加入自選股關注突破時機。";
      } else if (rnm <= -45.0) {
        signal = LeadingSignalType.strongDrain;
        guidance =
            "🔴【危險提示：大資金出逃】此板塊正成為全台股的『提款機』，資金正不計成本被抽出搬往其他新主力產業。股價極易面臨無量陰跌，請領先清倉或反向做空。";
      } else if (rnm < -15.0) {
        signal = LeadingSignalType.distributionRisk;
        guidance = "🟠【高檔派發風險】資金淨流出。主力在高檔逐步將籌碼派發給散戶，短期防禦型交易者應適度調調節減碼。";
      }

      results.add(
        LeadingIndicatorResult(
          category: category,
          netRotationScore: rnm,
          totalInflowScore: metrics.inflowSum,
          totalOutflowScore: metrics.outflowSum,
          inflowFeederCount: metrics.feederCount,
          signal: signal,
          textGuidance: guidance,
        ),
      );
    });

    // 3. 排序：將淨動能最高的（最吸金、最領先）排在最前面
    results.sort((a, b) => b.netRotationScore.compareTo(a.netRotationScore));
    return results;
  }
}

/// 內部計算輔助類
class _RotationMetrics {
  final String name;
  double inflowSum = 0.0;
  double outflowSum = 0.0;
  int feederCount = 0;
  _RotationMetrics({required this.name});
}
