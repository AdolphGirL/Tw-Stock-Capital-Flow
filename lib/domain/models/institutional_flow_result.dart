/// 單一法人類別的買賣明細（單位：億元）
class InstitutionalGroup {
  final String name;
  final double buyYi;
  final double sellYi;
  final double netYi;

  const InstitutionalGroup({
    required this.name,
    required this.buyYi,
    required this.sellYi,
    required this.netYi,
  });

  bool get isBuyNet => netYi >= 0;

  String get netLabel =>
      '${isBuyNet ? "+" : ""}${netYi.toStringAsFixed(2)} 億';

  String get buyLabel => '${buyYi.toStringAsFixed(2)} 億';

  String get sellLabel => '${sellYi.toStringAsFixed(2)} 億';
}

/// 三大法人完整買賣超結果（單位：億元）
///
/// 分組規則：
///   外資   = 外資及陸資(不含外資自營商) + 外資自營商
///   投信   = 投信
///   自營商 = 自營商(自行買賣) + 自營商(避險)
///   總額   = 合計（取 API 原始合計行）
class InstitutionalFlowResult {
  final String date;
  final InstitutionalGroup foreign;  // 外資
  final InstitutionalGroup trust;    // 投信
  final InstitutionalGroup dealer;   // 自營商
  final InstitutionalGroup total;    // 總額

  const InstitutionalFlowResult({
    required this.date,
    required this.foreign,
    required this.trust,
    required this.dealer,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'fBuy': foreign.buyYi, 'fSell': foreign.sellYi, 'fNet': foreign.netYi,
    'tBuy': trust.buyYi,   'tSell': trust.sellYi,   'tNet': trust.netYi,
    'dBuy': dealer.buyYi,  'dSell': dealer.sellYi,  'dNet': dealer.netYi,
    'totBuy': total.buyYi, 'totSell': total.sellYi, 'totNet': total.netYi,
  };

  factory InstitutionalFlowResult.fromJson(Map<String, dynamic> j) {
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0.0;
    return InstitutionalFlowResult(
      date: j['date'] as String,
      foreign: InstitutionalGroup(name: '外資',   buyYi: d('fBuy'),   sellYi: d('fSell'),   netYi: d('fNet')),
      trust:   InstitutionalGroup(name: '投信',   buyYi: d('tBuy'),   sellYi: d('tSell'),   netYi: d('tNet')),
      dealer:  InstitutionalGroup(name: '自營商', buyYi: d('dBuy'),   sellYi: d('dSell'),   netYi: d('dNet')),
      total:   InstitutionalGroup(name: '三大法人合計', buyYi: d('totBuy'), sellYi: d('totSell'), netYi: d('totNet')),
    );
  }
}
