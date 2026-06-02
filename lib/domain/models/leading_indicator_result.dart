enum LeadingSignalType {
  strongAccumulation, // 🟢 強烈暗中吸籌（黃金領先買進點）
  mildInflow, // 🍏 資金穩步潛伏
  neutral, // ⚪ 資金平穩
  distributionRisk, // 🟠 高檔派發風險（領先減碼點）
  strongDrain, // 🔴 強烈失血出逃（領先逃命點）
}

class LeadingIndicatorResult {
  final String category;
  final double netRotationScore; // 輪動淨動能 (RNM = Inflow - Outflow)
  final double totalInflowScore; // 總灌入強度
  final double totalOutflowScore; // 總抽離強度
  final int inflowFeederCount; // 有多少個板塊把錢輸血給它
  final LeadingSignalType signal; // 領先訊號型別
  final String textGuidance; // 交易者白話指南

  LeadingIndicatorResult({
    required this.category,
    required this.netRotationScore,
    required this.totalInflowScore,
    required this.totalOutflowScore,
    required this.inflowFeederCount,
    required this.signal,
    required this.textGuidance,
  });
}
