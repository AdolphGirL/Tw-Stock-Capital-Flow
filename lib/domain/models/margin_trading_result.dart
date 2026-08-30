/// 單一信用交易項目（融資或融券）的每日明細（單位：張）
class MarginEntry {
  final String name;
  final double buyLots;          // 買進（張）
  final double sellLots;         // 賣出（張）
  final double redemptionLots;   // 現金(券)償還（張）
  final double prevBalanceLots;  // 前日餘額（張）
  final double todayBalanceLots; // 今日餘額（張）

  const MarginEntry({
    required this.name,
    required this.buyLots,
    required this.sellLots,
    required this.redemptionLots,
    required this.prevBalanceLots,
    required this.todayBalanceLots,
  });

  double get changeLots => todayBalanceLots - prevBalanceLots;

  bool get isIncrease => changeLots >= 0;

  String get changeLabel =>
      '${isIncrease ? "+" : ""}${changeLots.toStringAsFixed(0)} 張';

  String get todayBalanceLabel => '${todayBalanceLots.toStringAsFixed(0)} 張';

  Map<String, dynamic> toJson() => {
    'name': name,
    'buy': buyLots,
    'sell': sellLots,
    'redemption': redemptionLots,
    'prevBalance': prevBalanceLots,
    'todayBalance': todayBalanceLots,
  };

  factory MarginEntry.fromJson(String name, Map<String, dynamic> j) {
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0.0;
    return MarginEntry(
      name: name,
      buyLots: d('buy'),
      sellLots: d('sell'),
      redemptionLots: d('redemption'),
      prevBalanceLots: d('prevBalance'),
      todayBalanceLots: d('todayBalance'),
    );
  }
}

/// 集中市場（上市）信用交易統計結果（散戶指標：融資融券餘額）
///
/// 資料來源：TWSE MI_MARGN（selectType=MS，大盤信用交易統計）。
/// 融資 = 借錢買股（看多／散戶進場）；融券 = 借股賣出（看空／散戶放空）。
/// 融券沒有官方公告的金額欄位，只提供交易單位（張）。
class MarginTradingResult {
  final String date; // YYYYMMDD
  final MarginEntry margin;    // 融資
  final MarginEntry shortSale; // 融券
  final double marginBalanceValueYi;       // 融資金額今日餘額（億元）
  final double marginBalanceValueChangeYi; // 融資金額較前日增減（億元）

  const MarginTradingResult({
    required this.date,
    required this.margin,
    required this.shortSale,
    required this.marginBalanceValueYi,
    required this.marginBalanceValueChangeYi,
  });

  bool get isMarginIncrease => marginBalanceValueChangeYi >= 0;

  Map<String, dynamic> toJson() => {
    'date': date,
    'margin': margin.toJson(),
    'shortSale': shortSale.toJson(),
    'marginBalanceValueYi': marginBalanceValueYi,
    'marginBalanceValueChangeYi': marginBalanceValueChangeYi,
  };

  factory MarginTradingResult.fromJson(Map<String, dynamic> j) {
    return MarginTradingResult(
      date: j['date'] as String,
      margin: MarginEntry.fromJson('融資', j['margin'] as Map<String, dynamic>),
      shortSale: MarginEntry.fromJson('融券', j['shortSale'] as Map<String, dynamic>),
      marginBalanceValueYi: (j['marginBalanceValueYi'] as num?)?.toDouble() ?? 0.0,
      marginBalanceValueChangeYi: (j['marginBalanceValueChangeYi'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
