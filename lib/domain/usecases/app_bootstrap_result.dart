import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

class AppBootstrapResult {
  final String listedDate;  // TWSE 上市交易日（民國年 YYYMMDD）
  final String otcDate;     // TPEX 上櫃交易日（民國年 YYYMMDD）
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
  final List<LifecycleResult> listedLifecycles; // 上市市場獨立週期（StrategyDashboard 用）
  final List<LifecycleResult> otcLifecycles;    // 上櫃市場獨立週期（StrategyDashboard 用）
  final List<RotationResult> rotations;
  final MarketSentimentResult sentiment;

  const AppBootstrapResult({
    this.listedDate = '',
    this.otcDate = '',
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
    this.listedLifecycles = const [],
    this.otcLifecycles = const [],
    required this.rotations,
    required this.sentiment,
  });

  AppBootstrapResult copyWith({String? listedDate, String? otcDate}) {
    return AppBootstrapResult(
      listedDate: listedDate ?? this.listedDate,
      otcDate: otcDate ?? this.otcDate,
      listedCategories: listedCategories,
      otcCategories: otcCategories,
      listedRiseCount: listedRiseCount,
      listedFallCount: listedFallCount,
      otcRiseCount: otcRiseCount,
      otcFallCount: otcFallCount,
      listedScore: listedScore,
      otcScore: otcScore,
      mainstreams: mainstreams,
      lifecycles: lifecycles,
      listedLifecycles: listedLifecycles,
      otcLifecycles: otcLifecycles,
      rotations: rotations,
      sentiment: sentiment,
    );
  }
}
