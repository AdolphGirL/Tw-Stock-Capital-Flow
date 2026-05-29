import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tw_stock_capital_flow/presentation/theme/app_theme.dart';
import 'package:tw_stock_capital_flow/data/managers/sync_manager.dart';
import 'package:tw_stock_capital_flow/data/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/presentation/pages/home_page.dart';
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/domain/usecases/bootstrap_analyzer.dart';
import 'package:tw_stock_capital_flow/data/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/data/services/analysis_cache_service.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/shimmer_skeleton.dart';

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
  AppBootstrapResult? bootstrapResult;
  bool isOfflineMode = false; // 🚀 標記目前是否進入「離線降級防禦模式」

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    final storageService = StorageService();
    final calendarService = MarketCalendarService();
    final cacheService = AnalysisCacheService(storageService);

    final syncManager = SyncManager(
      storageService: storageService,
      calendarService: calendarService,
    );

    String dateKey = DateTime.now()
        .toIso8601String()
        .split('T')
        .first
        .replaceAll('-', '');

    try {
      // 1. 同步今日最新數據 (斷網高風險點)
      final syncResult = await syncManager.syncTodayData().timeout(
        // 🚀 【完美修正】：將 6 秒放寬至 20 秒
        // 因為台股 1,900 多檔個股在尖峰時刻需要充分的時間進行 HTTP 下載與 JSON 解析
        const Duration(seconds: 60), 
      );
      
      if (syncResult.date.isNotEmpty) {
        dateKey = syncResult.date;
      }

      // 2. 核心快取攔截
      final cachedResult = await cacheService.loadBootstrapCache(dateKey);
      if (cachedResult != null) {
        debugPrint('🚀 [Cache Hit] 命中今日數據快取');
        setState(() {
          bootstrapResult = cachedResult;
          loading = false;
        });
        return;
      }

      // 3. 標準計算流程
      final historyRepository = HistoryRepository(
        storageService: storageService,
      );
      final snapshots = await historyRepository.loadRecentSnapshots(5);

      if (snapshots.isEmpty) {
        throw Exception('本機暫無任何股市快照紀錄，無法進行離線初始化');
      }

      // 4. 背景運算
      final result = await compute(BootstrapAnalyzer.analyze, snapshots);

      // 5. 寫入快取
      await cacheService.saveBootstrapCache(dateKey, result);

      setState(() {
        bootstrapResult = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('⚠️ [防禦機制觸發] 網路或計算異常: $e，啟動本地全域降級防線...');

      // 🚀 【離線防禦核心】：不論發生何種異常，立刻嘗試去硬碟翻找過去任意一天的歷史快取結果
      final fallbackResult = await cacheService.tryGetAnyLatestCache();

      if (fallbackResult != null) {
        setState(() {
          bootstrapResult = fallbackResult;
          isOfflineMode = true; // 成功無縫降級，標記為離線展示狀態
          loading = false;
        });
      } else {
        // 如果連過去歷史快取都沒有，才真正拋出白屏錯誤（通常只出現在使用者第一次安裝且完全沒網路）
        setState(() {
          error = '首次開屏需要網路同步，請檢查您的網路連線並重試。\n($e)';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 優化一：等待期不再顯示簡陋的轉圈圈，改顯示微光打光的產業卡片骨架屏排版
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

    // 🚀 優化二：如果進入離線降級，在主頁面頂部加裝一個優雅的通知條，提示用戶當前使用的是歷史離線快照
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Column(
          children: [
            if (isOfflineMode)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3CD), // 柔和的警示黃
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
              child: HomePage(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
