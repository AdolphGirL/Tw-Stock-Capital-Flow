import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/ui/theme/app_theme.dart';
import 'package:tw_stock_capital_flow/managers/sync_manager.dart';
import 'package:tw_stock_capital_flow/models/stock_data.dart';
import 'package:tw_stock_capital_flow/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/services/storage_service.dart';
import 'package:tw_stock_capital_flow/services/capital_flow_analyzer.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/ui/pages/home_page.dart';
import 'package:tw_stock_capital_flow/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/core/engines/rotation_engine.dart';
import 'package:tw_stock_capital_flow/core/engines/mainstream_engine.dart';
import 'package:tw_stock_capital_flow/core/engines/market_sentiment_engine.dart';
import 'package:tw_stock_capital_flow/core/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/core/models/market_sentiment_result.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool loading = true;

  String? error;

  List<CategoryUiModel> listedCategories = [];

  List<CategoryUiModel> otcCategories = [];

  int listedRiseCount = 0;

  int listedFallCount = 0;

  int otcRiseCount = 0;

  int otcFallCount = 0;

  double listedScore = 0;

  double otcScore = 0;

  List<RotationResult> rotations = [];

  List<MainstreamResult> mainstreams = [];

  MarketSentimentResult? sentiment;

  @override
  void initState() {
    super.initState();

    initialize();
  }

  Future<void> initialize() async {
    try {
      final storageService = StorageService();

      final syncManager = SyncManager(
        storageService: storageService,
        calendarService: MarketCalendarService(),
      );

      await syncManager.syncTodayData();

      final historyRepository = HistoryRepository(
        storageService: storageService,
      );

      final snapshots = await historyRepository.loadRecentSnapshots(1);

      if (snapshots.isEmpty) {
        setState(() {
          error = '無歷史資料';
          loading = false;
        });

        return;
      }

      final analyzer = CapitalFlowAnalyzer(snapshots: snapshots);

      listedCategories = analyzer.analyzeMainCategories(
        market: MarketType.listed,
      );

      otcCategories = analyzer.analyzeMainCategories(market: MarketType.otc);

      listedRiseCount = analyzer.calculateRiseCount(market: MarketType.listed);

      listedFallCount = analyzer.calculateFallCount(market: MarketType.listed);

      otcRiseCount = analyzer.calculateRiseCount(market: MarketType.otc);

      otcFallCount = analyzer.calculateFallCount(market: MarketType.otc);

      listedScore = analyzer.calculateMarketScore(market: MarketType.listed);

      otcScore = analyzer.calculateMarketScore(market: MarketType.otc);

      final rotationEngine = RotationEngine(snapshots: snapshots);

      rotations = rotationEngine.analyzeMainCategoryRotation();

      final mainstreamEngine = MainstreamEngine(snapshots: snapshots);

      mainstreams = mainstreamEngine.analyzeMainstreams();

      final sentimentEngine = MarketSentimentEngine(
        snapshots: snapshots,
        mainstreams: mainstreams,
      );

      sentiment = sentimentEngine.analyze();

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,

        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,

        home: Scaffold(body: Center(child: Text(error!))),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: HomePage(
        listedCategories: listedCategories,

        otcCategories: otcCategories,

        listedRiseCount: listedRiseCount,

        listedFallCount: listedFallCount,

        listedScore: listedScore,

        otcRiseCount: otcRiseCount,

        otcFallCount: otcFallCount,

        otcScore: otcScore,

        rotations: rotations,

        mainstreams: mainstreams,
      ),
    );
  }
}
