import 'package:tw_stock_capital_flow/core/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/core/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/core/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';

class AppBootstrapResult {
  final List<CategoryUiModel> listedCategories;

  final List<CategoryUiModel> otcCategories;

  final int listedRiseCount;

  final int listedFallCount;

  final int otcRiseCount;

  final int otcFallCount;

  final double listedScore;

  final double otcScore;

  final List<MainstreamResult> mainstreams;

  final List<LifecycleResult> lifecycles;

  final List<RotationResult> rotations;

  final MarketSentimentResult sentiment;

  const AppBootstrapResult({
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.listedScore,
    required this.otcScore,
    required this.mainstreams,
    required this.lifecycles,
    required this.rotations,
    required this.sentiment,
  });
}
