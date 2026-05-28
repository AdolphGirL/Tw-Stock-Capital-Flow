import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

class AbnormalMoneyResult {
  final StockData stock;

  final double moneyScore;

  final double volumeRatio;

  final double valueRatio;

  final double momentumScore;

  final bool continuous;

  final bool breakout;

  const AbnormalMoneyResult({
    required this.stock,
    required this.moneyScore,
    required this.volumeRatio,
    required this.valueRatio,
    required this.momentumScore,
    required this.continuous,
    required this.breakout,
  });
}
