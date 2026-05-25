import 'package:flutter/material.dart';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:tw_stock_capital_flow/ui/theme/app_theme.dart';
import 'package:tw_stock_capital_flow/managers/sync_manager.dart';
import 'package:tw_stock_capital_flow/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/services/storage_service.dart';
import 'package:tw_stock_capital_flow/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/ui/pages/home_page.dart';
import 'package:tw_stock_capital_flow/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/core/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/core/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/core/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/core/bootstrap/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/core/bootstrap/app_bootstrapper.dart';
import 'package:tw_stock_capital_flow/core/bootstrap/bootstrap_analyzer.dart';
import 'package:tw_stock_capital_flow/repositories/history_repository.dart';

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

  List<LifecycleResult> lifecycles = [];

  AppBootstrapResult? bootstrapResult;

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

      final snapshots = await historyRepository.loadRecentSnapshots(5);

      final result = await compute(BootstrapAnalyzer.analyze, snapshots);

      setState(() {
        bootstrapResult = result;

        loading = false;
      });
    } catch (e, stack) {
      debugPrint(e.toString());

      debugPrint(stack.toString());

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

    final data = bootstrapResult!;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: HomePage(
        listedCategories: data.listedCategories,

        otcCategories: data.otcCategories,

        listedRiseCount: data.listedRiseCount,

        listedFallCount: data.listedFallCount,

        listedScore: data.listedScore,

        otcRiseCount: data.otcRiseCount,

        otcFallCount: data.otcFallCount,

        otcScore: data.otcScore,

        rotations: data.rotations,

        mainstreams: data.mainstreams,

        lifecycles: data.lifecycles,

        sentiment: data.sentiment,
      ),
    );
  }
}
