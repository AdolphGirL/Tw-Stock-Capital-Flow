import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/theme/app_theme.dart';
import 'package:tw_stock_capital_flow/data/managers/sync_manager.dart';
import 'package:tw_stock_capital_flow/data/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/presentation/pages/main_navigation_container.dart'; // 🚀 引入全新導航控制外殼
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/domain/usecases/bootstrap_analyzer.dart';
import 'package:tw_stock_capital_flow/data/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/data/services/analysis_cache_service.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/shimmer_skeleton.dart';

// 正確引入本地 SQLite 資料庫與歷史紀錄 Repository
import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/data/watchlist/repositories/watchlist_repository.dart';
import 'package:tw_stock_capital_flow/data/signal/repositories/signal_snapshot_repository.dart';
import 'package:tw_stock_capital_flow/domain/strategies/momentum_strategy.dart';
import 'package:tw_stock_capital_flow/domain/services/signal_change_detector.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/signal_change_dialog.dart';
import 'package:tw_stock_capital_flow/core/services/notification_service.dart';
import 'package:tw_stock_capital_flow/data/services/debug_log_service.dart'; // TODO(debug): 除錯用
import 'package:tw_stock_capital_flow/domain/services/live_bootstrap_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> with WidgetsBindingObserver {
  String _listedDate = ''; // 上市（TWSE）交易日（民國年 YYYMMDD）
  String _otcDate    = ''; // 上櫃（TPEX）交易日（民國年 YYYMMDD）
  bool loading = true;
  String? error;
  AppBootstrapResult? bootstrapResult;
  bool isOfflineMode = false;

  CategoryHistoryRepository? _categoryHistoryRepository;
  WatchlistRepository? _watchlistRepository;
  SignalSnapshotRepository? _signalSnapshotRepository;
  final StorageService _storageService = StorageService();

  // 演算完成後填入異動清單，主畫面渲染後彈 dialog
  List<SignalChange> _pendingSignalChanges = [];
  bool _signalDialogShown = false;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  // 防止 _refresh 重複並發
  bool _isRefreshing = false;

  // 節流背景恢復同步，避免使用者短時間內反覆切換 App 造成 API 被連續打爆
  DateTime? _lastResumeSyncAt;
  static const _resumeSyncCooldown = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App 沒有背景常駐同步機制：從背景恢復前景時 Flutter 進程通常不會重新
  /// 執行 initState，畫面會停留在上次冷啟動/手動刷新當下抓到的數據。這裡
  /// 補上恢復前景時的靜默重新同步，沿用 syncTodayData 既有的白天靜默期
  /// 護欄（非 forceSync），確定有新資料才重新計算並更新畫面。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !loading) {
      _resyncOnResume();
    }
  }

  /// 取得今天日期字串（格式：民國年 YYYMMDD，與 StockService 格式一致）
  String _getTodayDateKey() {
    final now = DateTime.now();
    final rocYear = now.year - 1911;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$rocYear$month$day';
  }

  Future<void> initialize() async {
    DebugLogService.log('Init', '=== App 冷啟動 initialize() 開始 ===');
    await NotificationService.initialize();

    final storageService = _storageService;
    final calendarService = MarketCalendarService();
    final cacheService = AnalysisCacheService(storageService);

    // 初始化 SQLite 資料庫與所有 Repository
    final db = AppDatabase();
    _categoryHistoryRepository = CategoryHistoryRepository(db);
    _watchlistRepository = WatchlistRepository(db);
    _signalSnapshotRepository = SignalSnapshotRepository(db);

    final syncManager = SyncManager(
      storageService: storageService,
      calendarService: calendarService,
    );

    try {
      // 1. 同步今日最新數據
      final syncResult = await syncManager.syncTodayData().timeout(
        const Duration(seconds: 120),
      );

      final fallbackDate = await storageService.getLatestAvailableDate() ?? _getTodayDateKey();
      _listedDate = syncResult.listedDate.isNotEmpty ? syncResult.listedDate : fallbackDate;
      _otcDate    = syncResult.otcDate.isNotEmpty    ? syncResult.otcDate    : fallbackDate;

      // 新交易日成功存入：執行 SQLite 歷史分級清理（Layer 2，保留 365 天）
      if (syncResult.saved) {
        await _categoryHistoryRepository!.pruneOldHistory(keepDays: 365);
      }

      // 2. 嘗試讀取快取（快取 key 使用上市日期）
      // 若剛儲存了新快照（saved=true），快取與快照已不同步，必須強制重算；
      // 只有在「使用本地快照、未呼叫 API」的情況下才可命中快取。
      final cachedResult = syncResult.saved
          ? null
          : await cacheService.loadBootstrapCache(_listedDate);
      if (cachedResult != null) {
        DebugLogService.log('Init', '命中 bootstrap 快取（$_listedDate），直接使用，未重新計算');
        // 若快取不含日期資訊（舊版快取），補上當前日期
        final resultWithDates = cachedResult.listedDate.isEmpty
            ? cachedResult.copyWith(listedDate: _listedDate, otcDate: _otcDate)
            : cachedResult;
        final changes = await _detectAndSaveSignalChanges(resultWithDates);
        setState(() {
          bootstrapResult = resultWithDates;
          loading = false;
          _pendingSignalChanges = changes;
        });
        LiveBootstrapData.notifier.value = resultWithDates;
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

      // 4. 背景運算分析（五引擎依賴圖分兩階段並行 Isolate 執行）
      final rawResult = await BootstrapAnalyzer.analyzeAsync(snapshots);
      // 注入市場日期（Isolate 無法回傳日期，由呼叫端補上）
      final result = rawResult.copyWith(listedDate: _listedDate, otcDate: _otcDate);

      // 5. 儲存快取，並清理超出保留份數的舊版分析快取（Layer 3 清理）
      await cacheService.saveBootstrapCache(_listedDate, result);
      await storageService.pruneOldBootstrapCaches(keepCount: 3);

      // 6. 儲存今日板塊指標至 SQLite 歷史（30日走勢圖資料來源），只寫這輪真的抓到新資料的市場
      if (syncResult.saved) {
        await _saveHistoryToSqlite(
          result,
          saveListed: syncResult.listedFetchSucceeded,
          saveOtc: syncResult.otcFetchSucceeded,
        );
      }

      final changes = await _detectAndSaveSignalChanges(result);
      setState(() {
        bootstrapResult = result;
        loading = false;
        _pendingSignalChanges = changes;
      });
      LiveBootstrapData.notifier.value = result;
      DebugLogService.log('Init', '✅ 冷啟動完成，listedDate=$_listedDate，otcDate=$_otcDate');
    } catch (e) {
      DebugLogService.log('Init', '❌ 冷啟動例外（${e.runtimeType}）: $e');
      // 離線模式：優先使用本地最新日期
      final fallbackDate = await storageService.getLatestAvailableDate() ?? _getTodayDateKey();
      _listedDate = fallbackDate;
      _otcDate    = fallbackDate;

      final fallbackResult = await cacheService.tryGetAnyLatestCache();

      if (fallbackResult != null) {
        final changes = await _detectAndSaveSignalChanges(fallbackResult);
        setState(() {
          bootstrapResult = fallbackResult;
          isOfflineMode = true;
          loading = false;
          _pendingSignalChanges = changes;
        });
        LiveBootstrapData.notifier.value = fallbackResult;
      } else {
        setState(() {
          error = '首次開屏需要網路同步，請檢查您的網路連線並重試。\n($e)';
          loading = false;
        });
      }
    }
  }

  /// 手動刷新：強制向 API 同步、重新計算、upsert SQLite，並更新 UI。
  /// 使用者點擊刷新按鈕時呼叫，完全繞過 08:00–18:00 白天靜默期護欄。
  ///
  /// 回傳這輪的 [SyncResult]（含 listedFetchSucceeded／otcFetchSucceeded），
  /// 讓呼叫端（HomePage._handleRefresh）能判斷這次刷新是否真的更新到每個
  /// 市場的新資料，進而提示使用者；本地完全無資料可用時回傳 null。
  ///
  /// `_isRefreshing` 與 `_resyncOnResume()`（App 從背景回前景時的靜默同步）
  /// 共用同一把鎖。使用者主動點擊刷新的優先權高於那個靜默背景任務，因此若
  /// 背景同步剛好在跑，這裡改成等它結束再繼續，而不是直接放棄——否則使用
  /// 者點擊刷新會被靜默吃掉，畫面完全沒反應也沒有任何錯誤提示，這正是先
  /// 前實機「點了重新整理但資料沒變化」最可能的成因。
  Future<SyncResult?> _refresh() async {
    DebugLogService.log('Refresh', '手動刷新按下');
    var waited = 0;
    while (_isRefreshing && waited < 30000) {
      if (waited == 0) {
        DebugLogService.log('Refresh', '⏳ 背景同步正在進行中，等待它結束…');
      }
      await Future.delayed(const Duration(milliseconds: 300));
      waited += 300;
    }
    if (waited > 0) {
      DebugLogService.log('Refresh', '等待了 ${waited}ms 後繼續');
    }
    // 極端情況：背景同步異常卡住超過 30 秒仍未釋放鎖，放棄避免無限等待。
    if (_isRefreshing) {
      DebugLogService.log('Refresh', '❌❌ 等待 30 秒後背景同步仍未結束，本次刷新放棄');
      return null;
    }
    _isRefreshing = true;
    try {
      final storageService = _storageService;
      final syncManager = SyncManager(
        storageService: storageService,
        calendarService: MarketCalendarService(),
      );
      final cacheService = AnalysisCacheService(storageService);

      final syncResult = await syncManager
          .syncTodayData(forceSync: true)
          .timeout(const Duration(seconds: 120));

      final fallbackDate = await storageService.getLatestAvailableDate() ?? _getTodayDateKey();
      _listedDate = syncResult.listedDate.isNotEmpty ? syncResult.listedDate : fallbackDate;
      _otcDate    = syncResult.otcDate.isNotEmpty    ? syncResult.otcDate    : fallbackDate;

      if (syncResult.saved) {
        await _categoryHistoryRepository!.pruneOldHistory(keepDays: 365);
      }

      final historyRepository = HistoryRepository(storageService: storageService);
      final snapshots = await historyRepository.loadRecentSnapshots(5);
      if (snapshots.isEmpty) return syncResult;

      final rawResult = await BootstrapAnalyzer.analyzeAsync(snapshots);
      final result = rawResult.copyWith(listedDate: _listedDate, otcDate: _otcDate);
      await cacheService.saveBootstrapCache(_listedDate, result);
      await storageService.pruneOldBootstrapCaches(keepCount: 3);

      if (syncResult.saved) {
        await _saveHistoryToSqlite(
          result,
          saveListed: syncResult.listedFetchSucceeded,
          saveOtc: syncResult.otcFetchSucceeded,
        );
      }

      if (mounted) {
        setState(() {
          bootstrapResult = result;
        });
      }
      LiveBootstrapData.notifier.value = result;

      DebugLogService.log('Refresh', '✅ 手動刷新完成，畫面已更新');
      return syncResult;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 背景恢復前景時的靜默重新同步：只有確實抓到新資料（saved=true）才
  /// 重新計算並更新畫面；命中白天靜默期、無新資料或失敗時悄悄跳過，
  /// 維持目前畫面顯示的內容，不彈錯誤、不顯示 loading。
  Future<void> _resyncOnResume() async {
    final now = DateTime.now();
    if (_lastResumeSyncAt != null &&
        now.difference(_lastResumeSyncAt!) < _resumeSyncCooldown) {
      DebugLogService.log('Resume', '⏭ 冷卻中（30 秒內剛同步過），跳過這次背景恢復同步');
      return;
    }
    if (_isRefreshing) {
      DebugLogService.log('Resume', '⏭ 手動刷新正在進行中，跳過這次背景恢復同步');
      return;
    }
    DebugLogService.log('Resume', 'App 從背景回前景，開始靜默同步');
    _isRefreshing = true;
    _lastResumeSyncAt = now;
    try {
      final syncManager = SyncManager(
        storageService: _storageService,
        calendarService: MarketCalendarService(),
      );
      final syncResult = await syncManager.syncTodayData().timeout(
        const Duration(seconds: 120),
      );

      if (!syncResult.saved) {
        DebugLogService.log('Resume', '本次未抓到新資料（靜默期或失敗），維持現有畫面');
        return;
      }

      final newListedDate =
          syncResult.listedDate.isNotEmpty ? syncResult.listedDate : _listedDate;
      final newOtcDate =
          syncResult.otcDate.isNotEmpty ? syncResult.otcDate : _otcDate;

      await _categoryHistoryRepository!.pruneOldHistory(keepDays: 365);

      final historyRepository = HistoryRepository(storageService: _storageService);
      final snapshots = await historyRepository.loadRecentSnapshots(5);
      if (snapshots.isEmpty) return;

      final rawResult = await BootstrapAnalyzer.analyzeAsync(snapshots);
      final result = rawResult.copyWith(listedDate: newListedDate, otcDate: newOtcDate);

      final cacheService = AnalysisCacheService(_storageService);
      await cacheService.saveBootstrapCache(newListedDate, result);
      await _storageService.pruneOldBootstrapCaches(keepCount: 3);
      await _saveHistoryToSqlite(
        result,
        saveListed: syncResult.listedFetchSucceeded,
        saveOtc: syncResult.otcFetchSucceeded,
      );

      final changes = await _detectAndSaveSignalChanges(result);

      if (!mounted) return;
      setState(() {
        _listedDate = newListedDate;
        _otcDate = newOtcDate;
        bootstrapResult = result;
        _pendingSignalChanges = changes;
        if (changes.isNotEmpty) _signalDialogShown = false;
      });
      LiveBootstrapData.notifier.value = result;
      DebugLogService.log('Resume', '✅ 背景恢復同步完成，畫面已更新');
    } catch (e) {
      // 悄悄失敗，維持現有畫面資料
      DebugLogService.log('Resume', '❌ 背景恢復同步例外（${e.runtimeType}）: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// 【重置用】清空 SQLite 市場數據歷史表（板塊/主流/生命週期/輪動；watchlist／
  /// signal_snapshot 不動），強制向 API 重新抓取今日資料，重新計算後把結果整批
  /// 重新寫回 SQLite，最後更新畫面。
  ///
  /// 抓取確定成功才清空，避免清空後才發現抓不到新資料——期間若抓取失敗，
  /// 本機既有資料完全不受影響。一旦確認成功，會清空「全部」本地儲存的資料：
  /// SQLite 全部 6 張表（含 watchlist、signal_snapshot）與 daily 目錄下所有
  /// JSON 檔案（股票快照、分析結果快取、三大法人／融資融券歷史），只保留這
  /// 輪剛抓到的「今天」資料重新寫回再重新計算。
  ///
  /// 清空後只剩「今天」一天原始快照，需要仰賴多天歷史窗口的指標（
  /// MainstreamEngine 3 日延續力、CapitalFlowEngine N 日均量、LifecycleEngine
  /// 5 日趨勢、異常偵測 35 日 Z-score）會在重置後的頭幾天因樣本不足而暫時
  /// 退化，需等 App 正常使用幾天重新累積資料才會恢復——這是使用者主動選擇
  /// 「全部清空」後的預期行為，非本方法的臭蟲。
  ///
  /// 與 `_refresh()`／`_resyncOnResync()` 共用 `_isRefreshing` 鎖，避免重置途中
  /// 又被背景同步或手動刷新打斷。
  ///
  /// 回傳結果訊息供呼叫端（DebugLogPage）用 SnackBar 顯示；失敗時拋出例外。
  Future<String> _resetAndResync() async {
    if (_isRefreshing) {
      throw Exception('目前有其他同步正在進行，請稍後再試');
    }
    _isRefreshing = true;
    DebugLogService.log('Reset', '=== 使用者觸發一鍵重置＋重新抓取（全部清空）===');
    try {
      final syncManager = SyncManager(
        storageService: _storageService,
        calendarService: MarketCalendarService(),
      );
      final syncResult = await syncManager
          .syncTodayData(forceSync: true)
          .timeout(const Duration(seconds: 120));

      if (!syncResult.success || (!syncResult.listedFetchSucceeded && !syncResult.otcFetchSucceeded)) {
        throw Exception('重新抓取失敗，本機資料未受影響：${syncResult.message}');
      }

      // 抓取確定成功才清空，避免清空後才發現抓不到新資料。
      await _categoryHistoryRepository!.clearAllHistory();
      await _watchlistRepository!.clearAll();
      await _signalSnapshotRepository!.clearAll();
      await _storageService.clearAllFiles();
      DebugLogService.log('Reset', '重新抓取成功，已清空 SQLite 全部資料表與本地 JSON 快取，開始重新計算');

      _listedDate = syncResult.listedDate;
      _otcDate = syncResult.otcDate;

      // clearAllFiles() 連同 syncTodayData 剛寫入的「今天」快照一併刪除，
      // 這裡用回傳的 stocks 依市場拆分後重新寫回，確保後續分析讀得到今天的資料。
      final listedStocks =
          syncResult.stocks.where((s) => s.market == MarketType.listed).toList();
      final otcStocks =
          syncResult.stocks.where((s) => s.market == MarketType.otc).toList();
      if (listedStocks.isNotEmpty) {
        await _storageService.saveListedSnapshot(
          StockDaySnapshot(date: _listedDate, stocks: listedStocks),
        );
      }
      if (otcStocks.isNotEmpty) {
        await _storageService.saveOtcSnapshot(
          StockDaySnapshot(date: _otcDate, stocks: otcStocks),
        );
      }

      final historyRepository = HistoryRepository(storageService: _storageService);
      final snapshots = await historyRepository.loadRecentSnapshots(5);
      if (snapshots.isEmpty) {
        throw Exception('重新抓取後仍無可用資料');
      }

      final rawResult = await BootstrapAnalyzer.analyzeAsync(snapshots);
      final result = rawResult.copyWith(listedDate: _listedDate, otcDate: _otcDate);

      final cacheService = AnalysisCacheService(_storageService);
      await cacheService.saveBootstrapCache(_listedDate, result);

      await _saveHistoryToSqlite(
        result,
        saveListed: syncResult.listedFetchSucceeded,
        saveOtc: syncResult.otcFetchSucceeded,
      );

      // watchlist 已清空，_detectAndSaveSignalChanges 內部讀到空清單會直接
      // 回傳空列表，不會誤發訊號異動通知。
      final changes = await _detectAndSaveSignalChanges(result);

      if (mounted) {
        setState(() {
          bootstrapResult = result;
          loading = false;
          error = null;
          isOfflineMode = false;
          _pendingSignalChanges = changes;
          if (changes.isNotEmpty) _signalDialogShown = false;
        });
      }
      LiveBootstrapData.notifier.value = result;

      final failedMarkets = [
        if (!syncResult.listedFetchSucceeded) '上市',
        if (!syncResult.otcFetchSucceeded) '上櫃',
      ];
      DebugLogService.log('Reset', '✅ 重置完成，資料日期：上市 $_listedDate／上櫃 $_otcDate');
      return failedMarkets.isEmpty
          ? '已全部清空並重新抓取完成（$_listedDate）'
          : '已全部清空並重新抓取，但 ${failedMarkets.join("、")} 這次沒抓到新資料';
    } catch (e) {
      DebugLogService.log('Reset', '❌ 重置失敗（${e.runtimeType}）: $e');
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 將今日 bootstrap 計算結果寫入 SQLite 歷史表，供 30 日走勢圖使用。
  ///
  /// [saveListed]／[saveOtc] 對應「這一輪是否真的抓到該市場的新資料」
  /// （來自 SyncResult.listedFetchSucceeded／otcFetchSucceeded）。只有真的
  /// 抓到新資料的市場才會寫入、以其實際回傳的日期為 key；沒抓到的市場這輪
  /// 完全不動它在 SQLite 裡的既有紀錄，避免用還沒更新的舊資料覆蓋掉正確的
  /// 歷史紀錄，也避免明明沒抓到卻硬寫一筆「看起來是今天」的假資料。
  /// saveDailySnapshot 本身是 upsert，只會更新/新增傳入的板塊，不會刪除
  /// 該日期底下沒被傳入的既有板塊，因此上市／上櫃分開呼叫是安全的。
  ///
  /// 寫入失敗時重試最多 3 次（遞增間隔），重試整個方法是安全的（upsert 冪等）。
  Future<void> _saveHistoryToSqlite(
    AppBootstrapResult result, {
    required bool saveListed,
    required bool saveOtc,
  }) async {
    if (!saveListed && !saveOtc) {
      DebugLogService.log('SQLite', '⏭ 這輪兩個市場都沒抓到新資料，略過寫入');
      return;
    }

    const maxRetry = 3;
    for (int attempt = 1; attempt <= maxRetry; attempt++) {
      try {
        if (saveListed) {
          final key = result.listedDate.isNotEmpty ? result.listedDate : _listedDate;
          await _categoryHistoryRepository!.saveDailySnapshot(
            dateKey: key,
            categories: result.listedCategories,
            mainstreams: result.mainstreams,
            lifecycles: result.lifecycles,
            rotations: result.listedRotations,
          );
          DebugLogService.log('SQLite', '✅ 上市已寫入，dateKey=$key，${result.listedCategories.length} 個板塊');
        }
        if (saveOtc && result.otcCategories.isNotEmpty) {
          final key = result.otcDate.isNotEmpty ? result.otcDate : _otcDate;
          await _categoryHistoryRepository!.saveDailySnapshot(
            dateKey: key,
            categories: result.otcCategories,
            mainstreams: const [],
            lifecycles: const [],
            rotations: result.otcRotations,
          );
          DebugLogService.log('SQLite', '✅ 上櫃已寫入，dateKey=$key，${result.otcCategories.length} 個板塊');
        }
        return; // 成功，結束重試
      } catch (e, stack) {
        DebugLogService.log('SQLite', '❌ 寫入失敗（第 $attempt/$maxRetry 次，${e.runtimeType}）: $e');
        dev.log(
          'SQLite 歷史寫入失敗（第 $attempt/$maxRetry 次）: $e',
          name: 'BootstrapApp',
          error: e,
          stackTrace: stack,
        );
        if (attempt < maxRetry) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }
    dev.log(
      'SQLite 歷史寫入重試 $maxRetry 次後仍失敗，本次啟動略過該日期歷史紀錄',
      name: 'BootstrapApp',
    );
  }

  /// 偵測關注板塊訊號異動，並儲存今日訊號供下次比對。
  /// Watchlist 為空時直接回傳空列表，完全跳過演算。
  Future<List<SignalChange>> _detectAndSaveSignalChanges(
      AppBootstrapResult result) async {
    try {
      final watched = await _watchlistRepository!.getAll();
      if (watched.isEmpty) return [];

      final watchedNames = watched.map((e) => e.categoryName).toList();
      final strategy = MomentumStrategy();
      // 訊號評估以上市日期為主（上市為主要市場）
      final signalDateKey = result.listedDate.isNotEmpty ? result.listedDate : _listedDate;
      final todaySignals = result.lifecycles
          .map((lc) => strategy.evaluate(lc, dateKey: signalDateKey))
          .toList();

      // 比對前次訊號
      final previousSignals =
          await _signalSnapshotRepository!.loadForCategories(watchedNames);
      final changes = SignalChangeDetector().detect(
        previousSignals: previousSignals,
        todaySignals: todaySignals,
        watchedNames: watchedNames,
      );

      // 儲存今日訊號（下次啟動時作為「前次」使用）
      final toSave = <String, String>{};
      final watchedSet = watchedNames.toSet();
      for (final s in todaySignals) {
        if (watchedSet.contains(s.category)) toSave[s.category] = s.action.name;
      }
      await _signalSnapshotRepository!.saveSignals(signalDateKey, toSave);

      // 發送本地通知（有異動才觸發，不影響主流程）
      await NotificationService.showSignalChanges(changes);

      return changes;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: const Color(0xfff3f6fb),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const MainSectionSkeleton(),
                  const SizedBox(height: 24),
                  const MainSectionSkeleton(),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '數據來源：台灣證券交易所、證券櫃檯買賣中心。\n本 App 計算結果僅供參考，不構成任何投資建議。',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade400,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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

    // 演算完成後，若有關注板塊訊號異動，在第一次渲染後彈 dialog
    if (!_signalDialogShown && _pendingSignalChanges.isNotEmpty) {
      _signalDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _navKey.currentContext;
        if (ctx != null && mounted) {
          showDialog(
            context: ctx,
            barrierDismissible: true,
            builder: (_) => SignalChangeDialog(changes: _pendingSignalChanges),
          );
        }
      });
    }

    // 🟢 正式主畫面：全面由標籤頁分流系統接管
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navKey,
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
                listedDate: bootstrapResult!.listedDate.isNotEmpty ? bootstrapResult!.listedDate : _listedDate,
                otcDate:    bootstrapResult!.otcDate.isNotEmpty    ? bootstrapResult!.otcDate    : _otcDate,
                listedCategories: bootstrapResult!.listedCategories,
                otcCategories: bootstrapResult!.otcCategories,
                listedRiseCount: bootstrapResult!.listedRiseCount,
                listedFallCount: bootstrapResult!.listedFallCount,
                listedScore: bootstrapResult!.listedScore,
                otcRiseCount: bootstrapResult!.otcRiseCount,
                otcFallCount: bootstrapResult!.otcFallCount,
                otcScore: bootstrapResult!.otcScore,
                listedRotations: bootstrapResult!.listedRotations,
                otcRotations: bootstrapResult!.otcRotations,
                mainstreams: bootstrapResult!.mainstreams,
                lifecycles: bootstrapResult!.lifecycles,
                listedLifecycles: bootstrapResult!.listedLifecycles,
                otcLifecycles: bootstrapResult!.otcLifecycles,
                sentiment: bootstrapResult!.sentiment,
                historyRepository: _categoryHistoryRepository!,
                watchlistRepository: _watchlistRepository!,
                storageService: _storageService,
                onRefresh: _refresh,
                onResetAndResync: _resetAndResync,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
