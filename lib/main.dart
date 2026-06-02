import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tw_stock_capital_flow/presentation/theme/app_theme.dart';
import 'package:tw_stock_capital_flow/data/managers/sync_manager.dart';
import 'package:tw_stock_capital_flow/data/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/presentation/pages/main_navigation_container.dart'; // 🚀 引入全新導航控制外殼
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/domain/usecases/bootstrap_analyzer.dart';
import 'package:tw_stock_capital_flow/data/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/data/services/analysis_cache_service.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/shimmer_skeleton.dart';

// 正確引入本地 SQLite 資料庫與歷史紀錄 Repository
import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

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
  String _resolvedDate = ''; // 最終決定的交易日期（YYYYMMDD）
  bool loading = true;
  String? error;
  AppBootstrapResult? bootstrapResult;
  bool isOfflineMode = false;

  // 歷史資料庫 Repository
  CategoryHistoryRepository? _categoryHistoryRepository;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  /// 取得今天日期字串（格式：YYYYMMDD）
  String _getTodayDateKey() {
    return DateTime.now()
        .toIso8601String()
        .split('T')
        .first
        .replaceAll('-', '');
  }

  Future<void> initialize() async {
    final storageService = StorageService();
    final calendarService = MarketCalendarService();
    final cacheService = AnalysisCacheService(storageService);

    // 初始化 SQLite 資料庫與 Repository
    final db = AppDatabase();
    _categoryHistoryRepository = CategoryHistoryRepository(db);

    final syncManager = SyncManager(
      storageService: storageService,
      calendarService: calendarService,
    );

    String resolvedDate = '';

    try {
      // 1. 同步今日最新數據
      final syncResult = await syncManager.syncTodayData().timeout(
        const Duration(seconds: 120),
      );

      if (syncResult.date.isNotEmpty) {
        resolvedDate = syncResult.date;
      } else {
        resolvedDate = await storageService.getLatestAvailableDate() ?? '';
      }

      // 額外保護：如果 resolvedDate 還是空的
      if (resolvedDate.isEmpty) {
        resolvedDate = _getTodayDateKey();
      }

      _resolvedDate = resolvedDate;

      // 2. 嘗試讀取快取
      final cachedResult = await cacheService.loadBootstrapCache(resolvedDate);
      if (cachedResult != null) {
        debugPrint('🚀 [Cache Hit] 命中快取: $resolvedDate');
        setState(() {
          bootstrapResult = cachedResult;
          loading = false;
        });
        return;
      }

      // 3. 無快取時執行標準計算流程
      final historyRepository = HistoryRepository(
        storageService: storageService,
      );
      final snapshots = await historyRepository.loadRecentSnapshots(5);

      if (snapshots.isEmpty) {
        throw Exception('本機無任何股市快照紀錄，無法進行初始化');
      }

      // 4. 背景運算分析
      final result = await compute(BootstrapAnalyzer.analyze, snapshots);

      // 5. 儲存快取
      await cacheService.saveBootstrapCache(resolvedDate, result);

      setState(() {
        bootstrapResult = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('⚠️ [防禦機制觸發] 異常: $e，進入離線降級...');

      // 離線模式：優先使用本地最新日期
      resolvedDate =
          await storageService.getLatestAvailableDate() ?? _getTodayDateKey();
      _resolvedDate = resolvedDate;

      final fallbackResult = await cacheService.tryGetAnyLatestCache();

      if (fallbackResult != null) {
        setState(() {
          bootstrapResult = fallbackResult;
          isOfflineMode = true;
          loading = false;
        });
      } else {
        setState(() {
          error = '首次開屏需要網路同步，請檢查您的網路連線並重試。\n($e)';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: Color(0xfff3f6fb),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  MainSectionSkeleton(),
                  SizedBox(height: 24),
                  MainSectionSkeleton(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ),
        ),
      );
    }

    // 🟢 正式主畫面：全面由標籤頁分流系統接管
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Column(
          children: [
            if (isOfflineMode)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3CD),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Color(0xFF856404), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '當前網路連線不穩定，已為您加載本地歷史資金流數據。',
                        style: TextStyle(
                          color: Color(0xFF856404),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: MainNavigationContainer(
                tradeDate: _resolvedDate,
                listedCategories: bootstrapResult!.listedCategories,
                otcCategories: bootstrapResult!.otcCategories,
                listedRiseCount: bootstrapResult!.listedRiseCount,
                listedFallCount: bootstrapResult!.listedFallCount,
                listedScore: bootstrapResult!.listedScore,
                otcRiseCount: bootstrapResult!.otcRiseCount,
                otcFallCount: bootstrapResult!.otcFallCount,
                otcScore: bootstrapResult!.otcScore,
                rotations: bootstrapResult!.rotations,
                mainstreams: bootstrapResult!.mainstreams,
                lifecycles: bootstrapResult!.lifecycles,
                sentiment: bootstrapResult!.sentiment,
                historyRepository: _categoryHistoryRepository!, // 注入本地歷史紀錄儲存庫
              ),
            ),
          ],
        ),
      ),
    );
  }
}
