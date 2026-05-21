import 'package:tw_stock_capital_flow/core/enums/sentiment_level.dart';

class MarketSentimentResult {
  final double score;

  final SentimentLevel level;

  final int riseCount;

  final int fallCount;

  final int strongCategoryCount;

  final double mainstreamAverage;

  final double hotMoneyStrength;

  const MarketSentimentResult({
    required this.score,
    required this.level,
    required this.riseCount,
    required this.fallCount,
    required this.strongCategoryCount,
    required this.mainstreamAverage,
    required this.hotMoneyStrength,
  });
}
