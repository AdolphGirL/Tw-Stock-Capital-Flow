## Project Structure

lib/
    main.dart
    core/
        constants/
            app_constants.dart
        extensions/
            list_extension.dart
            market_type_extension.dart
        navigation/
            category_navigation.dart
        utils/
            date_utils.dart
    data/
        database/
            app_database.dart
            app_database.g.dart
            dao/
            tables/
                category_history_table.dart
                lifecycle_history_table.dart
                mainstream_history_table.dart
                rotation_history_table.dart
        history/
            repositories/
                category_history_repository.dart
        managers/
            sync_manager.dart
        models/
            analysis_snapshot.dart
            flow_signal.dart
            rotation_result.dart
            stock_data.dart
            stock_day_snapshot.dart
            stock_score.dart
        repositories/
            history_repository.dart
        services/
            analysis_cache_service.dart
            capital_flow_analyzer.dart
            market_calendar_service.dart
            stock_service.dart
            storage_service.dart
    domain/
        analysers/
            rotation_leading_analyser.dart
        engines/
            abnormal_money_engine.dart
            capital_flow_engine.dart
            lifecycle_engine.dart
            mainstream_engine.dart
            market_sentiment_engine.dart
            rotation_engine.dart
            trend_metrics_engine.dart
        enums/
            lifecycle_stage.dart
            sentiment_level.dart
        models/
            abnormal_money_result.dart
            leading_indicator_result.dart
            lifecycle_result.dart
            lifecycle_timeline.dart
            mainstream_result.dart
            market_sentiment_result.dart
            strategy_signal.dart
            trend_metrics.dart
        strategies/
            momentum_strategy.dart
        usecases/
            app_bootstrapper.dart
            app_bootstrap_result.dart
            bootstrap_analyzer.dart
    presentation/
        enums/
            category_sort_type.dart
        mappers/
        models/
            category_ui_model.dart
        pages/
            home_page.dart
            leading_indicator_page.dart
            lifecycle_page.dart
            mainstream_page.dart
            main_category_page.dart
            main_navigation_container.dart
            market_sentiment_page.dart
            rotation_page.dart
            strategy_dashboard_page.dart
            sub_category_page.dart
        theme/
            app_theme.dart
        widgets/
            category_card.dart
            empty_view.dart
            home_section_card.dart
            hot_badge.dart
            lifecycle_card.dart
            mainstream_card.dart
            market_heatmap.dart
            market_summary_card.dart
            rotation_flow_card.dart
            section_title.dart
            shimmer_skeleton.dart
            stock_tile.dart
            top_hot_categories.dart
            trend_sparkline.dart

## Source Code

### lib\main.dart

`dart
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

`

### lib\core\constants\app_constants.dart

`dart
class AppConstants {
  static const String dailyFolder = 'daily';

  static const int recentCompareDays = 3;

  static const int minSubCategoryStockCount = 3;
}

`

### lib\core\extensions\list_extension.dart

`dart
extension AverageExtension on List<double> {
  double average() {
    if (isEmpty) {
      return 0;
    }

    return reduce((a, b) => a + b) / length;
  }
}

`

### lib\core\extensions\market_type_extension.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

extension MarketTypeExtension on MarketType {
  String get value {
    switch (this) {
      case MarketType.listed:
        return 'listed';
      case MarketType.otc:
        return 'otc';
    }
  }

  static MarketType fromString(String value) {
    switch (value) {
      case 'listed':
        return MarketType.listed;
      case 'otc':
        return MarketType.otc;
      default:
        return MarketType.listed;
    }
  }
}

`

### lib\core\navigation\category_navigation.dart

`dart
// lib/core/navigation/category_navigation.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart'; // 保持引入基礎資料模型

// 正確引入歷史紀錄 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class CategoryNavigation {
  /// 🚀 動作 A：主分類 -> 進入細分類全螢幕頁面 (SubCategoryPage)
  static void openCategory(
    BuildContext context,
    CategoryUiModel category,
    CategoryHistoryRepository historyRepository,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubCategoryPage(
          title: category.name,
          categories: category.children,
          historyRepository: historyRepository,
        ),
      ),
    );
  }

  /// 🚀 動作 B：細分類 -> 彈出成分股清單半窗抽屜 (BottomSheet)
  static void showStockListSheet({
    required BuildContext context,
    required String categoryName,
    required List<StockUiModel>
    uiStocks, // 🟢 修正點 1：將型態精確對接為 UI 層的 List<StockUiModel>
  }) {
    // 自動過濾出屬於該細分類（或主分類）的個股，並依成交值 (value) 由大到小排序
    // 💡 透過 s.stock.value 進行解包與降序排序
    final filteredUiStocks =
        uiStocks
            .where(
              (s) =>
                  s.stock.subCategory == categoryName ||
                  s.stock.mainCategory == categoryName,
            )
            .toList()
          ..sort((a, b) => b.stock.value.compareTo(a.stock.value));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 頂部滑動小灰條
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // 標頭區段
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '# $categoryName 成分股排行',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '共 ${filteredUiStocks.length} 檔',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),

                  // 個股清單
                  Expanded(
                    child: filteredUiStocks.isEmpty
                        ? const Center(
                            child: Text(
                              '查無此產業成分股數據',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 20,
                            ),
                            itemCount: filteredUiStocks.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final uiStock = filteredUiStocks[index];
                              // 🟢 修正點 2：直接傳遞 uiStock 物件給小卡片元件
                              return _buildStockListTile(context, uiStock);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 打造抽屜內部的個股細項 ListTile 元件
  static Widget _buildStockListTile(
    BuildContext context,
    StockUiModel uiStock,
  ) {
    // 💡 從 uiStock 提煉出底層的基礎 stock 資料
    final stock = uiStock.stock;

    final isUp = stock.changePercent >= 0;
    final themeColor = isUp
        ? const Color(0xffc62828)
        : const Color(0xff2e7d32); // 台股紅漲綠跌

    // 計算億元級成交值
    final double valueInMillions = stock.value / 100000000.0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      title: Row(
        children: [
          Text(
            stock.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            stock.code,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stock.market == MarketType.listed ? '上市' : '上櫃',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '成交值: ${valueInMillions.toStringAsFixed(2)} 億 | 量: ${(stock.volume / 1000).toStringAsFixed(0)} 張',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            stock.close.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${isUp ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
        ],
      ),
      onTap: () => _launchYahooFinance(stock),
    );
  }

  /// 精準對接外部網頁
  static Future<void> _launchYahooFinance(StockData stock) async {
    final String suffix = (stock.market == MarketType.listed) ? 'TW' : 'TWO';
    final String urlString =
        'https://tw.stock.yahoo.com/quote/${stock.code}.$suffix';

    final Uri url = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('無法開啟網頁連結: $urlString');
      }
    } catch (e) {
      debugPrint('網頁穿透發生異常: $e');
    }
  }
}

`

### lib\core\utils\date_utils.dart

`dart
class AppDateUtils {
  static int compareRocDate(String a, String b) {
    return a.compareTo(b);
  }

  static List<String> sortDesc(List<String> dates) {
    final copied = [...dates];

    copied.sort((a, b) => b.compareTo(a));

    return copied;
  }
}

`

### lib\data\database\app_database.dart

`dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// 引入所有 Table 定義
import 'package:tw_stock_capital_flow/data/database/tables/category_history_table.dart';
import 'package:tw_stock_capital_flow/data/database/tables/mainstream_history_table.dart';
import 'package:tw_stock_capital_flow/data/database/tables/lifecycle_history_table.dart';
import 'package:tw_stock_capital_flow/data/database/tables/rotation_history_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CategoryHistoryTable,
    MainstreamHistoryTable, // V2 新增
    LifecycleHistoryTable, // V3 新增
    RotationHistoryTable, // V3 新增
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // 升級版本號至 3 (涵蓋 Version 2 與 Version 3 的規劃)
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // 升級到 Version 2: 新增主流排行表
        await m.createTable(mainstreamHistoryTable);
      }
      if (from < 3) {
        // 升級到 Version 3: 新增生命週期與輪動表
        await m.createTable(lifecycleHistoryTable);
        await m.createTable(rotationHistoryTable);
      }
    },
    beforeOpen: (details) async {
      // 開啟 WAL 模式以提升效能，並啟用外鍵限制
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'capital_flow.db'));
    return NativeDatabase(file);
  });
}

`

### lib\data\database\app_database.g.dart

`dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoryHistoryTableTable extends CategoryHistoryTable
    with TableInfo<$CategoryHistoryTableTable, CategoryHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hotScoreMeta = const VerificationMeta(
    'hotScore',
  );
  @override
  late final GeneratedColumn<double> hotScore = GeneratedColumn<double>(
    'hot_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _persistenceMeta = const VerificationMeta(
    'persistence',
  );
  @override
  late final GeneratedColumn<double> persistence = GeneratedColumn<double>(
    'persistence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trendStrengthMeta = const VerificationMeta(
    'trendStrength',
  );
  @override
  late final GeneratedColumn<double> trendStrength = GeneratedColumn<double>(
    'trend_strength',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riseCountMeta = const VerificationMeta(
    'riseCount',
  );
  @override
  late final GeneratedColumn<int> riseCount = GeneratedColumn<int>(
    'rise_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fallCountMeta = const VerificationMeta(
    'fallCount',
  );
  @override
  late final GeneratedColumn<int> fallCount = GeneratedColumn<int>(
    'fall_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCountMeta = const VerificationMeta(
    'totalCount',
  );
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
    'total_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tradeDate,
    categoryName,
    score,
    hotScore,
    persistence,
    trendStrength,
    riseCount,
    fallCount,
    totalCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trade_date')) {
      context.handle(
        _tradeDateMeta,
        tradeDate.isAcceptableOrUnknown(data['trade_date']!, _tradeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_tradeDateMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('hot_score')) {
      context.handle(
        _hotScoreMeta,
        hotScore.isAcceptableOrUnknown(data['hot_score']!, _hotScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_hotScoreMeta);
    }
    if (data.containsKey('persistence')) {
      context.handle(
        _persistenceMeta,
        persistence.isAcceptableOrUnknown(
          data['persistence']!,
          _persistenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_persistenceMeta);
    }
    if (data.containsKey('trend_strength')) {
      context.handle(
        _trendStrengthMeta,
        trendStrength.isAcceptableOrUnknown(
          data['trend_strength']!,
          _trendStrengthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trendStrengthMeta);
    }
    if (data.containsKey('rise_count')) {
      context.handle(
        _riseCountMeta,
        riseCount.isAcceptableOrUnknown(data['rise_count']!, _riseCountMeta),
      );
    } else if (isInserting) {
      context.missing(_riseCountMeta);
    }
    if (data.containsKey('fall_count')) {
      context.handle(
        _fallCountMeta,
        fallCount.isAcceptableOrUnknown(data['fall_count']!, _fallCountMeta),
      );
    } else if (isInserting) {
      context.missing(_fallCountMeta);
    }
    if (data.containsKey('total_count')) {
      context.handle(
        _totalCountMeta,
        totalCount.isAcceptableOrUnknown(data['total_count']!, _totalCountMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tradeDate, categoryName};
  @override
  CategoryHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      hotScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hot_score'],
      )!,
      persistence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}persistence'],
      )!,
      trendStrength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}trend_strength'],
      )!,
      riseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rise_count'],
      )!,
      fallCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fall_count'],
      )!,
      totalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_count'],
      )!,
    );
  }

  @override
  $CategoryHistoryTableTable createAlias(String alias) {
    return $CategoryHistoryTableTable(attachedDatabase, alias);
  }
}

class CategoryHistoryData extends DataClass
    implements Insertable<CategoryHistoryData> {
  final String tradeDate;
  final String categoryName;
  final double score;
  final double hotScore;
  final double persistence;
  final double trendStrength;
  final int riseCount;
  final int fallCount;
  final int totalCount;
  const CategoryHistoryData({
    required this.tradeDate,
    required this.categoryName,
    required this.score,
    required this.hotScore,
    required this.persistence,
    required this.trendStrength,
    required this.riseCount,
    required this.fallCount,
    required this.totalCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trade_date'] = Variable<String>(tradeDate);
    map['category_name'] = Variable<String>(categoryName);
    map['score'] = Variable<double>(score);
    map['hot_score'] = Variable<double>(hotScore);
    map['persistence'] = Variable<double>(persistence);
    map['trend_strength'] = Variable<double>(trendStrength);
    map['rise_count'] = Variable<int>(riseCount);
    map['fall_count'] = Variable<int>(fallCount);
    map['total_count'] = Variable<int>(totalCount);
    return map;
  }

  CategoryHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryHistoryTableCompanion(
      tradeDate: Value(tradeDate),
      categoryName: Value(categoryName),
      score: Value(score),
      hotScore: Value(hotScore),
      persistence: Value(persistence),
      trendStrength: Value(trendStrength),
      riseCount: Value(riseCount),
      fallCount: Value(fallCount),
      totalCount: Value(totalCount),
    );
  }

  factory CategoryHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      score: serializer.fromJson<double>(json['score']),
      hotScore: serializer.fromJson<double>(json['hotScore']),
      persistence: serializer.fromJson<double>(json['persistence']),
      trendStrength: serializer.fromJson<double>(json['trendStrength']),
      riseCount: serializer.fromJson<int>(json['riseCount']),
      fallCount: serializer.fromJson<int>(json['fallCount']),
      totalCount: serializer.fromJson<int>(json['totalCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tradeDate': serializer.toJson<String>(tradeDate),
      'categoryName': serializer.toJson<String>(categoryName),
      'score': serializer.toJson<double>(score),
      'hotScore': serializer.toJson<double>(hotScore),
      'persistence': serializer.toJson<double>(persistence),
      'trendStrength': serializer.toJson<double>(trendStrength),
      'riseCount': serializer.toJson<int>(riseCount),
      'fallCount': serializer.toJson<int>(fallCount),
      'totalCount': serializer.toJson<int>(totalCount),
    };
  }

  CategoryHistoryData copyWith({
    String? tradeDate,
    String? categoryName,
    double? score,
    double? hotScore,
    double? persistence,
    double? trendStrength,
    int? riseCount,
    int? fallCount,
    int? totalCount,
  }) => CategoryHistoryData(
    tradeDate: tradeDate ?? this.tradeDate,
    categoryName: categoryName ?? this.categoryName,
    score: score ?? this.score,
    hotScore: hotScore ?? this.hotScore,
    persistence: persistence ?? this.persistence,
    trendStrength: trendStrength ?? this.trendStrength,
    riseCount: riseCount ?? this.riseCount,
    fallCount: fallCount ?? this.fallCount,
    totalCount: totalCount ?? this.totalCount,
  );
  CategoryHistoryData copyWithCompanion(CategoryHistoryTableCompanion data) {
    return CategoryHistoryData(
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      score: data.score.present ? data.score.value : this.score,
      hotScore: data.hotScore.present ? data.hotScore.value : this.hotScore,
      persistence: data.persistence.present
          ? data.persistence.value
          : this.persistence,
      trendStrength: data.trendStrength.present
          ? data.trendStrength.value
          : this.trendStrength,
      riseCount: data.riseCount.present ? data.riseCount.value : this.riseCount,
      fallCount: data.fallCount.present ? data.fallCount.value : this.fallCount,
      totalCount: data.totalCount.present
          ? data.totalCount.value
          : this.totalCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryHistoryData(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('score: $score, ')
          ..write('hotScore: $hotScore, ')
          ..write('persistence: $persistence, ')
          ..write('trendStrength: $trendStrength, ')
          ..write('riseCount: $riseCount, ')
          ..write('fallCount: $fallCount, ')
          ..write('totalCount: $totalCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tradeDate,
    categoryName,
    score,
    hotScore,
    persistence,
    trendStrength,
    riseCount,
    fallCount,
    totalCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryHistoryData &&
          other.tradeDate == this.tradeDate &&
          other.categoryName == this.categoryName &&
          other.score == this.score &&
          other.hotScore == this.hotScore &&
          other.persistence == this.persistence &&
          other.trendStrength == this.trendStrength &&
          other.riseCount == this.riseCount &&
          other.fallCount == this.fallCount &&
          other.totalCount == this.totalCount);
}

class CategoryHistoryTableCompanion
    extends UpdateCompanion<CategoryHistoryData> {
  final Value<String> tradeDate;
  final Value<String> categoryName;
  final Value<double> score;
  final Value<double> hotScore;
  final Value<double> persistence;
  final Value<double> trendStrength;
  final Value<int> riseCount;
  final Value<int> fallCount;
  final Value<int> totalCount;
  final Value<int> rowid;
  const CategoryHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.score = const Value.absent(),
    this.hotScore = const Value.absent(),
    this.persistence = const Value.absent(),
    this.trendStrength = const Value.absent(),
    this.riseCount = const Value.absent(),
    this.fallCount = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryHistoryTableCompanion.insert({
    required String tradeDate,
    required String categoryName,
    required double score,
    required double hotScore,
    required double persistence,
    required double trendStrength,
    required int riseCount,
    required int fallCount,
    required int totalCount,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       categoryName = Value(categoryName),
       score = Value(score),
       hotScore = Value(hotScore),
       persistence = Value(persistence),
       trendStrength = Value(trendStrength),
       riseCount = Value(riseCount),
       fallCount = Value(fallCount),
       totalCount = Value(totalCount);
  static Insertable<CategoryHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? categoryName,
    Expression<double>? score,
    Expression<double>? hotScore,
    Expression<double>? persistence,
    Expression<double>? trendStrength,
    Expression<int>? riseCount,
    Expression<int>? fallCount,
    Expression<int>? totalCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (categoryName != null) 'category_name': categoryName,
      if (score != null) 'score': score,
      if (hotScore != null) 'hot_score': hotScore,
      if (persistence != null) 'persistence': persistence,
      if (trendStrength != null) 'trend_strength': trendStrength,
      if (riseCount != null) 'rise_count': riseCount,
      if (fallCount != null) 'fall_count': fallCount,
      if (totalCount != null) 'total_count': totalCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? categoryName,
    Value<double>? score,
    Value<double>? hotScore,
    Value<double>? persistence,
    Value<double>? trendStrength,
    Value<int>? riseCount,
    Value<int>? fallCount,
    Value<int>? totalCount,
    Value<int>? rowid,
  }) {
    return CategoryHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      categoryName: categoryName ?? this.categoryName,
      score: score ?? this.score,
      hotScore: hotScore ?? this.hotScore,
      persistence: persistence ?? this.persistence,
      trendStrength: trendStrength ?? this.trendStrength,
      riseCount: riseCount ?? this.riseCount,
      fallCount: fallCount ?? this.fallCount,
      totalCount: totalCount ?? this.totalCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (hotScore.present) {
      map['hot_score'] = Variable<double>(hotScore.value);
    }
    if (persistence.present) {
      map['persistence'] = Variable<double>(persistence.value);
    }
    if (trendStrength.present) {
      map['trend_strength'] = Variable<double>(trendStrength.value);
    }
    if (riseCount.present) {
      map['rise_count'] = Variable<int>(riseCount.value);
    }
    if (fallCount.present) {
      map['fall_count'] = Variable<int>(fallCount.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('score: $score, ')
          ..write('hotScore: $hotScore, ')
          ..write('persistence: $persistence, ')
          ..write('trendStrength: $trendStrength, ')
          ..write('riseCount: $riseCount, ')
          ..write('fallCount: $fallCount, ')
          ..write('totalCount: $totalCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MainstreamHistoryTableTable extends MainstreamHistoryTable
    with TableInfo<$MainstreamHistoryTableTable, MainstreamHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MainstreamHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankNoMeta = const VerificationMeta('rankNo');
  @override
  late final GeneratedColumn<int> rankNo = GeneratedColumn<int>(
    'rank_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tradeDate,
    categoryName,
    rankNo,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mainstream_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<MainstreamHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trade_date')) {
      context.handle(
        _tradeDateMeta,
        tradeDate.isAcceptableOrUnknown(data['trade_date']!, _tradeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_tradeDateMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('rank_no')) {
      context.handle(
        _rankNoMeta,
        rankNo.isAcceptableOrUnknown(data['rank_no']!, _rankNoMeta),
      );
    } else if (isInserting) {
      context.missing(_rankNoMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tradeDate, categoryName};
  @override
  MainstreamHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MainstreamHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      rankNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank_no'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $MainstreamHistoryTableTable createAlias(String alias) {
    return $MainstreamHistoryTableTable(attachedDatabase, alias);
  }
}

class MainstreamHistoryData extends DataClass
    implements Insertable<MainstreamHistoryData> {
  final String tradeDate;
  final String categoryName;
  final int rankNo;
  final double score;
  const MainstreamHistoryData({
    required this.tradeDate,
    required this.categoryName,
    required this.rankNo,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trade_date'] = Variable<String>(tradeDate);
    map['category_name'] = Variable<String>(categoryName);
    map['rank_no'] = Variable<int>(rankNo);
    map['score'] = Variable<double>(score);
    return map;
  }

  MainstreamHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return MainstreamHistoryTableCompanion(
      tradeDate: Value(tradeDate),
      categoryName: Value(categoryName),
      rankNo: Value(rankNo),
      score: Value(score),
    );
  }

  factory MainstreamHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MainstreamHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      rankNo: serializer.fromJson<int>(json['rankNo']),
      score: serializer.fromJson<double>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tradeDate': serializer.toJson<String>(tradeDate),
      'categoryName': serializer.toJson<String>(categoryName),
      'rankNo': serializer.toJson<int>(rankNo),
      'score': serializer.toJson<double>(score),
    };
  }

  MainstreamHistoryData copyWith({
    String? tradeDate,
    String? categoryName,
    int? rankNo,
    double? score,
  }) => MainstreamHistoryData(
    tradeDate: tradeDate ?? this.tradeDate,
    categoryName: categoryName ?? this.categoryName,
    rankNo: rankNo ?? this.rankNo,
    score: score ?? this.score,
  );
  MainstreamHistoryData copyWithCompanion(
    MainstreamHistoryTableCompanion data,
  ) {
    return MainstreamHistoryData(
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      rankNo: data.rankNo.present ? data.rankNo.value : this.rankNo,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MainstreamHistoryData(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('rankNo: $rankNo, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tradeDate, categoryName, rankNo, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MainstreamHistoryData &&
          other.tradeDate == this.tradeDate &&
          other.categoryName == this.categoryName &&
          other.rankNo == this.rankNo &&
          other.score == this.score);
}

class MainstreamHistoryTableCompanion
    extends UpdateCompanion<MainstreamHistoryData> {
  final Value<String> tradeDate;
  final Value<String> categoryName;
  final Value<int> rankNo;
  final Value<double> score;
  final Value<int> rowid;
  const MainstreamHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.rankNo = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MainstreamHistoryTableCompanion.insert({
    required String tradeDate,
    required String categoryName,
    required int rankNo,
    required double score,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       categoryName = Value(categoryName),
       rankNo = Value(rankNo),
       score = Value(score);
  static Insertable<MainstreamHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? categoryName,
    Expression<int>? rankNo,
    Expression<double>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (categoryName != null) 'category_name': categoryName,
      if (rankNo != null) 'rank_no': rankNo,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MainstreamHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? categoryName,
    Value<int>? rankNo,
    Value<double>? score,
    Value<int>? rowid,
  }) {
    return MainstreamHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      categoryName: categoryName ?? this.categoryName,
      rankNo: rankNo ?? this.rankNo,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (rankNo.present) {
      map['rank_no'] = Variable<int>(rankNo.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MainstreamHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('rankNo: $rankNo, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifecycleHistoryTableTable extends LifecycleHistoryTable
    with TableInfo<$LifecycleHistoryTableTable, LifecycleHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifecycleHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tradeDate, categoryName, stage];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lifecycle_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifecycleHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trade_date')) {
      context.handle(
        _tradeDateMeta,
        tradeDate.isAcceptableOrUnknown(data['trade_date']!, _tradeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_tradeDateMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tradeDate, categoryName};
  @override
  LifecycleHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifecycleHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
    );
  }

  @override
  $LifecycleHistoryTableTable createAlias(String alias) {
    return $LifecycleHistoryTableTable(attachedDatabase, alias);
  }
}

class LifecycleHistoryData extends DataClass
    implements Insertable<LifecycleHistoryData> {
  final String tradeDate;
  final String categoryName;
  final String stage;
  const LifecycleHistoryData({
    required this.tradeDate,
    required this.categoryName,
    required this.stage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trade_date'] = Variable<String>(tradeDate);
    map['category_name'] = Variable<String>(categoryName);
    map['stage'] = Variable<String>(stage);
    return map;
  }

  LifecycleHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return LifecycleHistoryTableCompanion(
      tradeDate: Value(tradeDate),
      categoryName: Value(categoryName),
      stage: Value(stage),
    );
  }

  factory LifecycleHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifecycleHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      stage: serializer.fromJson<String>(json['stage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tradeDate': serializer.toJson<String>(tradeDate),
      'categoryName': serializer.toJson<String>(categoryName),
      'stage': serializer.toJson<String>(stage),
    };
  }

  LifecycleHistoryData copyWith({
    String? tradeDate,
    String? categoryName,
    String? stage,
  }) => LifecycleHistoryData(
    tradeDate: tradeDate ?? this.tradeDate,
    categoryName: categoryName ?? this.categoryName,
    stage: stage ?? this.stage,
  );
  LifecycleHistoryData copyWithCompanion(LifecycleHistoryTableCompanion data) {
    return LifecycleHistoryData(
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      stage: data.stage.present ? data.stage.value : this.stage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifecycleHistoryData(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('stage: $stage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tradeDate, categoryName, stage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifecycleHistoryData &&
          other.tradeDate == this.tradeDate &&
          other.categoryName == this.categoryName &&
          other.stage == this.stage);
}

class LifecycleHistoryTableCompanion
    extends UpdateCompanion<LifecycleHistoryData> {
  final Value<String> tradeDate;
  final Value<String> categoryName;
  final Value<String> stage;
  final Value<int> rowid;
  const LifecycleHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.stage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifecycleHistoryTableCompanion.insert({
    required String tradeDate,
    required String categoryName,
    required String stage,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       categoryName = Value(categoryName),
       stage = Value(stage);
  static Insertable<LifecycleHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? categoryName,
    Expression<String>? stage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (categoryName != null) 'category_name': categoryName,
      if (stage != null) 'stage': stage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifecycleHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? categoryName,
    Value<String>? stage,
    Value<int>? rowid,
  }) {
    return LifecycleHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      categoryName: categoryName ?? this.categoryName,
      stage: stage ?? this.stage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifecycleHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('categoryName: $categoryName, ')
          ..write('stage: $stage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RotationHistoryTableTable extends RotationHistoryTable
    with TableInfo<$RotationHistoryTableTable, RotationHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RotationHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromCategoryMeta = const VerificationMeta(
    'fromCategory',
  );
  @override
  late final GeneratedColumn<String> fromCategory = GeneratedColumn<String>(
    'from_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toCategoryMeta = const VerificationMeta(
    'toCategory',
  );
  @override
  late final GeneratedColumn<String> toCategory = GeneratedColumn<String>(
    'to_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tradeDate,
    fromCategory,
    toCategory,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rotation_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<RotationHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trade_date')) {
      context.handle(
        _tradeDateMeta,
        tradeDate.isAcceptableOrUnknown(data['trade_date']!, _tradeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_tradeDateMeta);
    }
    if (data.containsKey('from_category')) {
      context.handle(
        _fromCategoryMeta,
        fromCategory.isAcceptableOrUnknown(
          data['from_category']!,
          _fromCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromCategoryMeta);
    }
    if (data.containsKey('to_category')) {
      context.handle(
        _toCategoryMeta,
        toCategory.isAcceptableOrUnknown(data['to_category']!, _toCategoryMeta),
      );
    } else if (isInserting) {
      context.missing(_toCategoryMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tradeDate, fromCategory, toCategory};
  @override
  RotationHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RotationHistoryData(
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      fromCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_category'],
      )!,
      toCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_category'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $RotationHistoryTableTable createAlias(String alias) {
    return $RotationHistoryTableTable(attachedDatabase, alias);
  }
}

class RotationHistoryData extends DataClass
    implements Insertable<RotationHistoryData> {
  final String tradeDate;
  final String fromCategory;
  final String toCategory;
  final double score;
  const RotationHistoryData({
    required this.tradeDate,
    required this.fromCategory,
    required this.toCategory,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trade_date'] = Variable<String>(tradeDate);
    map['from_category'] = Variable<String>(fromCategory);
    map['to_category'] = Variable<String>(toCategory);
    map['score'] = Variable<double>(score);
    return map;
  }

  RotationHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return RotationHistoryTableCompanion(
      tradeDate: Value(tradeDate),
      fromCategory: Value(fromCategory),
      toCategory: Value(toCategory),
      score: Value(score),
    );
  }

  factory RotationHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RotationHistoryData(
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      fromCategory: serializer.fromJson<String>(json['fromCategory']),
      toCategory: serializer.fromJson<String>(json['toCategory']),
      score: serializer.fromJson<double>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tradeDate': serializer.toJson<String>(tradeDate),
      'fromCategory': serializer.toJson<String>(fromCategory),
      'toCategory': serializer.toJson<String>(toCategory),
      'score': serializer.toJson<double>(score),
    };
  }

  RotationHistoryData copyWith({
    String? tradeDate,
    String? fromCategory,
    String? toCategory,
    double? score,
  }) => RotationHistoryData(
    tradeDate: tradeDate ?? this.tradeDate,
    fromCategory: fromCategory ?? this.fromCategory,
    toCategory: toCategory ?? this.toCategory,
    score: score ?? this.score,
  );
  RotationHistoryData copyWithCompanion(RotationHistoryTableCompanion data) {
    return RotationHistoryData(
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      fromCategory: data.fromCategory.present
          ? data.fromCategory.value
          : this.fromCategory,
      toCategory: data.toCategory.present
          ? data.toCategory.value
          : this.toCategory,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RotationHistoryData(')
          ..write('tradeDate: $tradeDate, ')
          ..write('fromCategory: $fromCategory, ')
          ..write('toCategory: $toCategory, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tradeDate, fromCategory, toCategory, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RotationHistoryData &&
          other.tradeDate == this.tradeDate &&
          other.fromCategory == this.fromCategory &&
          other.toCategory == this.toCategory &&
          other.score == this.score);
}

class RotationHistoryTableCompanion
    extends UpdateCompanion<RotationHistoryData> {
  final Value<String> tradeDate;
  final Value<String> fromCategory;
  final Value<String> toCategory;
  final Value<double> score;
  final Value<int> rowid;
  const RotationHistoryTableCompanion({
    this.tradeDate = const Value.absent(),
    this.fromCategory = const Value.absent(),
    this.toCategory = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RotationHistoryTableCompanion.insert({
    required String tradeDate,
    required String fromCategory,
    required String toCategory,
    required double score,
    this.rowid = const Value.absent(),
  }) : tradeDate = Value(tradeDate),
       fromCategory = Value(fromCategory),
       toCategory = Value(toCategory),
       score = Value(score);
  static Insertable<RotationHistoryData> custom({
    Expression<String>? tradeDate,
    Expression<String>? fromCategory,
    Expression<String>? toCategory,
    Expression<double>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tradeDate != null) 'trade_date': tradeDate,
      if (fromCategory != null) 'from_category': fromCategory,
      if (toCategory != null) 'to_category': toCategory,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RotationHistoryTableCompanion copyWith({
    Value<String>? tradeDate,
    Value<String>? fromCategory,
    Value<String>? toCategory,
    Value<double>? score,
    Value<int>? rowid,
  }) {
    return RotationHistoryTableCompanion(
      tradeDate: tradeDate ?? this.tradeDate,
      fromCategory: fromCategory ?? this.fromCategory,
      toCategory: toCategory ?? this.toCategory,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (fromCategory.present) {
      map['from_category'] = Variable<String>(fromCategory.value);
    }
    if (toCategory.present) {
      map['to_category'] = Variable<String>(toCategory.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RotationHistoryTableCompanion(')
          ..write('tradeDate: $tradeDate, ')
          ..write('fromCategory: $fromCategory, ')
          ..write('toCategory: $toCategory, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoryHistoryTableTable categoryHistoryTable =
      $CategoryHistoryTableTable(this);
  late final $MainstreamHistoryTableTable mainstreamHistoryTable =
      $MainstreamHistoryTableTable(this);
  late final $LifecycleHistoryTableTable lifecycleHistoryTable =
      $LifecycleHistoryTableTable(this);
  late final $RotationHistoryTableTable rotationHistoryTable =
      $RotationHistoryTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categoryHistoryTable,
    mainstreamHistoryTable,
    lifecycleHistoryTable,
    rotationHistoryTable,
  ];
}

typedef $$CategoryHistoryTableTableCreateCompanionBuilder =
    CategoryHistoryTableCompanion Function({
      required String tradeDate,
      required String categoryName,
      required double score,
      required double hotScore,
      required double persistence,
      required double trendStrength,
      required int riseCount,
      required int fallCount,
      required int totalCount,
      Value<int> rowid,
    });
typedef $$CategoryHistoryTableTableUpdateCompanionBuilder =
    CategoryHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> categoryName,
      Value<double> score,
      Value<double> hotScore,
      Value<double> persistence,
      Value<double> trendStrength,
      Value<int> riseCount,
      Value<int> fallCount,
      Value<int> totalCount,
      Value<int> rowid,
    });

class $$CategoryHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryHistoryTableTable> {
  $$CategoryHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hotScore => $composableBuilder(
    column: $table.hotScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get persistence => $composableBuilder(
    column: $table.persistence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get trendStrength => $composableBuilder(
    column: $table.trendStrength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get riseCount => $composableBuilder(
    column: $table.riseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fallCount => $composableBuilder(
    column: $table.fallCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryHistoryTableTable> {
  $$CategoryHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hotScore => $composableBuilder(
    column: $table.hotScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get persistence => $composableBuilder(
    column: $table.persistence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get trendStrength => $composableBuilder(
    column: $table.trendStrength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get riseCount => $composableBuilder(
    column: $table.riseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fallCount => $composableBuilder(
    column: $table.fallCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryHistoryTableTable> {
  $$CategoryHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get hotScore =>
      $composableBuilder(column: $table.hotScore, builder: (column) => column);

  GeneratedColumn<double> get persistence => $composableBuilder(
    column: $table.persistence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get trendStrength => $composableBuilder(
    column: $table.trendStrength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get riseCount =>
      $composableBuilder(column: $table.riseCount, builder: (column) => column);

  GeneratedColumn<int> get fallCount =>
      $composableBuilder(column: $table.fallCount, builder: (column) => column);

  GeneratedColumn<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => column,
  );
}

class $$CategoryHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryHistoryTableTable,
          CategoryHistoryData,
          $$CategoryHistoryTableTableFilterComposer,
          $$CategoryHistoryTableTableOrderingComposer,
          $$CategoryHistoryTableTableAnnotationComposer,
          $$CategoryHistoryTableTableCreateCompanionBuilder,
          $$CategoryHistoryTableTableUpdateCompanionBuilder,
          (
            CategoryHistoryData,
            BaseReferences<
              _$AppDatabase,
              $CategoryHistoryTableTable,
              CategoryHistoryData
            >,
          ),
          CategoryHistoryData,
          PrefetchHooks Function()
        > {
  $$CategoryHistoryTableTableTableManager(
    _$AppDatabase db,
    $CategoryHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CategoryHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tradeDate = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> hotScore = const Value.absent(),
                Value<double> persistence = const Value.absent(),
                Value<double> trendStrength = const Value.absent(),
                Value<int> riseCount = const Value.absent(),
                Value<int> fallCount = const Value.absent(),
                Value<int> totalCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryHistoryTableCompanion(
                tradeDate: tradeDate,
                categoryName: categoryName,
                score: score,
                hotScore: hotScore,
                persistence: persistence,
                trendStrength: trendStrength,
                riseCount: riseCount,
                fallCount: fallCount,
                totalCount: totalCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String categoryName,
                required double score,
                required double hotScore,
                required double persistence,
                required double trendStrength,
                required int riseCount,
                required int fallCount,
                required int totalCount,
                Value<int> rowid = const Value.absent(),
              }) => CategoryHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                categoryName: categoryName,
                score: score,
                hotScore: hotScore,
                persistence: persistence,
                trendStrength: trendStrength,
                riseCount: riseCount,
                fallCount: fallCount,
                totalCount: totalCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryHistoryTableTable,
      CategoryHistoryData,
      $$CategoryHistoryTableTableFilterComposer,
      $$CategoryHistoryTableTableOrderingComposer,
      $$CategoryHistoryTableTableAnnotationComposer,
      $$CategoryHistoryTableTableCreateCompanionBuilder,
      $$CategoryHistoryTableTableUpdateCompanionBuilder,
      (
        CategoryHistoryData,
        BaseReferences<
          _$AppDatabase,
          $CategoryHistoryTableTable,
          CategoryHistoryData
        >,
      ),
      CategoryHistoryData,
      PrefetchHooks Function()
    >;
typedef $$MainstreamHistoryTableTableCreateCompanionBuilder =
    MainstreamHistoryTableCompanion Function({
      required String tradeDate,
      required String categoryName,
      required int rankNo,
      required double score,
      Value<int> rowid,
    });
typedef $$MainstreamHistoryTableTableUpdateCompanionBuilder =
    MainstreamHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> categoryName,
      Value<int> rankNo,
      Value<double> score,
      Value<int> rowid,
    });

class $$MainstreamHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $MainstreamHistoryTableTable> {
  $$MainstreamHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rankNo => $composableBuilder(
    column: $table.rankNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MainstreamHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MainstreamHistoryTableTable> {
  $$MainstreamHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rankNo => $composableBuilder(
    column: $table.rankNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MainstreamHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MainstreamHistoryTableTable> {
  $$MainstreamHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rankNo =>
      $composableBuilder(column: $table.rankNo, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$MainstreamHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MainstreamHistoryTableTable,
          MainstreamHistoryData,
          $$MainstreamHistoryTableTableFilterComposer,
          $$MainstreamHistoryTableTableOrderingComposer,
          $$MainstreamHistoryTableTableAnnotationComposer,
          $$MainstreamHistoryTableTableCreateCompanionBuilder,
          $$MainstreamHistoryTableTableUpdateCompanionBuilder,
          (
            MainstreamHistoryData,
            BaseReferences<
              _$AppDatabase,
              $MainstreamHistoryTableTable,
              MainstreamHistoryData
            >,
          ),
          MainstreamHistoryData,
          PrefetchHooks Function()
        > {
  $$MainstreamHistoryTableTableTableManager(
    _$AppDatabase db,
    $MainstreamHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MainstreamHistoryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MainstreamHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MainstreamHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tradeDate = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<int> rankNo = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MainstreamHistoryTableCompanion(
                tradeDate: tradeDate,
                categoryName: categoryName,
                rankNo: rankNo,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String categoryName,
                required int rankNo,
                required double score,
                Value<int> rowid = const Value.absent(),
              }) => MainstreamHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                categoryName: categoryName,
                rankNo: rankNo,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MainstreamHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MainstreamHistoryTableTable,
      MainstreamHistoryData,
      $$MainstreamHistoryTableTableFilterComposer,
      $$MainstreamHistoryTableTableOrderingComposer,
      $$MainstreamHistoryTableTableAnnotationComposer,
      $$MainstreamHistoryTableTableCreateCompanionBuilder,
      $$MainstreamHistoryTableTableUpdateCompanionBuilder,
      (
        MainstreamHistoryData,
        BaseReferences<
          _$AppDatabase,
          $MainstreamHistoryTableTable,
          MainstreamHistoryData
        >,
      ),
      MainstreamHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LifecycleHistoryTableTableCreateCompanionBuilder =
    LifecycleHistoryTableCompanion Function({
      required String tradeDate,
      required String categoryName,
      required String stage,
      Value<int> rowid,
    });
typedef $$LifecycleHistoryTableTableUpdateCompanionBuilder =
    LifecycleHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> categoryName,
      Value<String> stage,
      Value<int> rowid,
    });

class $$LifecycleHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $LifecycleHistoryTableTable> {
  $$LifecycleHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LifecycleHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LifecycleHistoryTableTable> {
  $$LifecycleHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LifecycleHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifecycleHistoryTableTable> {
  $$LifecycleHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);
}

class $$LifecycleHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LifecycleHistoryTableTable,
          LifecycleHistoryData,
          $$LifecycleHistoryTableTableFilterComposer,
          $$LifecycleHistoryTableTableOrderingComposer,
          $$LifecycleHistoryTableTableAnnotationComposer,
          $$LifecycleHistoryTableTableCreateCompanionBuilder,
          $$LifecycleHistoryTableTableUpdateCompanionBuilder,
          (
            LifecycleHistoryData,
            BaseReferences<
              _$AppDatabase,
              $LifecycleHistoryTableTable,
              LifecycleHistoryData
            >,
          ),
          LifecycleHistoryData,
          PrefetchHooks Function()
        > {
  $$LifecycleHistoryTableTableTableManager(
    _$AppDatabase db,
    $LifecycleHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifecycleHistoryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LifecycleHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LifecycleHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tradeDate = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifecycleHistoryTableCompanion(
                tradeDate: tradeDate,
                categoryName: categoryName,
                stage: stage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String categoryName,
                required String stage,
                Value<int> rowid = const Value.absent(),
              }) => LifecycleHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                categoryName: categoryName,
                stage: stage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LifecycleHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LifecycleHistoryTableTable,
      LifecycleHistoryData,
      $$LifecycleHistoryTableTableFilterComposer,
      $$LifecycleHistoryTableTableOrderingComposer,
      $$LifecycleHistoryTableTableAnnotationComposer,
      $$LifecycleHistoryTableTableCreateCompanionBuilder,
      $$LifecycleHistoryTableTableUpdateCompanionBuilder,
      (
        LifecycleHistoryData,
        BaseReferences<
          _$AppDatabase,
          $LifecycleHistoryTableTable,
          LifecycleHistoryData
        >,
      ),
      LifecycleHistoryData,
      PrefetchHooks Function()
    >;
typedef $$RotationHistoryTableTableCreateCompanionBuilder =
    RotationHistoryTableCompanion Function({
      required String tradeDate,
      required String fromCategory,
      required String toCategory,
      required double score,
      Value<int> rowid,
    });
typedef $$RotationHistoryTableTableUpdateCompanionBuilder =
    RotationHistoryTableCompanion Function({
      Value<String> tradeDate,
      Value<String> fromCategory,
      Value<String> toCategory,
      Value<double> score,
      Value<int> rowid,
    });

class $$RotationHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $RotationHistoryTableTable> {
  $$RotationHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromCategory => $composableBuilder(
    column: $table.fromCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toCategory => $composableBuilder(
    column: $table.toCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RotationHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RotationHistoryTableTable> {
  $$RotationHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromCategory => $composableBuilder(
    column: $table.fromCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toCategory => $composableBuilder(
    column: $table.toCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RotationHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RotationHistoryTableTable> {
  $$RotationHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<String> get fromCategory => $composableBuilder(
    column: $table.fromCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toCategory => $composableBuilder(
    column: $table.toCategory,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$RotationHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RotationHistoryTableTable,
          RotationHistoryData,
          $$RotationHistoryTableTableFilterComposer,
          $$RotationHistoryTableTableOrderingComposer,
          $$RotationHistoryTableTableAnnotationComposer,
          $$RotationHistoryTableTableCreateCompanionBuilder,
          $$RotationHistoryTableTableUpdateCompanionBuilder,
          (
            RotationHistoryData,
            BaseReferences<
              _$AppDatabase,
              $RotationHistoryTableTable,
              RotationHistoryData
            >,
          ),
          RotationHistoryData,
          PrefetchHooks Function()
        > {
  $$RotationHistoryTableTableTableManager(
    _$AppDatabase db,
    $RotationHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RotationHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RotationHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RotationHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tradeDate = const Value.absent(),
                Value<String> fromCategory = const Value.absent(),
                Value<String> toCategory = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RotationHistoryTableCompanion(
                tradeDate: tradeDate,
                fromCategory: fromCategory,
                toCategory: toCategory,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tradeDate,
                required String fromCategory,
                required String toCategory,
                required double score,
                Value<int> rowid = const Value.absent(),
              }) => RotationHistoryTableCompanion.insert(
                tradeDate: tradeDate,
                fromCategory: fromCategory,
                toCategory: toCategory,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RotationHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RotationHistoryTableTable,
      RotationHistoryData,
      $$RotationHistoryTableTableFilterComposer,
      $$RotationHistoryTableTableOrderingComposer,
      $$RotationHistoryTableTableAnnotationComposer,
      $$RotationHistoryTableTableCreateCompanionBuilder,
      $$RotationHistoryTableTableUpdateCompanionBuilder,
      (
        RotationHistoryData,
        BaseReferences<
          _$AppDatabase,
          $RotationHistoryTableTable,
          RotationHistoryData
        >,
      ),
      RotationHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoryHistoryTableTableTableManager get categoryHistoryTable =>
      $$CategoryHistoryTableTableTableManager(_db, _db.categoryHistoryTable);
  $$MainstreamHistoryTableTableTableManager get mainstreamHistoryTable =>
      $$MainstreamHistoryTableTableTableManager(
        _db,
        _db.mainstreamHistoryTable,
      );
  $$LifecycleHistoryTableTableTableManager get lifecycleHistoryTable =>
      $$LifecycleHistoryTableTableTableManager(_db, _db.lifecycleHistoryTable);
  $$RotationHistoryTableTableTableManager get rotationHistoryTable =>
      $$RotationHistoryTableTableTableManager(_db, _db.rotationHistoryTable);
}

`

### lib\data\database\tables\category_history_table.dart

`dart
import 'package:drift/drift.dart';

@DataClassName('CategoryHistoryData')
class CategoryHistoryTable extends Table {
  @override
  String get tableName => 'category_history';

  // 1. 如果你不需要自增 id，請直接刪除它，改由交易日期與產業名稱作為聯合主鍵
  TextColumn get tradeDate => text()();
  TextColumn get categoryName => text()();

  // 核心指標
  RealColumn get score => real()();
  RealColumn get hotScore => real()();
  RealColumn get persistence => real()();
  RealColumn get trendStrength => real()();

  // 家數統計
  IntColumn get riseCount => integer()();
  IntColumn get fallCount => integer()();
  IntColumn get totalCount => integer()();

  // 2. 正確宣告複合主鍵（這會自動覆蓋掉預設的主鍵機制）
  @override
  Set<Column> get primaryKey => {tradeDate, categoryName};
}

`

### lib\data\database\tables\lifecycle_history_table.dart

`dart
import 'package:drift/drift.dart';

@DataClassName('LifecycleHistoryData')
class LifecycleHistoryTable extends Table {
  @override
  String get tableName => 'lifecycle_history';

  // 複合主鍵之一：交易日期
  TextColumn get tradeDate => text()();

  // 複合主鍵之二：產業名稱
  TextColumn get categoryName => text()();

  // 生命週期階段 (例如: Emerging, Expanding, Climax, Declining)
  TextColumn get stage => text()();

  @override
  Set<Column> get primaryKey => {tradeDate, categoryName};
}

`

### lib\data\database\tables\mainstream_history_table.dart

`dart
import 'package:drift/drift.dart';

@DataClassName('MainstreamHistoryData')
class MainstreamHistoryTable extends Table {
  @override
  String get tableName => 'mainstream_history';

  // 複合主鍵之一：交易日期
  TextColumn get tradeDate => text()();

  // 複合主鍵之二：產業名稱
  TextColumn get categoryName => text()();

  // 排名
  IntColumn get rankNo => integer()();

  // 分數
  RealColumn get score => real()();

  @override
  Set<Column> get primaryKey => {tradeDate, categoryName};
}

`

### lib\data\database\tables\rotation_history_table.dart

`dart
import 'package:drift/drift.dart';

@DataClassName('RotationHistoryData')
class RotationHistoryTable extends Table {
  @override
  String get tableName => 'rotation_history';

  // 交易日期
  TextColumn get tradeDate => text()();

  // 資金流出產業
  TextColumn get fromCategory => text()();

  // 資金流入產業
  TextColumn get toCategory => text()();

  // 輪動強度分數
  RealColumn get score => real()();

  // 自訂複合主鍵
  @override
  Set<Column> get primaryKey => {tradeDate, fromCategory, toCategory};
}

`

### lib\data\history\repositories\category_history_repository.dart

`dart
import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/models/analysis_snapshot.dart';
import 'package:drift/drift.dart';

class CategoryHistoryRepository {
  final AppDatabase db;

  CategoryHistoryRepository(this.db);

  /// 🚀 Phase 5 修正升級：從本地 SQLite 撈取特定產業過去 N 天的歷史紀錄
  /// 💡 加上 .reversed.toList() 將資料改為「由舊到新」排序，以完美對接 fl_chart 圖表繪製需求
  Future<List<CategoryHistoryData>> getCategoryTrend(
    String categoryName, {
    int limit = 15, // 調整預設抓取 15 天或 20 天，讓看盤圖更精確
  }) async {
    final results =
        await (db.select(db.categoryHistoryTable)
              ..where((t) => t.categoryName.equals(categoryName))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.tradeDate,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit))
            .get();

    // 💡 降序拿出來後反轉，使陣列最左邊是舊資料，最右邊是最新資料
    return results.reversed.toList();
  }

  /// 儲存每日完整的資金流 analysis 快照
  Future<void> saveDailySnapshot({
    required List<CategoryUiModel> categories,
    required AnalysisSnapshot snapshot,
  }) async {
    final String dateStr = snapshot.date;

    await db.transaction(() async {
      // 1. 儲存產業今日快照 (category_history)
      for (final category in categories) {
        await db
            .into(db.categoryHistoryTable)
            .insertOnConflictUpdate(
              CategoryHistoryTableCompanion.insert(
                tradeDate: dateStr,
                categoryName: category.name,
                score: category.score,
                hotScore: category.hotScore,
                persistence: category.persistence,
                trendStrength: category.trendStrength,
                riseCount: category.riseCount,
                fallCount: category.fallCount,
                totalCount: category.totalCount,
              ),
            );
      }

      // 2. 儲存主流排行 (mainstream_history)
      for (int i = 0; i < snapshot.mainstreams.length; i++) {
        final ms = snapshot.mainstreams[i];
        await db
            .into(db.mainstreamHistoryTable)
            .insertOnConflictUpdate(
              MainstreamHistoryTableCompanion.insert(
                tradeDate: dateStr,
                categoryName: ms.categoryName ?? ms.name ?? '',
                rankNo: i + 1,
                score: (ms.score as num).toDouble(),
              ),
            );
      }

      // 3. 儲存生命週期 (lifecycle_history)
      for (final lc in snapshot.lifecycles) {
        await db
            .into(db.lifecycleHistoryTable)
            .insertOnConflictUpdate(
              LifecycleHistoryTableCompanion.insert(
                tradeDate: dateStr,
                categoryName: lc.categoryName ?? lc.name ?? '',
                stage: lc.stage.toString(),
              ),
            );
      }

      // 4. 儲存資金輪動 (rotation_history)
      for (final rt in snapshot.rotations) {
        await db
            .into(db.rotationHistoryTable)
            .insertOnConflictUpdate(
              RotationHistoryTableCompanion.insert(
                tradeDate: dateStr,
                fromCategory: rt.fromCategory.toString(),
                toCategory: rt.toCategory.toString(),
                score: (rt.score as num).toDouble(),
              ),
            );
      }
    });
  }
}

`

### lib\data\managers\sync_manager.dart

`dart
import 'dart:developer' as dev;

import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/data/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/data/services/stock_service.dart';

class SyncResult {
  final bool success;

  final bool saved;

  final String message;

  final String date;

  final int stockCount;

  final List<StockData> stocks;

  SyncResult({
    required this.success,
    required this.saved,
    required this.message,
    required this.date,
    required this.stockCount,
    required this.stocks,
  });
}

class SyncManager {
  final StorageService storageService;

  final MarketCalendarService calendarService;

  SyncManager({required this.storageService, required this.calendarService});

  Future<SyncResult> syncTodayData() async {
    try {
      dev.log('開始同步今日股市資料', name: 'SyncManager');

      await StockService.loadMapping();

      dev.log('開始抓取上市資料', name: 'SyncManager');

      final listed = await StockService.fetchListed();

      final listedDate = StockService.lastDataDate;

      dev.log('上市資料筆數: ${listed.length}', name: 'SyncManager');

      dev.log('開始抓取上櫃資料', name: 'SyncManager');

      final otc = await StockService.fetchOTC();

      final otcDate = StockService.lastDataDate;

      dev.log('上櫃資料筆數: ${otc.length}', name: 'SyncManager');

      if (listed.isEmpty && otc.isEmpty) {
        return SyncResult(
          success: false,
          saved: false,
          message: '上市與上櫃資料皆為空',
          date: '',
          stockCount: 0,
          stocks: [],
        );
      }

      final latestDate = _resolveLatestDate(
        listedDate: listedDate,
        otcDate: otcDate,
      );

      if (latestDate.isEmpty) {
        return SyncResult(
          success: false,
          saved: false,
          message: '無法取得有效交易日期',
          date: '',
          stockCount: 0,
          stocks: [],
        );
      }

      // 🚨 新增：檢查兩個來源日期是否差異過大
      if (listedDate.isNotEmpty &&
          otcDate.isNotEmpty &&
          listedDate != otcDate) {
        dev.log(
          '⚠️ 警告：上市與上櫃資料日期不同步！上市:$listedDate | 上櫃:$otcDate | 最終採用:$latestDate',
          name: 'SyncManager',
        );
      }

      final allStocks = <StockData>[...listed, ...otc];

      dev.log('合併後總股票數: ${allStocks.length}', name: 'SyncManager');

      final localDates = await storageService.listAvailableDates();

      final isNewTradingDay = calendarService.isNewTradingDay(
        latestApiDate: latestDate,
        localDates: localDates,
      );

      if (!isNewTradingDay) {
        dev.log('今日資料已存在，略過保存', name: 'SyncManager');

        final existingSnapshot = await storageService.loadSnapshot(latestDate);

        return SyncResult(
          success: true,
          saved: false,
          message: '今日資料已存在',
          date: latestDate,
          stockCount: existingSnapshot?.stocks.length ?? allStocks.length,
          stocks: existingSnapshot?.stocks ?? allStocks,
        );
      }

      final snapshot = StockDaySnapshot(date: latestDate, stocks: allStocks);

      await storageService.saveDailySnapshot(snapshot);

      dev.log('資料同步成功: $latestDate', name: 'SyncManager');

      return SyncResult(
        success: true,
        saved: true,
        message: '同步成功',
        date: latestDate,
        stockCount: allStocks.length,
        stocks: allStocks,
      );
    } catch (e, stack) {
      dev.log('同步失敗: $e', name: 'SyncManager', error: e, stackTrace: stack);

      // 即使失敗，也盡量返回本地最新日期
      final lastDate = await storageService.getLatestAvailableDate();

      return SyncResult(
        success: false,
        saved: false,
        message: e.toString(),
        date: lastDate ?? '',
        stockCount: 0,
        stocks: [],
      );
    }
  }

  String _resolveLatestDate({
    required String listedDate,
    required String otcDate,
  }) {
    if (listedDate.isEmpty && otcDate.isEmpty) return '';
    if (listedDate.isEmpty) return otcDate;
    if (otcDate.isEmpty) return listedDate;

    // 取兩個日期中「較新」的
    if (listedDate.compareTo(otcDate) > 0) {
      dev.log('📅 選擇上市日期（較新）: $listedDate', name: 'SyncManager');
      return listedDate;
    } else {
      dev.log('📅 選擇上櫃日期（較新）: $otcDate', name: 'SyncManager');
      return otcDate;
    }
  }
}

`

### lib\data\models\analysis_snapshot.dart

`dart
class AnalysisSnapshot {
  final String date;

  final List<dynamic> mainstreams;

  final List<dynamic> lifecycles;

  final List<dynamic> rotations;

  final Map<String, dynamic> sentiment;

  const AnalysisSnapshot({
    required this.date,
    required this.mainstreams,
    required this.lifecycles,
    required this.rotations,
    required this.sentiment,
  });
}

`

### lib\data\models\flow_signal.dart

`dart
enum FlowDirection { inflow, outflow, neutral }

class FlowSignal {
  final double score;

  final double volumeRatio;

  final double momentumScore;

  final double persistenceScore;

  final FlowDirection direction;

  const FlowSignal({
    required this.score,
    required this.volumeRatio,
    required this.momentumScore,
    required this.persistenceScore,
    required this.direction,
  });
}

`

### lib\data\models\rotation_result.dart

`dart
class RotationResult {
  final String fromCategory;

  final String toCategory;

  final double score;

  final double inflowStrength;

  const RotationResult({
    required this.fromCategory,
    required this.toCategory,
    required this.score,
    required this.inflowStrength,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromCategory': fromCategory,
      'toCategory': toCategory,
      'score': score,
      'inflowStrength': inflowStrength,
    };
  }

  factory RotationResult.fromJson(Map<String, dynamic> json) {
    return RotationResult(
      fromCategory: json['fromCategory'],

      toCategory: json['toCategory'],

      score: (json['score'] ?? 0).toDouble(),

      inflowStrength: (json['inflowStrength'] ?? 0).toDouble(),
    );
  }
}

`

### lib\data\models\stock_data.dart

`dart
import 'package:tw_stock_capital_flow/core/extensions/market_type_extension.dart';

enum MarketType { listed, otc }

class StockData {
  final String code;
  final String name;
  final MarketType market;
  final String mainCategory;
  final String subCategory;
  final double open;
  final double high;
  final double low;
  final double close;
  final double change;
  final double changePercent;
  final int volume;
  final int value;

  StockData({
    required this.code,
    required this.name,
    required this.market,
    required this.mainCategory,
    required this.subCategory,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.value,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      code: json['code'],
      name: json['name'],
      market: MarketTypeExtension.fromString(json['market']),
      mainCategory: json['mainCategory'],
      subCategory: json['subCategory'],
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
      value: json['value'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'market': market.value,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'value': value,
    };
  }
}

`

### lib\data\models\stock_day_snapshot.dart

`dart
import 'stock_data.dart';

class StockDaySnapshot {
  final String date;

  final List<StockData> stocks;

  StockDaySnapshot({required this.date, required this.stocks});

  factory StockDaySnapshot.fromJson(Map<String, dynamic> json) {
    return StockDaySnapshot(
      date: json['date'],
      stocks: (json['stocks'] as List)
          .map((e) => StockData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'stocks': stocks.map((e) => e.toJson()).toList()};
  }
}

`

### lib\data\models\stock_score.dart

`dart
class StockScore {
  final String code;

  final String name;

  final double amountRatio;

  final double priceScore;

  final double finalScore;

  StockScore({
    required this.code,
    required this.name,
    required this.amountRatio,
    required this.priceScore,
    required this.finalScore,
  });
}

`

### lib\data\repositories\history_repository.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';

class HistoryRepository {
  final StorageService storageService;

  HistoryRepository({required this.storageService});

  Future<List<StockDaySnapshot>> loadRecentSnapshots(int days) async {
    final dates = await storageService.listAvailableDates();

    final selectedDates = dates.take(days).toList();

    final result = <StockDaySnapshot>[];

    for (final date in selectedDates) {
      final snapshot = await storageService.loadSnapshot(date);

      if (snapshot != null) {
        result.add(snapshot);
      }
    }

    return result;
  }
}

`

### lib\data\services\analysis_cache_service.dart

`dart
import 'dart:convert';
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/domain/enums/sentiment_level.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'dart:developer' as dev;

class AnalysisCacheService {
  final StorageService _storageService;
  static const String _cachePrefix = 'bootstrap_cache_';

  AnalysisCacheService(this._storageService);

  /// 將全域計算好的 AppBootstrapResult 轉換成 JSON，並借用專案現有的快取儲存通道
  Future<void> saveBootstrapCache(
    String dateKey,
    AppBootstrapResult result,
  ) async {
    try {
      final Map<String, dynamic> jsonMap = {
        'listedRiseCount': result.listedRiseCount,
        'listedFallCount': result.listedFallCount,
        'otcRiseCount': result.otcRiseCount,
        'otcFallCount': result.otcFallCount,
        'listedScore': result.listedScore,
        'otcScore': result.otcScore,
        'listedCategories': result.listedCategories
            .map((e) => _categoryToMap(e))
            .toList(),
        'otcCategories': result.otcCategories
            .map((e) => _categoryToMap(e))
            .toList(),
        'mainstreams': result.mainstreams
            .map((e) => _mainstreamToMap(e))
            .toList(),
        'lifecycles': result.lifecycles.map((e) => _lifecycleToMap(e)).toList(),
        'rotations': result.rotations
            .map((e) => e.toJson())
            .toList(), // 點 4：使用專案內建的 toJson
        'sentiment': _sentimentToMap(result.sentiment),
      };

      final jsonString = jsonEncode(jsonMap);

      // 利用現有的通道將 jsonString 拼接在 date 內，安全傳入硬碟中儲存
      await _storageService.saveDailySnapshot(
        StockDaySnapshot(
          date: '$_cachePrefix$dateKey|$jsonString',
          stocks: const [],
        ),
      );
    } catch (_) {}
  }

  /// 嘗試讀取今日快取，完美還原為強型別物件
  Future<AppBootstrapResult?> loadBootstrapCache(String dateKey) async {
    try {
      // 修正點 1：依據 StorageService 實作，讀取應呼叫 loadSnapshot
      final snapshot = await _storageService.loadSnapshot(
        '$_cachePrefix$dateKey',
      );
      if (snapshot == null || snapshot.date.isEmpty) return null;

      // 解析出當初拼接進去的 JSON 字串
      final parts = snapshot.date.split('|');
      if (parts.length < 2) return null;

      final jsonString = parts[1];
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // 還原為完整的 AppBootstrapResult 物件
      return AppBootstrapResult(
        listedRiseCount: jsonMap['listedRiseCount'] ?? 0,
        listedFallCount: jsonMap['listedFallCount'] ?? 0,
        otcRiseCount: jsonMap['otcRiseCount'] ?? 0,
        otcFallCount: jsonMap['otcFallCount'] ?? 0,
        listedScore: (jsonMap['listedScore'] ?? 0.0).toDouble(),
        otcScore: (jsonMap['otcScore'] ?? 0.0).toDouble(),
        listedCategories: (jsonMap['listedCategories'] as List)
            .map((e) => _mapToCategory(e))
            .toList(),
        otcCategories: (jsonMap['otcCategories'] as List)
            .map((e) => _mapToCategory(e))
            .toList(),
        mainstreams: (jsonMap['mainstreams'] as List)
            .map((e) => _mapToMainstream(e))
            .toList(), // 點 2：對齊主流引擎
        lifecycles: (jsonMap['lifecycles'] as List)
            .map((e) => _mapToLifecycle(e))
            .toList(), // 點 3：對齊生命週期引擎
        rotations: (jsonMap['rotations'] as List)
            .map((e) => RotationResult.fromJson(e))
            .toList(), // 點 4：使用專案內建的 fromJson
        sentiment: _mapToSentiment(jsonMap['sentiment']),
      );
    } catch (_) {
      return null;
    }
  }

  /// 離線防禦兜底機制
  Future<AppBootstrapResult?> tryGetAnyLatestCache() async {
    try {
      // 🚀 修正點：因為 getAllKeys 回傳 Future，這裡必須加上 await 喔！
      final List<String> keys = await _storageService.getAllKeys();

      if (keys.isEmpty) return null;

      // 篩選屬於資金流快取的 Key
      final cacheKeys = keys
          .where((k) => k.startsWith('bootstrap_cache_'))
          .toList();
      if (cacheKeys.isEmpty) return null;

      // 排序並還原日期標籤
      cacheKeys.sort((a, b) => b.compareTo(a));
      final String latestCacheKey = cacheKeys.first.replaceFirst(
        'bootstrap_cache_',
        '',
      );

      dev.log('ℹ️ [離線防禦] 成功攔截異常，改為載入歷史備份快取: $latestCacheKey');
      return await loadBootstrapCache(latestCacheKey);
    } catch (e) {
      dev.log('❌ [離線防禦失敗] 錯誤: $e');
      return null;
    }
  }

  // ==================== 2. 主流引擎數據映射轉換 (Mainstream Result) ====================
  Map<String, dynamic> _mainstreamToMap(MainstreamResult m) => {
    'category': m.category,
    'mainstreamScore': m.mainstreamScore,
    'flowScore': m.flowScore,
    'persistenceScore': m.persistenceScore,
    'diffusionScore': m.diffusionScore,
    'leaderScore': m.leaderScore,
    'strengthening': m.strengthening,
    'weakening': m.weakening,
  };

  MainstreamResult _mapToMainstream(Map<String, dynamic> map) =>
      MainstreamResult(
        category: map['category'] ?? '',
        mainstreamScore: (map['mainstreamScore'] ?? 0.0).toDouble(),
        flowScore: (map['flowScore'] ?? 0.0).toDouble(),
        persistenceScore: (map['persistenceScore'] ?? 0.0).toDouble(),
        diffusionScore: (map['diffusionScore'] ?? 0.0).toDouble(),
        leaderScore: (map['leaderScore'] ?? 0.0).toDouble(),
        strengthening: map['strengthening'] ?? false, // 修正點 2：嚴格對齊專案的 bool 類型
        weakening: map['weakening'] ?? false, // 修正點 2：嚴格對齊專案的 bool 類型
      );

  // ==================== 3. 生命週期引擎數據映射轉換 (Lifecycle Result) ====================
  Map<String, dynamic> _lifecycleToMap(LifecycleResult l) => {
    'category': l.category,
    'stage': l.stage.index, // 列舉儲存為 index 整數
    'strength': l.strength,
    'acceleration': l.acceleration,
    'persistence': l.persistence,
    'diffusion': l.diffusion,
    'hotMoneyIn': l.hotMoneyIn,
  };

  LifecycleResult _mapToLifecycle(Map<String, dynamic> map) => LifecycleResult(
    category: map['category'] ?? '',
    stage: LifecycleStage.values[map['stage'] ?? 0], // 整數還原為強型別列舉
    strength: (map['strength'] ?? 0.0).toDouble(),
    acceleration: (map['acceleration'] ?? 0.0).toDouble(),
    persistence: (map['persistence'] ?? 0.0).toDouble(),
    diffusion: (map['diffusion'] ?? 0.0).toDouble(),
    hotMoneyIn: map['hotMoneyIn'] ?? false,
  );

  // ==================== 基礎與其它輔助序列化函數 ====================
  Map<String, dynamic> _categoryToMap(CategoryUiModel model) => {
    'name': model.name,
    'totalCount': model.totalCount,
    'roseCount': model.riseCount,
    'fallCount': model.fallCount,
    'score': model.score,
    'day1Score': model.day1Score,
    'day2Score': model.day2Score,
    'day3Score': model.day3Score,
    'hotScore': model.hotScore,
    'persistence': model.persistence,
  };

  CategoryUiModel _mapToCategory(Map<String, dynamic> map) => CategoryUiModel(
    name: map['name'] ?? '',
    totalCount: map['totalCount'] ?? 0,
    riseCount: map['roseCount'] ?? 0,
    fallCount: map['fallCount'] ?? 0,
    score: (map['score'] ?? 0.0).toDouble(),
    day1Score: (map['day1Score'] ?? 0.0).toDouble(),
    day2Score: (map['day2Score'] ?? 0.0).toDouble(),
    day3Score: (map['day3Score'] ?? 0.0).toDouble(),
    hotScore: (map['hotScore'] ?? 0.0).toDouble(),
    persistence: (map['persistence'] ?? 0.0).toDouble(),
    children: const [],
    stocks: const [],
  );

  Map<String, dynamic> _sentimentToMap(MarketSentimentResult s) => {
    'score': s.score,
    'level': s.level.index,
    'riseCount': s.riseCount,
    'fallCount': s.fallCount,
    'strongCategoryCount': s.strongCategoryCount,
    'mainstreamAverage': s.mainstreamAverage,
    'hotMoneyStrength': s.hotMoneyStrength,
  };

  MarketSentimentResult _mapToSentiment(Map<String, dynamic> map) =>
      MarketSentimentResult(
        score: (map['score'] ?? 0.0).toDouble(),
        level: SentimentLevel.values[map['level'] ?? 0],
        riseCount: map['riseCount'] ?? 0,
        fallCount: map['fallCount'] ?? 0,
        strongCategoryCount: map['strongCategoryCount'] ?? 0,
        mainstreamAverage: (map['mainstreamAverage'] ?? 0.0).toDouble(),
        hotMoneyStrength: (map['hotMoneyStrength'] ?? 0.0).toDouble(),
      );
}

`

### lib\data\services\capital_flow_analyzer.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/domain/engines/capital_flow_engine.dart';

class CapitalFlowAnalyzer {
  final List<StockDaySnapshot> snapshots;

  CapitalFlowAnalyzer({required this.snapshots});

  List<CategoryUiModel> analyzeMainCategories({required MarketType market}) {
    if (snapshots.isEmpty) {
      return [];
    }

    final latest = snapshots[0];

    final latestStocks = latest.stocks
        .where((e) => e.market == market)
        .toList();

    final Map<String, List<StockData>> grouped = {};

    for (final stock in latestStocks) {
      grouped.putIfAbsent(stock.mainCategory, () => []);

      grouped[stock.mainCategory]!.add(stock);
    }

    final List<CategoryUiModel> result = [];

    for (final entry in grouped.entries) {
      final categoryName = entry.key;

      final categoryStocks = entry.value;

      final riseCount = categoryStocks.where((e) => e.changePercent > 0).length;

      final fallCount = categoryStocks.where((e) => e.changePercent < 0).length;

      final day1 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 0,
        mainCategory: true,
      );

      final day2 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 1,
        mainCategory: true,
      );

      final day3 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 2,
        mainCategory: true,
      );

      final subCategories = analyzeSubCategories(
        market: market,
        mainCategory: categoryName,
      );

      final trendStrength =
          ((day1 * 0.5) + (day2 * 0.3) + (day3 * 0.2)) +
          ((day1 - day2) + ((day2 - day3) * 0.5));

      result.add(
        CategoryUiModel(
          name: categoryName,

          totalCount: categoryStocks.length,

          riseCount: riseCount,

          fallCount: fallCount,

          score: day1,

          day1Score: day1,

          day2Score: day2,

          day3Score: day3,

          children: subCategories,

          hotScore: trendStrength,

          persistence: (day1 + day2 + day3) / 3,
        ),
      );
    }

    result.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    return result;
  }

  List<CategoryUiModel> analyzeSubCategories({
    required MarketType market,
    required String mainCategory,
  }) {
    if (snapshots.isEmpty) {
      return [];
    }

    final latest = snapshots[0];

    final latestStocks = latest.stocks
        .where((e) => e.market == market && e.mainCategory == mainCategory)
        .toList();

    final Map<String, List<StockData>> grouped = {};

    for (final stock in latestStocks) {
      grouped.putIfAbsent(stock.subCategory, () => []);

      grouped[stock.subCategory]!.add(stock);
    }

    final List<CategoryUiModel> result = [];

    for (final entry in grouped.entries) {
      final categoryName = entry.key;

      final categoryStocks = entry.value;

      final riseCount = categoryStocks.where((e) => e.changePercent > 0).length;

      final fallCount = categoryStocks.where((e) => e.changePercent < 0).length;

      final day1 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 0,
        mainCategory: false,
      );

      final day2 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 1,
        mainCategory: false,
      );

      final day3 = _calculateCategoryScore(
        categoryName: categoryName,
        market: market,
        dayOffset: 2,
        mainCategory: false,
      );

      final trendStrength =
          ((day1 * 0.5) + (day2 * 0.3) + (day3 * 0.2)) +
          ((day1 - day2) + ((day2 - day3) * 0.5));

      result.add(
        CategoryUiModel(
          name: categoryName,

          totalCount: categoryStocks.length,

          riseCount: riseCount,

          fallCount: fallCount,

          score: day1,

          day1Score: day1,

          day2Score: day2,

          day3Score: day3,

          stocks: categoryStocks
              .map(
                (e) => StockUiModel(stock: e, score: _calculateStockScore(e)),
              )
              .toList(),
          hotScore: trendStrength,

          persistence: (day1 + day2 + day3) / 3,
        ),
      );
    }

    result.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    return result;
  }

  double _calculateCategoryScore({
    required String categoryName,
    required MarketType market,
    required int dayOffset,
    required bool mainCategory,
  }) {
    if (dayOffset >= snapshots.length) {
      return 0;
    }

    final snapshot = snapshots[dayOffset];

    final stocks = snapshot.stocks.where((e) {
      final matchedCategory = mainCategory
          ? e.mainCategory == categoryName
          : e.subCategory == categoryName;

      return e.market == market && matchedCategory;
    }).toList();

    if (stocks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final stock in stocks) {
      total += _calculateStockScore(stock);
    }

    return total / stocks.length;
  }

  double _calculateStockScore(StockData stock) {
    final engine = CapitalFlowEngine(snapshots: snapshots);

    final signal = engine.analyze(stock);

    return signal.score;
  }

  double calculateMarketScore({required MarketType market}) {
    if (snapshots.isEmpty) {
      return 0;
    }

    final latest = snapshots[0];

    final stocks = latest.stocks.where((e) => e.market == market).toList();

    if (stocks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final stock in stocks) {
      total += _calculateStockScore(stock);
    }

    return total / stocks.length;
  }

  int calculateRiseCount({required MarketType market}) {
    if (snapshots.isEmpty) {
      return 0;
    }

    return snapshots[0].stocks
        .where((e) => e.market == market && e.changePercent > 0)
        .length;
  }

  int calculateFallCount({required MarketType market}) {
    if (snapshots.isEmpty) {
      return 0;
    }

    return snapshots[0].stocks
        .where((e) => e.market == market && e.changePercent < 0)
        .length;
  }
}

`

### lib\data\services\market_calendar_service.dart

`dart
class MarketCalendarService {
  bool isNewTradingDay({
    required String latestApiDate,
    required List<String> localDates,
  }) {
    return !localDates.contains(latestApiDate);
  }
}

`

### lib\data\services\stock_service.dart

`dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as dev; // 用於專業日誌
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

class StockService {
  static final Map<String, Map<String, String>> _mapping = {};
  static String lastDataDate = ""; // 新增：記錄最後一次抓取的日期

  static Future<void> loadMapping() async {
    try {
      final String content = await rootBundle.loadString(
        'assets/stock_mapping.txt',
      );
      final lines = content.split('\n');
      dev.log('開始解析本地對應表...', name: 'StockService');

      for (var line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          _mapping[parts[1]] = {
            'market': parts[0],
            'main': parts[2],
            'sub': parts[3],
          };
        }
      }
      dev.log('對應表解析完成，共載入 ${_mapping.length} 筆對應資料', name: 'StockService');
    } catch (e) {
      dev.log('解析對應表失敗: $e', name: 'StockService', error: e);
    }
  }

  static Future<List<StockData>> fetchListed() async {
    dev.log('抓取上市資料中...', name: 'StockService');
    try {
      final data = await _fetchJsonWithRetry(
        'https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL',
      );

      if (data.isEmpty) {
        return [];
      }

      if (data[0]['Date'] != null) {
        String rawDate = data[0]['Date'].toString();

        if (rawDate.length == 8) {
          int year = int.parse(rawDate.substring(0, 4));
          String monthDay = rawDate.substring(4);
          int rocYear = year - 1911;
          lastDataDate = "$rocYear$monthDay";
        } else {
          lastDataDate = rawDate;
        }
      }

      final filtered = data
          .where((item) {
            final String code = item['Code'] ?? '';
            return code.length == 4 && !code.startsWith('00');
          })
          .map((item) {
            final code = item['Code'];
            final map = _mapping[code];

            final close =
                double.tryParse(item['ClosingPrice']?.toString() ?? '') ?? 0;

            final change =
                double.tryParse(item['Change']?.toString() ?? '') ?? 0;

            final open =
                double.tryParse(item['OpeningPrice']?.toString() ?? '') ??
                close;

            final volume =
                int.tryParse(item['TradeVolume']?.toString() ?? '0') ?? 0;

            final value =
                int.tryParse(item['TradeValue']?.toString() ?? '0') ?? 0;

            return StockData(
              code: code,
              name: item['Name'],
              market: MarketType.listed,
              mainCategory: map?['main'] ?? '其他',
              subCategory: map?['sub'] ?? '其他',
              open: open,
              high:
                  double.tryParse(item['HighestPrice']?.toString() ?? '') ?? 0,
              low: double.tryParse(item['LowestPrice']?.toString() ?? '') ?? 0,
              close: close,
              change: change,
              changePercent: open != 0 ? (change / open) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上市資料處理完成，${StockService.lastDataDate}，共 ${filtered.length} 檔',
        name: 'StockService',
      );

      return filtered;
    } catch (e, stack) {
      dev.log(
        'fetchListed 發生例外',
        name: 'StockService',
        error: e,
        stackTrace: stack,
      );

      return [];
    }
  }

  static Future<List<StockData>> fetchOTC() async {
    dev.log('抓取上櫃資料中...', name: 'StockService');
    try {
      final data = await _fetchJsonWithRetry(
        'https://www.tpex.org.tw/openapi/v1/tpex_mainboard_daily_close_quotes',
      );

      if (data.isEmpty) {
        return [];
      }

      if (data[0]['Date'] != null) {
        String rawDate = data[0]['Date'].toString();

        if (rawDate.length == 8) {
          int year = int.parse(rawDate.substring(0, 4));
          String monthDay = rawDate.substring(4);
          int rocYear = year - 1911;
          lastDataDate = "$rocYear$monthDay";
        } else {
          lastDataDate = rawDate;
        }
      }

      final filtered = data
          .where((item) {
            final String code = item['SecuritiesCompanyCode']?.toString() ?? '';

            return code.length == 4 && !code.startsWith('00');
          })
          .map((item) {
            final code = item['SecuritiesCompanyCode'];
            final map = _mapping[code];

            final close = double.tryParse(item['Close']?.toString() ?? '') ?? 0;

            final change =
                double.tryParse(
                  item['Change']?.toString().replaceAll('+', '').trim() ?? '0',
                ) ??
                0;

            final open =
                double.tryParse(item['Open']?.toString() ?? '') ?? close;

            final volume =
                int.tryParse(item['TradingShares']?.toString().trim() ?? '0') ??
                0;

            final value =
                int.tryParse(
                  item['TransactionAmount']?.toString().trim() ?? '0',
                ) ??
                0;

            return StockData(
              code: code,
              name: item['CompanyName'],
              market: MarketType.otc,
              mainCategory: map?['main'] ?? '其他',
              subCategory: map?['sub'] ?? '其他',
              open: open,
              high: double.tryParse(item['High']?.toString() ?? '') ?? 0,
              low: double.tryParse(item['Low']?.toString() ?? '') ?? 0,
              close: close,
              change: change,
              changePercent: open != 0 ? (change / open) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上櫃資料處理完成，${StockService.lastDataDate}，共 ${filtered.length} 檔',
        name: 'StockService',
      );

      return filtered;
    } catch (e, stack) {
      dev.log(
        'fetchOTC 發生例外',
        name: 'StockService',
        error: e,
        stackTrace: stack,
      );

      return [];
    }
  }

  static Future<List<dynamic>> _fetchJsonWithRetry(
    String url, {
    int maxRetry = 3,
  }) async {
    final client = http.Client();

    try {
      for (int attempt = 1; attempt <= maxRetry; attempt++) {
        try {
          dev.log('開始請求 [$attempt/$maxRetry] $url', name: 'StockService');

          final request = http.Request('GET', Uri.parse(url));

          final streamedResponse = await client.send(request);

          if (streamedResponse.statusCode == 200) {
            final responseBody = await streamedResponse.stream.bytesToString();

            final decoded = json.decode(responseBody);

            if (decoded is List<dynamic>) {
              dev.log('請求成功，共 ${decoded.length} 筆', name: 'StockService');
              return decoded;
            }

            dev.log('資料格式異常，不是 List', name: 'StockService');

            return [];
          }

          dev.log(
            'HTTP Error: ${streamedResponse.statusCode}',
            name: 'StockService',
          );
        } catch (e, stack) {
          dev.log(
            '第 $attempt 次請求失敗',
            name: 'StockService',
            error: e,
            stackTrace: stack,
          );
        }

        if (attempt < maxRetry) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }

      dev.log('重試 $maxRetry 次後仍失敗：$url', name: 'StockService');

      return [];
    } finally {
      client.close();
    }
  }
}

`

### lib\data\services\storage_service.dart

`dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:tw_stock_capital_flow/core/constants/app_constants.dart';
import 'package:tw_stock_capital_flow/core/utils/date_utils.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<Directory> _getDailyDirectory() async {
    final root = await getApplicationDocumentsDirectory();

    final dailyPath = path.join(root.path, AppConstants.dailyFolder);

    final dir = Directory(dailyPath);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  Future<String> _buildFilePath(String date) async {
    final dir = await _getDailyDirectory();

    return path.join(dir.path, '$date.json');
  }

  Future<bool> exists(String date) async {
    final filePath = await _buildFilePath(date);

    return File(filePath).exists();
  }

  Future<void> saveDailySnapshot(StockDaySnapshot snapshot) async {
    final alreadyExists = await exists(snapshot.date);
    dev.log('日期: ${snapshot.date}，檔案是否存在: $alreadyExists');
    if (alreadyExists) {
      return;
    }

    final filePath = await _buildFilePath(snapshot.date);
    dev.log('日期: ${snapshot.date}，建構檔案路徑: $filePath');

    final file = File(filePath);

    final jsonString = jsonEncode(snapshot.toJson());

    await file.writeAsString(jsonString);
  }

  Future<StockDaySnapshot?> loadSnapshot(String date) async {
    final filePath = await _buildFilePath(date);

    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();

    final jsonData = jsonDecode(content);

    return StockDaySnapshot.fromJson(jsonData);
  }

  /// 取得本地最新可用的交易日期（按日期由新到舊排序）
  Future<String?> getLatestAvailableDate() async {
    try {
      final dates = await listAvailableDates();

      if (dates.isEmpty) {
        return null;
      }

      // 確保日期是字串格式 YYYYMMDD，先排序再取最新
      dates.sort((a, b) => b.compareTo(a)); // 降序：最新的在前面

      return dates.first;
    } catch (e) {
      dev.log('取得最新可用日期失敗: $e', name: 'StorageService', error: e);
      return null;
    }
  }

  Future<List<String>> listAvailableDates() async {
    final dir = await _getDailyDirectory();

    final files = dir.listSync();

    final dates = files
        .whereType<File>()
        .map((e) => path.basenameWithoutExtension(e.path))
        .toList();

    return AppDateUtils.sortDesc(dates);
  }

  Future<String> buildCustomFilePath(String filename) async {
    final dir = await _getDailyDirectory();

    return path.join(dir.path, filename);
  }

  Future<void> writeFile(String filename, String content) async {
    final filePath = await buildCustomFilePath(filename);

    final file = File(filePath);

    await file.writeAsString(content);
  }

  Future<String?> readFile(String filename) async {
    final filePath = await buildCustomFilePath(filename);

    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    return await file.readAsString();
  }

  Future<void> writeJson(String filename, Map<String, dynamic> json) async {
    await writeFile(filename, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> readJson(String filename) async {
    final content = await readFile(filename);

    if (content == null) {
      return null;
    }

    return jsonDecode(content);
  }

  /// 🚀 獲取目前本地儲存的所有快取 Key
  Future<List<String>> getAllKeys() async {
    try {
      // 1. 在方法內部直接獲取原生實體，100% 免疫欄位未定義錯誤
      final SharedPreferences prefsInstance =
          await SharedPreferences.getInstance();

      // 2. 呼叫原生 getKeys() 並轉為 List 丢出
      return prefsInstance.getKeys().toList();
    } catch (e) {
      dev.log('❌ [StorageService] 獲取全部 Keys 失敗: $e');
      return [];
    }
  }
}

`

### lib\domain\analysers\rotation_leading_analyser.dart

`dart
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/domain/models/leading_indicator_result.dart';

class RotationLeadingAnalyser {
  /// 🚀 核心計算方法：將滯後的輪動路徑，轉化為產業領先動能指標
  List<LeadingIndicatorResult> calculateLeadingIndicators(
    List<RotationResult> rotations,
  ) {
    if (rotations.isEmpty) return [];

    // Map 結構：Category -> _RotationMetrics
    final Map<String, _RotationMetrics> registry = {};

    // 1. 遍歷所有輪動軌跡，統計每個產業的「流入」與「流出」加總
    for (var r in rotations) {
      final fromCat = r.fromCategory;
      final toCat = r.toCategory;
      final score = r.score;

      // 累加 From 產業 (資金抽離)
      registry.putIfAbsent(fromCat, () => _RotationMetrics(name: fromCat));
      registry[fromCat]!.outflowSum += score;

      // 累加 To 產業 (資金灌入)
      registry.putIfAbsent(toCat, () => _RotationMetrics(name: toCat));
      registry[toCat]!.inflowSum += score;
      registry[toCat]!.feederCount += 1;
    }

    // 2. 根據淨動能 (RNM) 計算領先訊號與白話指南
    List<LeadingIndicatorResult> results = [];

    registry.forEach((category, metrics) {
      final double rnm = metrics.inflowSum - metrics.outflowSum;
      LeadingSignalType signal = LeadingSignalType.neutral;
      String guidance = "⚪ 市場資金對該板塊無明顯搬移傾向，暫時以區間盤整視之。";

      // 訊號量化評級模型
      if (rnm >= 45.0 && metrics.feederCount >= 2) {
        signal = LeadingSignalType.strongAccumulation;
        guidance =
            "🟢【核心提示：主力暗中吸籌】全市場有高達 ${metrics.feederCount} 個產業的資金正在集體『化整為零』秘密灌入此板塊。目前股價可能尚未大漲，是極具勝率的領先埋伏進場點！";
      } else if (rnm > 15.0) {
        signal = LeadingSignalType.mildInflow;
        guidance = "🍏【資金穩步潛伏】輪動淨動能為正，多方大資金正在溫和流入，可加入自選股關注突破時機。";
      } else if (rnm <= -45.0) {
        signal = LeadingSignalType.strongDrain;
        guidance =
            "🔴【危險提示：大資金出逃】此板塊正成為全台股的『提款機』，資金正不計成本被抽出搬往其他新主力產業。股價極易面臨無量陰跌，請領先清倉或反向做空。";
      } else if (rnm < -15.0) {
        signal = LeadingSignalType.distributionRisk;
        guidance = "🟠【高檔派發風險】資金淨流出。主力在高檔逐步將籌碼派發給散戶，短期防禦型交易者應適度調調節減碼。";
      }

      results.add(
        LeadingIndicatorResult(
          category: category,
          netRotationScore: rnm,
          totalInflowScore: metrics.inflowSum,
          totalOutflowScore: metrics.outflowSum,
          inflowFeederCount: metrics.feederCount,
          signal: signal,
          textGuidance: guidance,
        ),
      );
    });

    // 3. 排序：將淨動能最高的（最吸金、最領先）排在最前面
    results.sort((a, b) => b.netRotationScore.compareTo(a.netRotationScore));
    return results;
  }
}

/// 內部計算輔助類
class _RotationMetrics {
  final String name;
  double inflowSum = 0.0;
  double outflowSum = 0.0;
  int feederCount = 0;
  _RotationMetrics({required this.name});
}

`

### lib\domain\engines\abnormal_money_engine.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/domain/models/abnormal_money_result.dart';

class AbnormalMoneyEngine {
  final List<StockDaySnapshot> snapshots;

  const AbnormalMoneyEngine({required this.snapshots});

  List<AbnormalMoneyResult> analyze() {
    if (snapshots.length < 3) {
      return [];
    }

    final latest = snapshots[0];

    final prev1 = snapshots[1];

    final prev2 = snapshots[2];

    final List<AbnormalMoneyResult> results = [];

    for (final stock in latest.stocks) {
      final old1 = _findStock(prev1, stock.code);

      final old2 = _findStock(prev2, stock.code);

      if (old1 == null || old2 == null) {
        continue;
      }

      final avgVolume = (old1.volume + old2.volume) / 2;

      final avgValue = (old1.value + old2.value) / 2;

      if (avgVolume <= 0 || avgValue <= 0) {
        continue;
      }

      final volumeRatio = stock.volume / avgVolume;

      final valueRatio = stock.value / avgValue;

      final momentumScore = stock.changePercent;

      final continuous =
          stock.changePercent > 0 &&
          old1.changePercent > 0 &&
          old2.changePercent > 0;

      final breakout = volumeRatio > 2 && momentumScore > 3;

      final moneyScore =
          (volumeRatio * 35) +
          (valueRatio * 35) +
          (momentumScore * 20) +
          (continuous ? 10 : 0);

      if (moneyScore < 80) {
        continue;
      }

      results.add(
        AbnormalMoneyResult(
          stock: stock,

          moneyScore: moneyScore,

          volumeRatio: volumeRatio,

          valueRatio: valueRatio,

          momentumScore: momentumScore,

          continuous: continuous,

          breakout: breakout,
        ),
      );
    }

    results.sort((a, b) => b.moneyScore.compareTo(a.moneyScore));

    return results;
  }

  StockData? _findStock(StockDaySnapshot snapshot, String code) {
    try {
      return snapshot.stocks.firstWhere((e) => e.code == code);
    } catch (_) {
      return null;
    }
  }
}

`

### lib\domain\engines\capital_flow_engine.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/core/extensions/list_extension.dart';
import 'package:tw_stock_capital_flow/data/models/flow_signal.dart';

class CapitalFlowEngine {
  final List<StockDaySnapshot> snapshots;

  const CapitalFlowEngine({required this.snapshots});

  FlowSignal analyze(StockData stock) {
    final histories = _findStockHistory(stock.code);

    if (histories.isEmpty) {
      return const FlowSignal(
        score: 0,
        volumeRatio: 0,
        momentumScore: 0,
        persistenceScore: 0,
        direction: FlowDirection.neutral,
      );
    }

    final today = histories.first;

    final avgValue = histories
        .map((e) => e.value.toDouble())
        .toList()
        .average();

    final double volumeRatio = avgValue == 0 ? 0 : today.value / avgValue;

    final priceMomentum = today.changePercent;

    final volatility =
        ((today.high - today.low) / (today.close == 0 ? 1 : today.close)) * 100;

    final momentumScore = (priceMomentum * 0.7) + (volatility * 0.3);

    final persistenceScore = _calculatePersistence(histories);

    final flowScore =
        (volumeRatio * 0.35) +
        (momentumScore * 0.40) +
        (persistenceScore * 0.25);

    final direction = flowScore > 1
        ? FlowDirection.inflow
        : flowScore < -1
        ? FlowDirection.outflow
        : FlowDirection.neutral;

    return FlowSignal(
      score: flowScore,

      volumeRatio: volumeRatio,

      momentumScore: momentumScore,

      persistenceScore: persistenceScore,

      direction: direction,
    );
  }

  List<StockData> _findStockHistory(String code) {
    final List<StockData> result = [];

    for (final snapshot in snapshots) {
      try {
        final stock = snapshot.stocks.firstWhere((e) => e.code == code);

        result.add(stock);
      } catch (_) {}
    }

    return result;
  }

  double _calculatePersistence(List<StockData> histories) {
    if (histories.length <= 1) {
      return 0;
    }

    int positiveDays = 0;

    for (final stock in histories) {
      if (stock.changePercent > 0) {
        positiveDays++;
      }
    }

    final persistence = positiveDays / histories.length;

    final latest = histories.first.changePercent;

    return latest * persistence;
  }
}

`

### lib\domain\engines\lifecycle_engine.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_timeline.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/trend_metrics.dart';
import 'package:tw_stock_capital_flow/domain/engines/trend_metrics_engine.dart';

class LifecycleEngine {
  final List<StockDaySnapshot> snapshots;

  final List<MainstreamResult> mainstreams;

  const LifecycleEngine({required this.snapshots, required this.mainstreams});

  List<LifecycleResult> analyze() {
    if (snapshots.isEmpty) {
      return [];
    }

    final trendEngine = TrendMetricsEngine();

    final List<LifecycleResult> results = [];

    for (final mainstream in mainstreams) {
      final timeline = _buildTimeline(mainstream.category);

      final scoreTrend = trendEngine.analyze(timeline.scores);

      final flowTrend = trendEngine.analyze(timeline.flows);

      final diffusionTrend = trendEngine.analyze(timeline.diffusions);

      final stage = _resolveStage(
        mainstream: mainstream,

        scoreTrend: scoreTrend,

        flowTrend: flowTrend,

        diffusionTrend: diffusionTrend,
      );

      final acceleration = scoreTrend.acceleration;

      final hotMoneyIn = flowTrend.acceleration > 0 && diffusionTrend.slope > 0;

      results.add(
        LifecycleResult(
          category: mainstream.category,

          stage: stage,

          strength: mainstream.mainstreamScore,

          acceleration: acceleration,

          persistence: mainstream.persistenceScore,

          diffusion: mainstream.diffusionScore,

          hotMoneyIn: hotMoneyIn,
        ),
      );
    }

    results.sort((a, b) => b.strength.compareTo(a.strength));

    return results;
  }

  LifecycleTimeline _buildTimeline(String category) {
    final List<double> scores = [];

    final List<double> flows = [];

    final List<double> diffusions = [];

    for (final snapshot in snapshots.reversed) {
      final categoryStocks = snapshot.stocks
          .where((e) => e.mainCategory == category)
          .toList();

      if (categoryStocks.isEmpty) {
        continue;
      }

      double score = 0;

      double flow = 0;

      int riseCount = 0;

      for (final stock in categoryStocks) {
        final valueScore = stock.value / 100000000;

        score += stock.changePercent * valueScore;

        flow += valueScore;

        if (stock.changePercent > 0) {
          riseCount++;
        }
      }

      score /= categoryStocks.length;

      flow /= categoryStocks.length;

      final diffusion = riseCount / categoryStocks.length * 100;

      scores.add(score);

      flows.add(flow);

      diffusions.add(diffusion);
    }

    return LifecycleTimeline(
      category: category,

      scores: scores,

      flows: flows,

      diffusions: diffusions,
    );
  }

  LifecycleStage _resolveStage({
    required MainstreamResult mainstream,

    required TrendMetrics scoreTrend,

    required TrendMetrics flowTrend,

    required TrendMetrics diffusionTrend,
  }) {
    final score = mainstream.mainstreamScore;

    final slope = scoreTrend.slope;

    final acceleration = scoreTrend.acceleration;

    final stability = scoreTrend.stability;

    final volatility = scoreTrend.volatility;

    final diffusion = mainstream.diffusionScore;

    final flow = mainstream.flowScore;

    // 死亡
    if (score < 10 && slope < 0 && flow < 0) {
      return LifecycleStage.dead;
    }

    // 退潮
    if (slope < 0 && acceleration < 0 && flow < 0) {
      return LifecycleStage.decline;
    }

    // 出貨
    if (score > 70 && acceleration < 0 && volatility > 15) {
      return LifecycleStage.distribution;
    }

    // 狂熱
    if (score > 85 && diffusion > 75 && volatility > 20) {
      return LifecycleStage.euphoric;
    }

    // 主升
    if (score > 60 && slope > 20 && stability > 70 && volatility < 18) {
      return LifecycleStage.markup;
    }

    // 擴散
    if (diffusion > 45 && slope > 10 && flowTrend.slope > 0) {
      return LifecycleStage.expansion;
    }

    // 點火
    if (acceleration > 5 || flowTrend.acceleration > 0) {
      return LifecycleStage.ignition;
    }

    return LifecycleStage.ignition;
  }
}

`

### lib\domain\engines\mainstream_engine.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';

class MainstreamEngine {
  final List<StockDaySnapshot> snapshots;

  const MainstreamEngine({required this.snapshots});

  List<MainstreamResult> analyze() {
    if (snapshots.isEmpty) {
      return [];
    }

    final latest = snapshots.first;

    final Map<String, List<StockData>> grouped = {};

    for (final stock in latest.stocks) {
      grouped.putIfAbsent(stock.mainCategory, () => []);

      grouped[stock.mainCategory]!.add(stock);
    }

    final List<MainstreamResult> results = [];

    for (final entry in grouped.entries) {
      final category = entry.key;

      final stocks = entry.value;

      final flowScore = _calculateFlowScore(stocks);

      final persistenceScore = _calculatePersistence(category);

      final diffusionScore = _calculateDiffusion(stocks);

      final leaderScore = _calculateLeaderScore(stocks);

      final mainstreamScore =
          (flowScore * 0.35) +
          (persistenceScore * 0.30) +
          (diffusionScore * 0.20) +
          (leaderScore * 0.15);

      final strengthening = persistenceScore > 0 && flowScore > 0;

      final weakening = persistenceScore < 0 && flowScore < 0;

      results.add(
        MainstreamResult(
          category: category,

          mainstreamScore: mainstreamScore,

          flowScore: flowScore,

          persistenceScore: persistenceScore,

          diffusionScore: diffusionScore,

          leaderScore: leaderScore,

          strengthening: strengthening,

          weakening: weakening,
        ),
      );
    }

    results.sort((a, b) => b.mainstreamScore.compareTo(a.mainstreamScore));

    return results;
  }

  double _calculateFlowScore(List<StockData> stocks) {
    if (stocks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final stock in stocks) {
      final score = stock.changePercent * (stock.value / 100000000);

      total += score;
    }

    return total / stocks.length;
  }

  double _calculatePersistence(String category) {
    if (snapshots.length < 3) {
      return 0;
    }

    final List<double> scores = [];

    for (final snapshot in snapshots.take(3)) {
      final stocks = snapshot.stocks
          .where((e) => e.mainCategory == category)
          .toList();

      if (stocks.isEmpty) {
        continue;
      }

      double score = 0;

      for (final stock in stocks) {
        score += stock.changePercent * (stock.value / 100000000);
      }

      scores.add(score / stocks.length);
    }

    if (scores.length < 3) {
      return 0;
    }

    return (scores[0] * 0.5) + (scores[1] * 0.3) + (scores[2] * 0.2);
  }

  double _calculateDiffusion(List<StockData> stocks) {
    if (stocks.isEmpty) {
      return 0;
    }

    final rising = stocks.where((e) => e.changePercent > 0).length;

    return rising / stocks.length * 100;
  }

  double _calculateLeaderScore(List<StockData> stocks) {
    if (stocks.isEmpty) {
      return 0;
    }

    stocks.sort((a, b) => b.value.compareTo(a.value));

    final leader = stocks.first;

    final valueScore = leader.value / 100000000;

    final momentumScore = leader.changePercent;

    return (valueScore * 0.6) + (momentumScore * 0.4);
  }
}

`

### lib\domain\engines\market_sentiment_engine.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';

import 'package:tw_stock_capital_flow/domain/enums/sentiment_level.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';

class MarketSentimentEngine {
  final List<StockDaySnapshot> snapshots;

  final List<MainstreamResult> mainstreams;

  const MarketSentimentEngine({
    required this.snapshots,
    required this.mainstreams,
  });

  MarketSentimentResult analyze() {
    if (snapshots.isEmpty) {
      return const MarketSentimentResult(
        score: 0,
        level: SentimentLevel.neutral,
        riseCount: 0,
        fallCount: 0,
        strongCategoryCount: 0,
        mainstreamAverage: 0,
        hotMoneyStrength: 0,
      );
    }

    final latest = snapshots.first;

    final riseCount = latest.stocks.where((e) => e.changePercent > 0).length;

    final fallCount = latest.stocks.where((e) => e.changePercent < 0).length;

    final riseRatio = latest.stocks.isEmpty
        ? 0
        : riseCount / latest.stocks.length;

    final strongCategoryCount = mainstreams
        .where((e) => e.mainstreamScore > 30)
        .length;

    double mainstreamAverage = 0;

    if (mainstreams.isNotEmpty) {
      mainstreamAverage =
          mainstreams.map((e) => e.mainstreamScore).reduce((a, b) => a + b) /
          mainstreams.length;
    }

    final hotMoneyStrength = _calculateHotMoney(latest);

    final score =
        (riseRatio * 30) +
        (strongCategoryCount * 8) +
        (mainstreamAverage * 0.35) +
        (hotMoneyStrength * 0.25);

    final level = _resolveLevel(score);

    return MarketSentimentResult(
      score: score,

      level: level,

      riseCount: riseCount,

      fallCount: fallCount,

      strongCategoryCount: strongCategoryCount,

      mainstreamAverage: mainstreamAverage,

      hotMoneyStrength: hotMoneyStrength,
    );
  }

  double _calculateHotMoney(StockDaySnapshot snapshot) {
    double total = 0;

    for (final stock in snapshot.stocks) {
      final valueScore = stock.value / 100000000;

      final momentum = stock.changePercent;

      total += valueScore * momentum;
    }

    return total / snapshot.stocks.length;
  }

  SentimentLevel _resolveLevel(double score) {
    if (score >= 85) {
      return SentimentLevel.euphoric;
    }

    if (score >= 65) {
      return SentimentLevel.optimistic;
    }

    if (score >= 40) {
      return SentimentLevel.neutral;
    }

    if (score >= 20) {
      return SentimentLevel.weak;
    }

    return SentimentLevel.panic;
  }
}

`

### lib\domain\engines\rotation_engine.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/core/extensions/list_extension.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';

class RotationEngine {
  final List<StockDaySnapshot> snapshots;

  const RotationEngine({required this.snapshots});

  List<RotationResult> analyze() {
    if (snapshots.length < 2) {
      return [];
    }

    final today = snapshots[0];

    final yesterday = snapshots[1];

    final todayScores = _calculateCategoryScores(today);

    final yesterdayScores = _calculateCategoryScores(yesterday);

    final List<MapEntry<String, double>> increases = [];

    final List<MapEntry<String, double>> decreases = [];

    for (final entry in todayScores.entries) {
      final yesterdayScore = yesterdayScores[entry.key] ?? 0;

      final diff = entry.value - yesterdayScore;

      if (diff > 0) {
        increases.add(MapEntry(entry.key, diff));
      } else {
        decreases.add(MapEntry(entry.key, diff.abs()));
      }
    }

    increases.sort((a, b) => b.value.compareTo(a.value));

    decreases.sort((a, b) => b.value.compareTo(a.value));

    final List<RotationResult> result = [];

    final length = increases.length < decreases.length
        ? increases.length
        : decreases.length;

    for (int i = 0; i < length; i++) {
      final fromValue = decreases[i].value.abs();

      final toValue = increases[i].value.abs();

      final rotationScore = (fromValue + toValue) / 2;

      result.add(
        RotationResult(
          fromCategory: decreases[i].key,

          toCategory: increases[i].key,

          score: rotationScore,

          inflowStrength: increases[i].value,
        ),
      );
    }

    return result;
  }

  Map<String, double> _calculateCategoryScores(StockDaySnapshot snapshot) {
    final Map<String, List<double>> grouped = {};

    for (final stock in snapshot.stocks) {
      grouped.putIfAbsent(stock.mainCategory, () => []);

      final score = stock.changePercent * (stock.value / 100000000);

      grouped[stock.mainCategory]!.add(score);
    }

    final Map<String, double> result = {};

    for (final entry in grouped.entries) {
      result[entry.key] = entry.value.average();
    }

    return result;
  }
}

`

### lib\domain\engines\trend_metrics_engine.dart

`dart
import 'package:tw_stock_capital_flow/domain/models/trend_metrics.dart';

class TrendMetricsEngine {
  const TrendMetricsEngine();

  TrendMetrics analyze(List<double> values) {
    if (values.length < 2) {
      return const TrendMetrics(
        slope: 0,
        acceleration: 0,
        stability: 0,
        volatility: 0,
      );
    }

    final first = values.first;

    final last = values.last;

    final slope = last - first;

    double acceleration = 0;

    if (values.length >= 3) {
      final mid = values[values.length ~/ 2];

      acceleration = (last - mid) - (mid - first);
    }

    double volatility = 0;

    final avg = values.reduce((a, b) => a + b) / values.length;

    for (final value in values) {
      volatility += (value - avg).abs();
    }

    volatility /= values.length;

    final stability = 100 - volatility;

    return TrendMetrics(
      slope: slope,

      acceleration: acceleration,

      stability: stability,

      volatility: volatility,
    );
  }
}

`

### lib\domain\enums\lifecycle_stage.dart

`dart
enum LifecycleStage {
  ignition, // 點火
  expansion, // 擴散
  markup, // 主升
  euphoric, // 狂熱
  distribution, // 出貨
  decline, // 退潮
  dead, // 死亡
}

`

### lib\domain\enums\sentiment_level.dart

`dart
enum SentimentLevel { panic, weak, neutral, optimistic, euphoric }

`

### lib\domain\models\abnormal_money_result.dart

`dart
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

`

### lib\domain\models\leading_indicator_result.dart

`dart
enum LeadingSignalType {
  strongAccumulation, // 🟢 強烈暗中吸籌（黃金領先買進點）
  mildInflow, // 🍏 資金穩步潛伏
  neutral, // ⚪ 資金平穩
  distributionRisk, // 🟠 高檔派發風險（領先減碼點）
  strongDrain, // 🔴 強烈失血出逃（領先逃命點）
}

class LeadingIndicatorResult {
  final String category;
  final double netRotationScore; // 輪動淨動能 (RNM = Inflow - Outflow)
  final double totalInflowScore; // 總灌入強度
  final double totalOutflowScore; // 總抽離強度
  final int inflowFeederCount; // 有多少個板塊把錢輸血給它
  final LeadingSignalType signal; // 領先訊號型別
  final String textGuidance; // 交易者白話指南

  LeadingIndicatorResult({
    required this.category,
    required this.netRotationScore,
    required this.totalInflowScore,
    required this.totalOutflowScore,
    required this.inflowFeederCount,
    required this.signal,
    required this.textGuidance,
  });
}

`

### lib\domain\models\lifecycle_result.dart

`dart
import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';

class LifecycleResult {
  final String category;

  final LifecycleStage stage;

  final double strength;

  final double acceleration;

  final double persistence;

  final double diffusion;

  final bool hotMoneyIn;

  const LifecycleResult({
    required this.category,
    required this.stage,
    required this.strength,
    required this.acceleration,
    required this.persistence,
    required this.diffusion,
    required this.hotMoneyIn,
  });
}

`

### lib\domain\models\lifecycle_timeline.dart

`dart
class LifecycleTimeline {
  final String category;

  final List<double> scores;

  final List<double> flows;

  final List<double> diffusions;

  const LifecycleTimeline({
    required this.category,
    required this.scores,
    required this.flows,
    required this.diffusions,
  });
}

`

### lib\domain\models\mainstream_result.dart

`dart
class MainstreamResult {
  final String category;

  final double mainstreamScore;

  final double flowScore;

  final double persistenceScore;

  final double diffusionScore;

  final double leaderScore;

  final bool strengthening;

  final bool weakening;

  const MainstreamResult({
    required this.category,
    required this.mainstreamScore,
    required this.flowScore,
    required this.persistenceScore,
    required this.diffusionScore,
    required this.leaderScore,
    required this.strengthening,
    required this.weakening,
  });
}

`

### lib\domain\models\market_sentiment_result.dart

`dart
import 'package:tw_stock_capital_flow/domain/enums/sentiment_level.dart';

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

`

### lib\domain\models\strategy_signal.dart

`dart
// import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';

/// 策略建議之行動型別
enum StrategyAction {
  buy, // 🟢 買進 / 進場
  hold, // 🟡 續抱 / 加碼
  sell, // 🔴 賣出 / 出清
  neutral, // ⚪ 觀望 / 無訊號
}

/// 單一板塊當前觸發的策略訊號
class StrategySignal {
  final String category;
  final StrategyAction action;
  final double score;
  final double trendStrength;
  final double persistence;
  final String reason;
  final String dateKey;

  StrategySignal({
    required this.category,
    required this.action,
    required this.score,
    required this.trendStrength,
    required this.persistence,
    required this.reason,
    required this.dateKey,
  });
}

/// 策略回測統計效能結果
class BacktestSummary {
  final String strategyName;
  final double totalReturn; // 總報酬率 (例如 0.25 代表 25%)
  final double winRate; // 勝率 (0.0 ~ 1.0)
  final int totalTrades; // 總交易次數
  final double maxDrawdown; // 最大回撤 (MDD)
  final List<StrategySignal> signalHistory;

  BacktestSummary({
    required this.strategyName,
    required this.totalReturn,
    required this.winRate,
    required this.totalTrades,
    required this.maxDrawdown,
    required this.signalHistory,
  });
}

`

### lib\domain\models\trend_metrics.dart

`dart
class TrendMetrics {
  final double slope;

  final double acceleration;

  final double stability;

  final double volatility;

  const TrendMetrics({
    required this.slope,
    required this.acceleration,
    required this.stability,
    required this.volatility,
  });
}

`

### lib\domain\strategies\momentum_strategy.dart

`dart
import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart'; // 確保路徑對齊
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';

class MomentumStrategy {
  final String name = "板塊七期動量續航策略";

  /// 🚀 核心演算法：精確對齊 LifecycleResult 的所有欄位進行判定
  StrategySignal evaluate(LifecycleResult result, {required String dateKey}) {
    final String category = result.category;
    final LifecycleStage stage = result.stage;
    final double strength = result.strength;
    final double accel = result.acceleration;
    final double persist = result.persistence;
    final double diff = result.diffusion;
    final bool hasHotMoney = result.hotMoneyIn;

    // ==================== 🟢 1. 買進與加碼訊號 (Buy) ====================

    // 點火階段：熱錢剛流入且具備基礎加速度，小資金建立底倉
    if (stage == LifecycleStage.ignition && hasHotMoney && accel > 0) {
      return StrategySignal(
        category: category,
        action: StrategyAction.buy,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason:
            "🟢【點火期・初試啼聲】熱錢實質流入，且動能具備正加速度(+${accel.toStringAsFixed(1)})，建議建立基本試單倉。",
        dateKey: dateKey,
      );
    }

    // 擴散或主升階段：熱錢在，且板塊擴散度高 (共振強)，最強主升段加碼點
    if ((stage == LifecycleStage.expansion || stage == LifecycleStage.markup) &&
        hasHotMoney &&
        diff >= 50.0) {
      return StrategySignal(
        category: category,
        action: StrategyAction.buy,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason:
            "🟢🟢【主升擴張・全面加碼】熱錢持續駐留且板塊內部個股擴散度高達 ${diff.toStringAsFixed(0)}%，屬於結構極健康的共振噴出段，建議積極加碼。",
        dateKey: dateKey,
      );
    }

    // ==================== 🟡 2. 持股續抱與警告訊號 (Hold) ====================

    // 主升或狂熱期：只要熱錢沒走，且延續力還在，就抱緊讓利潤奔跑，但狂熱期禁止追高
    if (hasHotMoney && persist >= 50.0) {
      if (stage == LifecycleStage.euphoric) {
        return StrategySignal(
          category: category,
          action: StrategyAction.hold,
          score: strength,
          trendStrength: strength,
          persistence: persist,
          reason: "🟠【狂熱期・禁止追高】雖然熱錢仍在，但市場情緒已達集體過熱期。持股可續抱，但此處絕對禁止新資金追加追高。",
          dateKey: dateKey,
        );
      }
      return StrategySignal(
        category: category,
        action: StrategyAction.hold,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason: "自由抱牢。延續力達 ${persist.toStringAsFixed(0)}，主力鎖籌穩固，持股續抱。",
        dateKey: dateKey,
      );
    }

    // ==================== 🔴 3. 賣出與出清訊號 (Sell) ====================

    // 出貨期、退潮期、死亡期，或者「熱錢一撤走」或「延續力極度渙散(<40)」，觸發無條件出清風控
    if (stage == LifecycleStage.distribution ||
        stage == LifecycleStage.decline ||
        stage == LifecycleStage.dead ||
        !hasHotMoney ||
        persist < 40.0) {
      String reason = "🔴【風控警示・出清退場】";
      if (stage == LifecycleStage.distribution) reason += "進入出貨期，主力高檔悄悄派發。";
      if (stage == LifecycleStage.decline) reason += "進入退潮期，多殺多開始。";
      if (!hasHotMoney) reason += "最關鍵的熱錢（HotMoney）已撤離，失去資金支撐。";
      if (persist < 40.0) reason += "延續力低於40，盤中開高走低、長上影線拋壓嚴重。";

      return StrategySignal(
        category: category,
        action: StrategyAction.sell,
        score: strength,
        trendStrength: strength,
        persistence: persist,
        reason: reason,
        dateKey: dateKey,
      );
    }

    // ⚪ 4. 中性混沌觀望
    return StrategySignal(
      category: category,
      action: StrategyAction.neutral,
      score: strength,
      trendStrength: strength,
      persistence: persist,
      reason: "⚪【混沌盤整】各項指標處於混沌拉鋸區，無明確方向，建議先觀望。",
      dateKey: dateKey,
    );
  }
}

`

### lib\domain\usecases\app_bootstrap_result.dart

`dart
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

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

`

### lib\domain\usecases\app_bootstrapper.dart

`dart
import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';
import 'package:tw_stock_capital_flow/domain/engines/lifecycle_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/mainstream_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/market_sentiment_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/rotation_engine.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/repositories/history_repository.dart';
import 'package:tw_stock_capital_flow/data/services/capital_flow_analyzer.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';

class AppBootstrapper {
  static Future<AppBootstrapResult> bootstrap() async {
    final storageService = StorageService();

    final historyRepository = HistoryRepository(storageService: storageService);

    final snapshots = await historyRepository.loadRecentSnapshots(5);

    if (snapshots.isEmpty) {
      throw Exception('無歷史資料');
    }

    final analyzer = CapitalFlowAnalyzer(snapshots: snapshots);

    final listedCategories = analyzer.analyzeMainCategories(
      market: MarketType.listed,
    );

    final otcCategories = analyzer.analyzeMainCategories(
      market: MarketType.otc,
    );

    final mainstreams = MainstreamEngine(snapshots: snapshots).analyze();

    final lifecycles = LifecycleEngine(
      snapshots: snapshots,
      mainstreams: mainstreams,
    ).analyze();

    final rotations = RotationEngine(snapshots: snapshots).analyze();

    final sentiment = MarketSentimentEngine(
      snapshots: snapshots,
      mainstreams: mainstreams,
    ).analyze();

    return AppBootstrapResult(
      listedCategories: listedCategories,

      otcCategories: otcCategories,

      listedRiseCount: analyzer.calculateRiseCount(market: MarketType.listed),

      listedFallCount: analyzer.calculateFallCount(market: MarketType.listed),

      otcRiseCount: analyzer.calculateRiseCount(market: MarketType.otc),

      otcFallCount: analyzer.calculateFallCount(market: MarketType.otc),

      listedScore: analyzer.calculateMarketScore(market: MarketType.listed),

      otcScore: analyzer.calculateMarketScore(market: MarketType.otc),

      mainstreams: mainstreams,

      lifecycles: lifecycles,

      rotations: rotations,

      sentiment: sentiment,
    );
  }
}

`

### lib\domain\usecases\bootstrap_analyzer.dart

`dart
import 'package:tw_stock_capital_flow/domain/engines/lifecycle_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/mainstream_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/market_sentiment_engine.dart';
import 'package:tw_stock_capital_flow/domain/engines/rotation_engine.dart';

import 'package:tw_stock_capital_flow/data/services/capital_flow_analyzer.dart';

import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';

import 'package:tw_stock_capital_flow/domain/usecases/app_bootstrap_result.dart';

class BootstrapAnalyzer {
  static AppBootstrapResult analyze(List<StockDaySnapshot> snapshots) {
    final analyzer = CapitalFlowAnalyzer(snapshots: snapshots);

    final listedCategories = analyzer.analyzeMainCategories(
      market: MarketType.listed,
    );

    final otcCategories = analyzer.analyzeMainCategories(
      market: MarketType.otc,
    );

    final mainstreams = MainstreamEngine(snapshots: snapshots).analyze();

    final lifecycles = LifecycleEngine(
      snapshots: snapshots,
      mainstreams: mainstreams,
    ).analyze();

    final rotations = RotationEngine(snapshots: snapshots).analyze();

    final sentiment = MarketSentimentEngine(
      snapshots: snapshots,
      mainstreams: mainstreams,
    ).analyze();

    return AppBootstrapResult(
      listedCategories: listedCategories,

      otcCategories: otcCategories,

      listedRiseCount: analyzer.calculateRiseCount(market: MarketType.listed),

      listedFallCount: analyzer.calculateFallCount(market: MarketType.listed),

      otcRiseCount: analyzer.calculateRiseCount(market: MarketType.otc),

      otcFallCount: analyzer.calculateFallCount(market: MarketType.otc),

      listedScore: analyzer.calculateMarketScore(market: MarketType.listed),

      otcScore: analyzer.calculateMarketScore(market: MarketType.otc),

      mainstreams: mainstreams,

      lifecycles: lifecycles,

      rotations: rotations,

      sentiment: sentiment,
    );
  }
}

`

### lib\presentation\enums\category_sort_type.dart

`dart
enum CategorySortType { score, riseCount, fallCount, totalCount, threeDayTrend }

`

### lib\presentation\models\category_ui_model.dart

`dart
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

class CategoryUiModel {
  final String name;

  final int totalCount;

  final int riseCount;

  final int fallCount;

  final double score;

  final double day1Score;

  final double day2Score;

  final double day3Score;

  final double hotScore;

  final double persistence;

  final List<CategoryUiModel> children;

  final List<StockUiModel> stocks;

  CategoryUiModel({
    required this.name,
    required this.totalCount,
    required this.riseCount,
    required this.fallCount,
    required this.score,
    required this.day1Score,
    required this.day2Score,
    required this.day3Score,
    required this.hotScore,
    required this.persistence,
    this.children = const [],
    this.stocks = const [],
  });

  // 真正三日趨勢強度
  double get trendStrength {
    // 權重：
    // 今日 50%
    // 昨日 30%
    // 前日 20%

    final weighted = (day1Score * 0.5) + (day2Score * 0.3) + (day3Score * 0.2);

    // 趨勢加速度
    final acceleration =
        (day1Score - day2Score) + ((day2Score - day3Score) * 0.5);

    return weighted + acceleration;
  }

  // 是否為持續增強
  bool get isStrengthening {
    return day1Score > day2Score && day2Score > day3Score;
  }

  // 是否為持續衰退
  bool get isWeakening {
    return day1Score < day2Score && day2Score < day3Score;
  }

  String get hotLevel {
    final score = hotScore;

    if (score >= 80) {
      return '爆發';
    }

    if (score >= 50) {
      return '強勢';
    }

    if (score >= 20) {
      return '偏強';
    }

    if (score >= 0) {
      return '整理';
    }

    return '退潮';
  }
}

class StockUiModel {
  final StockData stock;

  final double score;

  StockUiModel({required this.stock, required this.score});
}

`

### lib\presentation\pages\home_page.dart

`dart
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

import 'package:tw_stock_capital_flow/presentation/widgets/home_section_card.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/market_summary_card.dart';

import 'package:tw_stock_capital_flow/presentation/pages/mainstream_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/main_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/pages/market_sentiment_page.dart';

// 🚀 引入本地 SQLite 歷史紀錄 Repository
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class HomePage extends StatelessWidget {
  final String tradeDate;
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final int listedRiseCount;
  final int listedFallCount;
  final double listedScore;
  final int otcRiseCount;
  final int otcFallCount;
  final double otcScore;
  final List<RotationResult> rotations;
  final List<MainstreamResult> mainstreams;
  final List<LifecycleResult> lifecycles;
  final MarketSentimentResult? sentiment;

  // 歷史資料庫接口
  final CategoryHistoryRepository historyRepository;

  const HomePage({
    super.key,
    required this.tradeDate,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.listedScore,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.otcScore,
    required this.rotations,
    required this.mainstreams,
    required this.lifecycles,
    required this.sentiment,
    required this.historyRepository,
  });

  /// 將資料庫的 YYYYMMDD 轉化為交易者易讀的 YYYY-MM-DD
  String _formatTradeDate(String rawDate) {
    if (rawDate.length == 8) {
      return '${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)}';
    }
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(), // 頂部動態日期與標題
            const SizedBox(height: 24),

            // 📊 1. 上市與上櫃多空家數診斷（保留作為一開屏的核心摘要）
            _buildMarketSection(context),
            const SizedBox(height: 24),

            // 🌊 2. 市場主流大方向（點擊直接穿透）
            _buildMainstreamSection(context),
            const SizedBox(height: 20),

            // 🧠 3. 市場熱錢情緒與心理週期（保留，提供綜合風控決策層面）
            _buildSentimentSection(context),
            const SizedBox(height: 20),

            // 💡 提示性微卡片：引導用戶切換底部頁籤看深度策略
            _buildNavigationHintCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 🟢 修正：恢復標準的具名參數賦值
            children: [
              const Text(
                '大盤大數據',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '全市場多空診斷與核心指標',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 12,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTradeDate(tradeDate),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketSection(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainCategoryPage(
                  title: '上市市場板塊',
                  categories: listedCategories,
                  historyRepository: historyRepository,
                ),
              ),
            );
          },
          child: MarketSummaryCard(
            title: '上市市場',
            riseCount: listedRiseCount,
            fallCount: listedFallCount,
            score: listedScore,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainCategoryPage(
                  title: '上櫃市場板塊',
                  categories: otcCategories,
                  historyRepository: historyRepository,
                ),
              ),
            );
          },
          child: MarketSummaryCard(
            title: '上櫃市場',
            riseCount: otcRiseCount,
            fallCount: otcFallCount,
            score: otcScore,
          ),
        ),
      ],
    );
  }

  Widget _buildMainstreamSection(BuildContext context) {
    final top = mainstreams.isEmpty ? null : mainstreams.first;

    return HomeSectionCard(
      title: '市場最強主流',
      subtitle: top == null ? '-' : top.category,
      description: '點擊深入追蹤多週期資金強勁凝聚方向',
      gradient: const [Color(0xff1e3c72), Color(0xff2a5298)],
      icon: Icons.auto_graph,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainstreamPage(mainstreams: mainstreams),
          ),
        );
      },
    );
  }

  Widget _buildSentimentSection(BuildContext context) {
    return HomeSectionCard(
      title: '市場熱錢情緒',
      subtitle: sentiment == null ? '-' : sentiment!.level.name,
      description: sentiment == null
          ? '-'
          : '熱錢湧入強度達 ${sentiment!.hotMoneyStrength.toStringAsFixed(1)}，注意水位風控',
      gradient: const [Color(0xff134e5e), Color(0xff71b280)],
      icon: Icons.psychology,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketSentimentPage(result: sentiment!),
          ),
        );
      },
    );
  }

  /// 🌟 視覺化小彩蛋：引導用戶使用底部高階標籤頁
  Widget _buildNavigationHintCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '💡 深度雷達提示：更完整的「資金熱區熱圖」、「動量紅綠燈決策」與「主力輪動領先雷達」功能已轉移至底部頁籤，提供隨切秒開的跨分頁高效操盤體驗。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

`

### lib\presentation\pages\leading_indicator_page.dart

`dart
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/domain/models/leading_indicator_result.dart';
import 'package:tw_stock_capital_flow/domain/analysers/rotation_leading_analyser.dart';

class LeadingIndicatorPage extends StatelessWidget {
  final List<RotationResult> rotations;
  final RotationLeadingAnalyser _analyser = RotationLeadingAnalyser();

  LeadingIndicatorPage({super.key, required this.rotations});

  @override
  Widget build(BuildContext context) {
    final indicators = _analyser.calculateLeadingIndicators(rotations);

    final leaders = indicators.where((e) => e.netRotationScore > 0).toList();
    final laggards = indicators.where((e) => e.netRotationScore <= 0).toList();
    laggards.sort((a, b) => a.netRotationScore.compareTo(b.netRotationScore));

    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        title: const Text(
          '資金輪動領先指標雷達',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildConceptCard(),
            const SizedBox(height: 20),

            if (leaders.isNotEmpty) ...[
              _buildSectionHeader(
                '🔥 領先吸籌板塊 (資金正灌入充電)',
                Colors.green.shade800,
                Icons.bolt,
              ),
              ...leaders.map((e) => _buildIndicatorCard(e)),
              const SizedBox(height: 20),
            ],

            if (laggards.isNotEmpty) ...[
              _buildSectionHeader(
                '⚠️ 領先失血板塊 (資金正被當提款機)',
                Colors.red.shade800,
                Icons.money_off,
              ),
              ...laggards.map((e) => _buildIndicatorCard(e)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConceptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff11998e), Color(0xff38ef7d)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                '什麼是輪動領先指標？',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '本雷達透過解構全市場主力搬錢軌跡，計算出產業的『輪動淨動能 (RNM)』。當某產業股價還在底部，但指標顯著大於零，代表主力正在悄悄建倉，能幫助您領先大盤提早埋伏飆股！',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70, // ← 修改重點
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(LeadingIndicatorResult item) {
    final isPositive = item.netRotationScore > 0;
    final themeColor = isPositive
        ? const Color(0xff2e7d32)
        : const Color(0xffc62828);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x03000000), // Colors.black.withOpacity(0.02)
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C), // black87
                ),
              ),
              Text(
                '淨動能: ${isPositive ? "+" : ""}${item.netRotationScore.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 能量條
          Row(
            children: [
              Expanded(
                flex: item.totalInflowScore.round().abs() + 1,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A), // green.shade400
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: item.totalOutflowScore.round().abs() + 1,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF9A9A), // red.shade300
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 能量條下方文字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '流入總分: +${item.totalInflowScore.toStringAsFixed(0)} (源自 ${item.inflowFeederCount} 個產業)',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575), // grey.shade600
                ),
              ),
              Text(
                '流出總分: -${item.totalOutflowScore.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575), // grey.shade600
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // 操盤指南
          Text(
            item.textGuidance,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF424242), // grey.shade800
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

`

### lib\presentation\pages\lifecycle_page.dart

`dart
import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/lifecycle_card.dart';

class LifecyclePage extends StatelessWidget {
  final List<LifecycleResult> lifecycles;

  const LifecyclePage({super.key, required this.lifecycles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '主流生命週期',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: lifecycles.length,

        itemBuilder: (_, index) {
          final item = lifecycles[index];

          return LifecycleCard(result: item);
        },
      ),
    );
  }
}

`

### lib\presentation\pages\main_category_page.dart

`dart
import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_card.dart';
// 🚀 修正路由對接：根據您的描述，點擊後應導向 SubCategoryPage，而非直接到 StockListPage
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
// 引入我們的歷史資料庫 Repository
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class MainCategoryPage extends StatefulWidget {
  final List<CategoryUiModel> categories;
  final String title;
  final CategoryHistoryRepository historyRepository; // 注入歷史資料庫接口

  const MainCategoryPage({
    super.key,
    required this.categories,
    required this.title,
    required this.historyRepository,
  });

  @override
  State<MainCategoryPage> createState() => _MainCategoryPageState();
}

class _MainCategoryPageState extends State<MainCategoryPage> {
  // 用來儲存從本地 SQLite 撈出來的各板塊歷史資金流趨勢 Map <板塊名稱, 歷史分數列表>
  final Map<String, List<double>> _dbTrendCache = {};
  bool _isLoadingDbData = true;

  @override
  void initState() {
    super.initState();
    _loadHistoricalTrends();
  }

  /// 🚀 穿透查詢：從 SQLite 撈取該類別真實的歷史走勢
  Future<void> _loadHistoricalTrends() async {
    try {
      for (final category in widget.categories) {
        // 從我們在資料庫設計的 category_history 表中，撈取過去 7 天的 snapshot 數據
        final historyRecords = await widget.historyRepository.getCategoryTrend(
          category.name,
          limit: 7,
        );

        if (historyRecords.isNotEmpty) {
          // 資料庫存儲通常是最新日期在最前(desc)，繪製畫布需要正序(由舊到新)，故使用 reversed
          final scores = historyRecords.reversed
              .map((data) => data.score)
              .toList();
          _dbTrendCache[category.name] = scores;
        }
      }
    } catch (e) {
      debugPrint('撈取本地歷史數據失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDbData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('暫無相關板塊數據')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        // scrollCacheExtent: const ScrollCacheExtent.dynamic(300.0)
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];

          // 💡 防禦機制與完美對接：
          // 如果資料庫有豐富的歷史紀錄(大於4天)，優先採用資料庫的真實長週期數據
          // 如果資料庫尚無數據(新開榜)，無縫降級採用原有的 4 點記憶體模型數據
          List<double> finalTrendValues = [
            category.day3Score,
            category.day2Score,
            category.day1Score,
            category.score,
          ];

          if (!_isLoadingDbData && _dbTrendCache.containsKey(category.name)) {
            finalTrendValues = _dbTrendCache[category.name]!;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CategoryCard(
              key: ValueKey('main_cat_${category.name}_$index'),
              title: category.name,
              totalCount: category.totalCount,
              riseCount: category.riseCount,
              fallCount: category.fallCount,
              score: category.score,
              persistence: category.persistence,
              trendValues: finalTrendValues, // 灌入優化後的真實歷史趨勢
              onTap: () {
                // 🚀 修正錯誤 2：將命名參數名稱對齊，精確傳入 categories 與必要的 historyRepository
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubCategoryPage(
                      categories: category
                          .children, // 💡 確保參數名稱對齊您的 SubCategoryPage 欄位定義
                      title: '${category.name} - 子板塊',
                      historyRepository: widget.historyRepository,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

`

### lib\presentation\pages\main_navigation_container.dart

`dart
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

// 引入各分流頁面
import 'package:tw_stock_capital_flow/presentation/pages/home_page.dart'; // 瘦身後的首頁
import 'package:tw_stock_capital_flow/presentation/pages/strategy_dashboard_page.dart'; // 策略看板
import 'package:tw_stock_capital_flow/presentation/pages/leading_indicator_page.dart'; // 領先指標
import 'package:tw_stock_capital_flow/presentation/widgets/market_heatmap.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/top_hot_categories.dart';

class MainNavigationContainer extends StatefulWidget {
  final String tradeDate;
  final List<CategoryUiModel> listedCategories;
  final List<CategoryUiModel> otcCategories;
  final int listedRiseCount;
  final int listedFallCount;
  final double listedScore;
  final int otcRiseCount;
  final int otcFallCount;
  final double otcScore;
  final List<RotationResult> rotations;
  final List<MainstreamResult> mainstreams;
  final List<LifecycleResult> lifecycles;
  final MarketSentimentResult? sentiment;
  final CategoryHistoryRepository historyRepository;

  const MainNavigationContainer({
    super.key,
    required this.tradeDate,
    required this.listedCategories,
    required this.otcCategories,
    required this.listedRiseCount,
    required this.listedFallCount,
    required this.listedScore,
    required this.otcRiseCount,
    required this.otcFallCount,
    required this.otcScore,
    required this.rotations,
    required this.mainstreams,
    required this.lifecycles,
    required this.sentiment,
    required this.historyRepository,
  });

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 🚀 使用 IndexedStack 的巨大好處：切換 Tab 時，頁面狀態不銷毀、不重繪、捲動位置不遺失
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 🏠 Tab 0: 大盤診斷 (瘦身後的首頁，內部可以移除 Heatmap、Strategy 等重複卡片)
          HomePage(
            tradeDate: widget.tradeDate,
            listedCategories: widget.listedCategories,
            otcCategories: widget.otcCategories,
            listedRiseCount: widget.listedRiseCount,
            listedFallCount: widget.listedFallCount,
            listedScore: widget.listedScore,
            otcRiseCount: widget.otcRiseCount,
            otcFallCount: widget.otcFallCount,
            otcScore: widget.otcScore,
            rotations: widget.rotations,
            mainstreams: widget.mainstreams,
            lifecycles: widget.lifecycles,
            sentiment: widget.sentiment,
            historyRepository: widget.historyRepository,
          ),

          // 📊 Tab 1: 資金熱圖中心 (將原本首頁巨大的熱圖與九宮格獨立分流到這裡)
          _buildHeatmapTabScreen(),

          // ⚡ Tab 2: 機構動量策略 (直接讓之前的動量紅綠燈看板變成一級分頁！)
          StrategyDashboardPage(
            lifecycles: widget.lifecycles,
            tradeDate: widget.tradeDate,
          ),

          // 📡 Tab 3: 輪動領先雷達
          LeadingIndicatorPage(rotations: widget.rotations),
        ],
      ),

      // 📱 現代看盤風格的底部導航欄
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: '大盤診斷',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: '資金熱區'),
          BottomNavigationBarItem(
            icon: Icon(Icons.traffic_rounded),
            label: '動量決策',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radar_rounded),
            label: '領先雷達',
          ),
        ],
      ),
    );
  }

  /// 建立獨立的熱圖與九宮格主畫面
  Widget _buildHeatmapTabScreen() {
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        title: const Text(
          '全市場資金熱區雷達',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            MarketHeatmap(
              categories: [...widget.listedCategories, ...widget.otcCategories],
              historyRepository: widget.historyRepository,
            ),
            const SizedBox(height: 32),
            TopHotCategories(
              categories: [...widget.listedCategories, ...widget.otcCategories],
              historyRepository: widget.historyRepository,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

`

### lib\presentation\pages\mainstream_page.dart

`dart
import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';

import 'package:tw_stock_capital_flow/presentation/widgets/mainstream_card.dart';

class MainstreamPage extends StatelessWidget {
  final List<MainstreamResult> mainstreams;

  const MainstreamPage({super.key, required this.mainstreams});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '市場主流',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: mainstreams.length,

        itemBuilder: (_, index) {
          final item = mainstreams[index];

          return MainstreamCard(rank: index + 1, result: item);
        },
      ),
    );
  }
}

`

### lib\presentation\pages\market_sentiment_page.dart

`dart
import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/domain/models/market_sentiment_result.dart';

class MarketSentimentPage extends StatelessWidget {
  final MarketSentimentResult result;

  const MarketSentimentPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '市場情緒',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(28),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff134e5e), Color(0xff71b280)],
                ),

                borderRadius: BorderRadius.circular(30),
              ),

              child: Column(
                children: [
                  const Text(
                    '市場情緒狀態',

                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    result.level.name,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '情緒分數 ${result.score.toStringAsFixed(1)}',

                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _Metric(title: '上漲家數', value: result.riseCount.toString()),

            _Metric(title: '下跌家數', value: result.fallCount.toString()),

            _Metric(
              title: '熱錢強度',
              value: result.hotMoneyStrength.toStringAsFixed(1),
            ),

            _Metric(
              title: '主流平均強度',
              value: result.mainstreamAverage.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;

  final String value;

  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          Text(
            value,

            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

`

### lib\presentation\pages\rotation_page.dart

`dart
import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';

class RotationPage extends StatelessWidget {
  final List<RotationResult> rotations;

  const RotationPage({super.key, required this.rotations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: const Text(
          '資金輪動',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: rotations.length,

        itemBuilder: (_, index) {
          final item = rotations[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),

            padding: const EdgeInsets.all(22),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(24),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item.toCategory,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _RotationMetric(
                        title: '輪動分數',

                        value: item.score.toStringAsFixed(1),
                      ),
                    ),

                    Expanded(
                      child: _RotationMetric(
                        title: '流入強度',

                        value: item.inflowStrength.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RotationMetric extends StatelessWidget {
  final String title;

  final String value;

  const _RotationMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,

          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(title, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

`

### lib\presentation\pages\strategy_dashboard_page.dart

`dart
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/domain/strategies/momentum_strategy.dart';
import 'package:tw_stock_capital_flow/domain/models/strategy_signal.dart';

class StrategyDashboardPage extends StatelessWidget {
  final List<LifecycleResult> lifecycles;
  final String tradeDate;
  final MomentumStrategy _strategy = MomentumStrategy();

  StrategyDashboardPage({
    super.key,
    required this.lifecycles,
    required this.tradeDate,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 1. 將所有板塊透過動量策略引擎轉換為當前訊號
    final List<StrategySignalWithSource> evaluatResult = lifecycles.map((item) {
      final signal = _strategy.evaluate(item, dateKey: tradeDate);
      return StrategySignalWithSource(signal: signal, source: item);
    }).toList();

    // 🚀 2. 將訊號分類：買進放在最前面（最重要），其次續抱，最後出清
    final buys = evaluatResult
        .where((e) => e.signal.action == StrategyAction.buy)
        .toList();
    final holds = evaluatResult
        .where((e) => e.signal.action == StrategyAction.hold)
        .toList();
    final sells = evaluatResult
        .where((e) => e.signal.action == StrategyAction.sell)
        .toList();
    final neutrals = evaluatResult
        .where((e) => e.signal.action == StrategyAction.neutral)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        title: const Text(
          '板塊動量續航決策系統',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 頂部策略說明卡片
            _buildInfoCard(),
            const SizedBox(height: 20),

            // 🟢 買進/加碼區段
            if (buys.isNotEmpty) ...[
              _buildSectionTitle('🟢 機構動能突破區 (建議買進/加碼)', Colors.green.shade800),
              ...buys.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            // 🟡 續抱/警戒區段
            if (holds.isNotEmpty) ...[
              _buildSectionTitle('🟡 趨勢鎖籌續航區 (建議持股續抱)', Colors.amber.shade900),
              ...holds.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            // 🔴 減碼/出清風控區段
            if (sells.isNotEmpty) ...[
              _buildSectionTitle('🔴 資金竭盡風控區 (建議減碼/出清)', Colors.red.shade800),
              ...sells.map((e) => _buildSignalCard(context, e)),
              const SizedBox(height: 20),
            ],

            // ⚪ 觀望區
            if (neutrals.isNotEmpty) ...[
              _buildSectionTitle('⚪ 資金冬眠盤整區 (建議空倉觀望)', Colors.grey.shade700),
              ...neutrals.map((e) => _buildSignalCard(context, e)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '七期動量續航策略指南',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '系統依據熱錢實質流入(HotMoney)、板塊擴散共振度(Diffusion)、主力買盤延續力(Persistence)與7大生命週期，自動將台股板塊歸類，協助您進行汰弱留強。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSignalCard(BuildContext context, StrategySignalWithSource item) {
    final signal = item.signal;
    final source = item.source;

    // 依據 Action 給予顏色
    Color indicatorColor = Colors.grey;
    IconData actionIcon = Icons.remove_circle_outline;
    if (signal.action == StrategyAction.buy) {
      indicatorColor = const Color(0xff2e7d32);
      actionIcon = Icons.add_shopping_cart;
    } else if (signal.action == StrategyAction.hold) {
      indicatorColor = const Color(0xffef6c00);
      actionIcon = Icons.pan_tool;
    } else if (signal.action == StrategyAction.sell) {
      indicatorColor = const Color(0xffc62828);
      actionIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // border: Border(left: BorderSide(color: indicatorColor, width: 6)),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: indicatorColor, width: 6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一排：產業名稱與生命週期狀態
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    signal.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: indicatorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${source.stage.name.toUpperCase()} 階段',
                      style: TextStyle(
                        fontSize: 11,
                        color: indicatorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二排：多維度硬核數據儀表
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniMetric('強度', source.strength.toStringAsFixed(1)),
                  _buildMiniMetric(
                    '加速度',
                    (source.acceleration >= 0 ? '+' : '') +
                        source.acceleration.toStringAsFixed(1),
                  ),
                  _buildMiniMetric(
                    '延續力',
                    '${source.persistence.toStringAsFixed(0)}%',
                  ),
                  _buildMiniMetric('熱錢', source.hotMoneyIn ? '🔥流入' : '❄️無'),
                ],
              ),
              const SizedBox(height: 12),

              // 擴散度進度條 (直觀看出是不是雞犬升天)
              Row(
                children: [
                  const Text(
                    '板塊擴散度: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: source.diffusion / 100.0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          indicatorColor.withValues(alpha: 0.7),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${source.diffusion.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 第三排：交易者的操作白話指南
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(actionIcon, size: 16, color: indicatorColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      signal.reason,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// 內部黏合資料輔助類
class StrategySignalWithSource {
  final StrategySignal signal;
  final LifecycleResult source;
  StrategySignalWithSource({required this.signal, required this.source});
}

`

### lib\presentation\pages\sub_category_page.dart

`dart
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/enums/category_sort_type.dart';
import 'package:tw_stock_capital_flow/presentation/widgets/category_card.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

// 🚀 Phase 5 核心引入：引入 Drift 的歷史數據實體模型以承接 SQLite 資料庫數據
import 'package:tw_stock_capital_flow/data/database/app_database.dart';

class SubCategoryPage extends StatefulWidget {
  final List<CategoryUiModel> categories;
  final String title;
  final CategoryHistoryRepository historyRepository;

  const SubCategoryPage({
    super.key,
    required this.categories,
    required this.title,
    required this.historyRepository,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  late List<CategoryUiModel> categories;
  CategorySortType sortType = CategorySortType.score;

  // 🚀 Phase 5 變數：儲存調取出來的歷史看盤數據與載入狀態
  List<CategoryHistoryData> _historyRecords = [];
  bool _isLoadingHistory = true;

  // 🚀 數據統計防線：當無歷史資料時，計算今日大板塊內細分產業股票的加總分佈
  int _totalRiseCount = 0;
  int _totalFallCount = 0;
  int _totalStockCount = 0;

  @override
  void initState() {
    super.initState();
    categories = [...widget.categories];
    applySort();

    // 💡 預先統計今日該板塊內所有個股的漲跌總數，提供雷達圓餅圖最精準的占比
    _calculateLiveDistribution();

    // 🚀 初始化時，立刻向本地 SQLite 發起歷史數據穿透回溯
    _fetchHistoryData();
  }

  /// 計算今日即時分布狀態
  void _calculateLiveDistribution() {
    _totalRiseCount = 0;
    _totalFallCount = 0;
    _totalStockCount = 0;
    for (final cat in categories) {
      _totalRiseCount += cat.riseCount;
      _totalFallCount += cat.fallCount;
      _totalStockCount += cat.totalCount;
    }
  }

  // 🚀 Phase 5 方法：實作非同步歷史軌跡回溯
  Future<void> _fetchHistoryData() async {
    setState(() => _isLoadingHistory = true);
    try {
      // 💡 精確對接專案原始代碼：呼叫 getCategoryTrend 取得 15 天歷史
      final records = await widget.historyRepository.getCategoryTrend(
        widget.title, // 傳入當前大分類板塊名稱
        limit: 15, // 拉取 15 天數據
      );

      if (mounted) {
        setState(() {
          _historyRecords = records;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void applySort() {
    switch (sortType) {
      case CategorySortType.score:
        categories.sort((a, b) => b.score.compareTo(a.score));
        break;
      case CategorySortType.riseCount:
        categories.sort((a, b) => b.riseCount.compareTo(a.riseCount));
        break;
      case CategorySortType.fallCount:
        categories.sort((a, b) => b.fallCount.compareTo(a.fallCount));
        break;
      case CategorySortType.totalCount:
        categories.sort((a, b) => b.totalCount.compareTo(a.totalCount));
        break;
      case CategorySortType.threeDayTrend:
        categories.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<CategorySortType>(
            onSelected: (value) {
              sortType = value;
              applySort();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: CategorySortType.score,
                child: Text('資金流優先'),
              ),
              const PopupMenuItem(
                value: CategorySortType.threeDayTrend,
                child: Text('三日強度排序'),
              ),
              const PopupMenuItem(
                value: CategorySortType.riseCount,
                child: Text('上漲家數多'),
              ),
              const PopupMenuItem(
                value: CategorySortType.fallCount,
                child: Text('下跌家數多'),
              ),
              const PopupMenuItem(
                value: CategorySortType.totalCount,
                child: Text('股票數量規模'),
              ),
            ],
          ),
        ],
      ),
      // 🚀【升級核心】：將原本的 body: ListView 改用 CustomScrollView
      // 如此一來才能在同一個滾動視窗中，完美結合「頂部歷史趨勢面板」與「下方細分類卡片列表」
      body: CustomScrollView(
        slivers: [
          // 🚀 1. 頂部組件：歷史看盤面板外殼
          SliverToBoxAdapter(child: _buildHistoryTrendHeader()),

          // 🚀 2. 分隔小標題
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
              child: Text(
                '包含細分板塊 (${categories.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),

          // 🚀 3. 下方列表：將舊的 ListView 完美轉換為高級的 SliverList
          SliverPadding(
            // 🟢 修正點：使用 EdgeInsets.only 精確定義上下左右的間距
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = categories[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ), // 替代原本 ListView 的間距效果
                  child: CategoryCard(
                    key: ValueKey('sub_cat_${item.name}_$index'),
                    title: item.name,
                    totalCount: item.totalCount,
                    riseCount: item.riseCount,
                    fallCount: item.fallCount,
                    score: item.score,
                    trendValues: [
                      item.day3Score,
                      item.day2Score,
                      item.day1Score,
                      item.score,
                    ],
                    persistence: item.persistence,
                    onTap: () {
                      CategoryNavigation.showStockListSheet(
                        context: context,
                        categoryName: item.name,
                        uiStocks: item.stocks,
                      );
                    },
                  ),
                );
              }, childCount: categories.length),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 Phase 5 核心自繪組件：打造高階趨勢看盤圖表面板外殼
  Widget _buildHistoryTrendHeader() {
    // 💡 判斷是否具備大於 1 筆的歷史資料，若目前尚無資料，則觸發「今日盤態雷達分佈」
    final bool hasHistory = _historyRecords.length > 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasHistory
                    ? '${widget.title} 板塊歷史資金走勢'
                    : '${widget.title} 今日盤態雷達',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasHistory
                      ? Colors.blueAccent.withValues(alpha: 0.08)
                      : Colors.orangeAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasHistory ? '歷史 K 線回溯' : '即時多空分佈',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasHistory
                        ? Colors.blueAccent
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 圖表渲染核心限制盒（固定高度 140）
          SizedBox(
            height: 140,
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : hasHistory
                ? _buildLineChart() // 📈 渲染歷史折線走勢圖
                : _buildLiveDistributionRadar(), // 📊 降級防線：即時多空比例圖
          ),
        ],
      ),
    );
  }

  /// 📈 核心圖表 A：自繪 15 日資金流分數走勢圖
  Widget _buildLineChart() {
    final scores = _historyRecords.map((e) => e.score).toList();
    final dates = _historyRecords
        .map(
          (e) =>
              e.tradeDate.length > 4 ? e.tradeDate.substring(4) : e.tradeDate,
        )
        .toList();

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: CategoryTrendPainter(scores: scores),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dates.first,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              dates[dates.length ~/ 2],
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              dates.last,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 核心圖表 B（即時雷達防線）：今日細成份股多空漲跌分佈圓餅圖
  /// 🟢 安全完全體：移除了所有致命的內部 SliverToBoxAdapter，改用純粹的標準佈局組件
  Widget _buildLiveDistributionRadar() {
    final double riseRatio = _totalStockCount > 0
        ? _totalRiseCount / _totalStockCount
        : 0.0;
    final double fallRatio = _totalStockCount > 0
        ? _totalFallCount / _totalStockCount
        : 0.0;
    final double keepRatio = 1.0 - riseRatio - fallRatio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🟢 100% 安全：使用固定寬高 SizedBox 包裹自繪甜甜圈圓餅圖，絕不卡死或死循環
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: DistributionPiePainter(
              riseRatio: riseRatio,
              fallRatio: fallRatio,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // 右側：高階數據指標對照表
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRadarLabel(
                '上漲家數',
                '$_totalRiseCount 檔',
                '${(riseRatio * 100).toStringAsFixed(1)}%',
                const Color(0xffc62828),
              ),
              const SizedBox(height: 6),
              _buildRadarLabel(
                '下跌家數',
                '$_totalFallCount 檔',
                '${(fallRatio * 100).toStringAsFixed(1)}%',
                const Color(0xff2e7d32),
              ),
              const SizedBox(height: 6),
              _buildRadarLabel(
                '平盤/其他',
                '${_totalStockCount - _totalRiseCount - _totalFallCount} 檔',
                '${(keepRatio * 100).toStringAsFixed(1)}%',
                Colors.grey.shade400,
              ),
              const Divider(height: 12),
              Text(
                '板塊個股總計: $_totalStockCount 檔',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadarLabel(
    String label,
    String count,
    String percent,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const Spacer(),
        Text(
          count,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Text(
          percent,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🎨 底層自繪引擎：趨勢折線圖畫布 (CategoryTrendPainter)
// ==========================================
class CategoryTrendPainter extends CustomPainter {
  final List<double> scores;
  CategoryTrendPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    double maxScore = scores.reduce((a, b) => a > b ? a : b);
    double minScore = scores.reduce((a, b) => a < b ? a : b);

    if ((maxScore - minScore).abs() < 0.1) {
      maxScore += 1.0;
      minScore -= 1.0;
    }

    maxScore += (maxScore - minScore) * 0.1;
    minScore -= (maxScore - minScore) * 0.1;

    final double range = maxScore - minScore;

    // 繪製零軸參考線
    if (maxScore > 0 && minScore < 0) {
      final double zeroY = height - ((0.0 - minScore) / range * height);
      final Paint zeroPaint = Paint()
        ..color = Colors.grey.shade200
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, zeroY), Offset(width, zeroY), zeroPaint);
    }

    // 建立折線點
    final double stepX = width / (scores.length - 1);
    final List<Offset> points = [];
    for (int i = 0; i < scores.length; i++) {
      final double x = i * stepX;
      final double y = height - ((scores[i] - minScore) / range * height);
      points.add(Offset(x, y));
    }

    // 繪製漸層陰影
    final Path shadowPath = Path()..moveTo(points.first.dx, height);
    for (var pt in points) {
      shadowPath.lineTo(pt.dx, pt.dy);
    }
    shadowPath.lineTo(points.last.dx, height);
    shadowPath.close();

    final Paint shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blueAccent.withValues(alpha: 0.15),
          Colors.blueAccent.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTRB(0, 0, width, height));
    canvas.drawPath(shadowPath, shadowPaint);

    // 繪製主趨勢折線
    final Paint linePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // 繪製最新端點
    final Paint dotPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;
    // 🟢 修正點：使用相容性最高、最穩定的 withOpacity(0.2) 宣告光暈
    final Paint dotHalo = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(points.last, 7, dotHalo);
    canvas.drawCircle(points.last, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CategoryTrendPainter oldDelegate) =>
      oldDelegate.scores != scores;
}

// ==========================================
// 🎨 底層自繪引擎：今日多空分佈圓餅圖 (DistributionPiePainter)
// ==========================================
class DistributionPiePainter extends CustomPainter {
  final double riseRatio;
  final double fallRatio;

  DistributionPiePainter({required this.riseRatio, required this.fallRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint risePaint = Paint()
      ..color = const Color(0xffc62828)
      ..style = PaintingStyle.fill;
    final Paint fallPaint = Paint()
      ..color = const Color(0xff2e7d32)
      ..style = PaintingStyle.fill;
    final Paint keepPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    double startAngle = -3.1415926 / 2; // 從 12 點鐘方向順時針繪製

    // 1. 繪製上漲區塊
    if (riseRatio > 0) {
      final double sweepAngle = riseRatio * 2 * 3.1415926;
      canvas.drawArc(rect, startAngle, sweepAngle, true, risePaint);
      startAngle += sweepAngle;
    }

    // 2. 繪製下跌區塊
    if (fallRatio > 0) {
      final double sweepAngle = fallRatio * 2 * 3.1415926;
      canvas.drawArc(rect, startAngle, sweepAngle, true, fallPaint);
      startAngle += sweepAngle;
    }

    // 3. 繪製平盤區塊
    final double keepRatio = 1.0 - riseRatio - fallRatio;
    if (keepRatio > 0) {
      final double sweepAngle = keepRatio * 2 * 3.1415926;
      canvas.drawArc(rect, startAngle, sweepAngle, true, keepPaint);
    }

    // 4. 中心挖空成甜甜圈圖（Donut Chart）
    final Paint centerHolePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, centerHolePaint);
  }

  @override
  bool shouldRepaint(covariant DistributionPiePainter oldDelegate) =>
      oldDelegate.riseRatio != riseRatio || oldDelegate.fallRatio != fallRatio;
}

`

### lib\presentation\theme\app_theme.dart

`dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const bg = Color(0xFFF4F7FB);

  static const card = Colors.white;

  static const primary = Color(0xFF2563EB);

  static const text = Color(0xFF111827);

  static const subText = Color(0xFF6B7280);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.light,

    scaffoldBackgroundColor: bg,

    primaryColor: primary,

    textTheme: GoogleFonts.notoSansTextTheme(),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: bg,
      foregroundColor: text,
    ),

    cardTheme: CardThemeData(
      color: card,

      elevation: 0,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),

      margin: EdgeInsets.zero,
    ),
  );
}

`

### lib\presentation\widgets\category_card.dart

`dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'trend_sparkline.dart';
import 'hot_badge.dart';

class CategoryCard extends StatelessWidget {
  final String title;

  final int totalCount;

  final int riseCount;

  final int fallCount;

  final double score;

  final VoidCallback onTap;

  final List<double> trendValues;

  final double persistence;

  const CategoryCard({
    super.key,
    required this.title,
    required this.totalCount,
    required this.riseCount,
    required this.fallCount,
    required this.score,
    required this.onTap,
    required this.trendValues,
    required this.persistence,
  });

  @override
  Widget build(BuildContext context) {
    final positive = score >= 0;

    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(28),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),

                gradient: LinearGradient(
                  colors: positive
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                      : [const Color(0xFF00C9A7), const Color(0xFF00B894)],
                ),
              ),

              child: const Icon(Icons.candlestick_chart, color: Colors.white),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 10,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      HotBadge(score: score),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text('持續性 ${persistence.toStringAsFixed(1)}'),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                TrendSparkline(values: trendValues),
                const SizedBox(height: 10),
                Text(
                  score.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,

                    color: positive ? Colors.redAccent : Colors.green,
                  ),
                ),

                const SizedBox(height: 6),

                Text('三日資金流', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.12, end: 0);
  }
}

`

### lib\presentation\widgets\empty_view.dart

`dart

`

### lib\presentation\widgets\home_section_card.dart

`dart
import 'package:flutter/material.dart';

class HomeSectionCard extends StatelessWidget {
  final String title;

  final String subtitle;

  final String description;

  final List<Color> gradient;

  final IconData icon;

  final VoidCallback onTap;

  const HomeSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.only(bottom: 18),

        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(30),

          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.25),

              blurRadius: 20,

              offset: const Offset(0, 12),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),

                borderRadius: BorderRadius.circular(22),
              ),

              child: Icon(icon, color: Colors.white, size: 34),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    subtitle,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    description,

                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),

                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }
}

`

### lib\presentation\widgets\hot_badge.dart

`dart
import 'package:flutter/material.dart';

class HotBadge extends StatelessWidget {
  final double score;

  const HotBadge({super.key, required this.score});

  String get label {
    if (score >= 80) {
      return '爆發';
    }

    if (score >= 50) {
      return '強勢';
    }

    if (score >= 20) {
      return '偏強';
    }

    if (score >= 0) {
      return '整理';
    }

    return '退潮';
  }

  Color get color {
    if (score >= 80) {
      return Colors.deepOrange;
    }

    if (score >= 50) {
      return Colors.orange;
    }

    if (score >= 20) {
      return Colors.amber;
    }

    if (score >= 0) {
      return Colors.blueGrey;
    }

    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

`

### lib\presentation\widgets\lifecycle_card.dart

`dart
import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/domain/enums/lifecycle_stage.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';

class LifecycleCard extends StatelessWidget {
  final LifecycleResult result;

  const LifecycleCard({super.key, required this.result});

  String get stageName {
    switch (result.stage) {
      case LifecycleStage.ignition:
        return '點火';

      case LifecycleStage.expansion:
        return '擴散';

      case LifecycleStage.markup:
        return '主升';

      case LifecycleStage.euphoric:
        return '市場狂熱';

      case LifecycleStage.distribution:
        return '高檔出貨';

      case LifecycleStage.decline:
        return '退潮';

      case LifecycleStage.dead:
        return '死亡';
    }
  }

  Color get color {
    switch (result.stage) {
      case LifecycleStage.ignition:
        return Colors.blue;

      case LifecycleStage.expansion:
        return Colors.teal;

      case LifecycleStage.markup:
        return Colors.orange;

      case LifecycleStage.euphoric:
        return Colors.red;

      case LifecycleStage.distribution:
        return Colors.purple;

      case LifecycleStage.decline:
        return Colors.grey;

      case LifecycleStage.dead:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(28),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.category,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Text(
                  stageName,

                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          LinearProgressIndicator(
            value: result.strength / 100,

            borderRadius: BorderRadius.circular(999),

            minHeight: 12,

            backgroundColor: Colors.grey.shade200,

            valueColor: AlwaysStoppedAnimation(color),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _Metric(title: '加速度', value: result.acceleration),
              ),

              Expanded(
                child: _Metric(title: '持續性', value: result.persistence),
              ),

              Expanded(
                child: _Metric(title: '擴散', value: result.diffusion),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;

  final double value;

  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),

          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        Text(title, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

`

### lib\presentation\widgets\mainstream_card.dart

`dart
import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';

class MainstreamCard extends StatelessWidget {
  final int rank;

  final MainstreamResult result;

  const MainstreamCard({super.key, required this.rank, required this.result});

  Color get trendColor {
    if (result.mainstreamScore >= 80) {
      return Colors.deepOrange;
    }

    if (result.mainstreamScore >= 60) {
      return Colors.orange;
    }

    if (result.mainstreamScore >= 40) {
      return Colors.amber;
    }

    return Colors.blueGrey;
  }

  String get status {
    if (result.strengthening) {
      return '資金增強';
    }

    if (result.weakening) {
      return '資金退潮';
    }

    return '整理';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(28),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: Text(
                  '$rank',

                  style: TextStyle(
                    color: trendColor,

                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      result.category,

                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(status, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Column(
                  children: [
                    Text(
                      result.mainstreamScore.toStringAsFixed(1),

                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '主流分數',

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: '資金流',
                  value: result.flowScore,
                  icon: Icons.water_drop,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _MetricCard(
                  title: '持續性',
                  value: result.persistenceScore,
                  icon: Icons.timeline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: '擴散度',
                  value: result.diffusionScore,
                  icon: Icons.hub,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _MetricCard(
                  title: '領頭羊',
                  value: result.leaderScore,
                  icon: Icons.emoji_events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;

  final double value;

  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xfff7f9fc),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Icon(icon, color: Colors.blueGrey),

          const SizedBox(height: 10),

          Text(
            value.toStringAsFixed(1),

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            title,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

`

### lib\presentation\widgets\market_heatmap.dart

`dart
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

// 🚀 正確引入歷史紀錄 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class MarketHeatmap extends StatelessWidget {
  final List<CategoryUiModel> categories;

  // 🚀 注入歷史資料庫接口，用以向下傳遞給二級導頁
  final CategoryHistoryRepository historyRepository;

  const MarketHeatmap({
    super.key,
    required this.categories,
    required this.historyRepository, // ⚡ 納入必要參數
  });

  Color _color(double score) {
    if (score >= 80) {
      return Colors.red;
    }

    if (score >= 50) {
      return Colors.orange;
    }

    if (score >= 20) {
      return Colors.green;
    }

    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final topCategories = [...categories]
      ..sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '市場熱區',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topCategories.length > 12 ? 12 : topCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final e = topCategories[index];

            return GestureDetector(
              onTap: () {
                // 🚀 【完美修復點】：精確傳入三個參數，完成依賴穿透鏈結
                CategoryNavigation.openCategory(context, e, historyRepository);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color(e.hotScore),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        e.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      e.hotLevel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '熱度 ${e.hotScore.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

`

### lib\presentation\widgets\market_summary_card.dart

`dart
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class MarketSummaryCard extends StatelessWidget {
  final String title;

  final int riseCount;

  final int fallCount;

  final double score;

  const MarketSummaryCard({
    super.key,
    required this.title,
    required this.riseCount,
    required this.fallCount,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final positive = score >= 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: positive
              ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),

        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),

          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),

                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: _buildMarketInfo(
                        '上漲',

                        riseCount.toString(),

                        Colors.redAccent,
                      ),
                    ),

                    Expanded(
                      child: _buildMarketInfo(
                        '下跌',

                        fallCount.toString(),

                        Colors.greenAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  '資金流強度',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 8),

                AnimatedFlipCounter(
                  value: score,

                  fractionDigits: 2,

                  textStyle: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketInfo(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),

        const SizedBox(height: 8),

        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

`

### lib\presentation\widgets\rotation_flow_card.dart

`dart
import 'package:flutter/material.dart';

import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';

class RotationFlowCard extends StatelessWidget {
  final RotationResult result;

  const RotationFlowCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  result.fromCategory,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.arrow_forward, color: Colors.orange),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        result.toCategory,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(
              color: Colors.orange.shade50,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              children: [
                Text(
                  result.inflowStrength.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '輪動強度',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

`

### lib\presentation\widgets\section_title.dart

`dart
import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

`

### lib\presentation\widgets\shimmer_skeleton.dart

`dart
import 'package:flutter/material.dart';

/// 泛用型高效微光骨架屏元件
class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 🚀 使用 1.2 秒的循環打光動畫，維持流暢視覺感
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // 動態計算掃描漸層的起訖點
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 模擬主頁卡片的骨架屏排版
class MainSectionSkeleton extends StatelessWidget {
  const MainSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerSkeleton(width: 140, height: 28),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const ShimmerSkeleton(
                  width: 62,
                  height: 62,
                  borderRadius: KaBorderRadius.r20,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerSkeleton(width: 120, height: 22),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const ShimmerSkeleton(width: 60, height: 16),
                          const SizedBox(width: 8),
                          const ShimmerSkeleton(width: 50, height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                const ShimmerSkeleton(width: 70, height: 45),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class KaBorderRadius {
  static const BorderRadius r20 = BorderRadius.all(Radius.circular(20));
}

`

### lib\presentation\widgets\stock_tile.dart

`dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

class StockTile extends StatelessWidget {
  final StockData stock;

  final double score;

  const StockTile({super.key, required this.stock, required this.score});

  Future<void> _openYahooPage() async {
    try {
      final suffix = stock.market == MarketType.listed ? 'TW' : 'TWO';

      final uri = Uri.parse(
        'https://tw.stock.yahoo.com/quote/${stock.code}.$suffix/technical-analysis',
      );

      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        return;
      }

      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: _openYahooPage,

        title: Text('${stock.code} ${stock.name}'),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            children: [
              Text(
                '${stock.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: stock.changePercent >= 0
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
              ),

              Text('成交額 ${(stock.value / 100000000).toStringAsFixed(2)}億'),
            ],
          ),
        ),

        trailing: Text(
          score.toStringAsFixed(2),
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

`

### lib\presentation\widgets\top_hot_categories.dart

`dart
import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/core/navigation/category_navigation.dart';

// 🚀 正確引入歷史紀錄 Repository 依賴
import 'package:tw_stock_capital_flow/data/history/repositories/category_history_repository.dart';

class TopHotCategories extends StatelessWidget {
  final List<CategoryUiModel> categories;
  final Function(CategoryUiModel)? onCategoryTap; // 可選：點擊回調

  // 🚀 注入歷史資料庫接口，用以向下傳遞給二級導頁
  final CategoryHistoryRepository historyRepository;

  const TopHotCategories({
    super.key,
    required this.categories,
    required this.historyRepository, // ⚡ 納入必要參數
    this.onCategoryTap, // 可選參數
  });

  @override
  Widget build(BuildContext context) {
    final top = [...categories];
    top.sort((a, b) => b.trendStrength.compareTo(a.trendStrength));

    final top5 = top.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '今日主流類股',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 18),

        ...top5.map(
          (e) => GestureDetector(
            onTap: () {
              // 🚀 如果有外部自訂的回調就執行
              if (onCategoryTap != null) {
                onCategoryTap!(e);
              }
              // 🚀 【完美修復點】：精確傳入三個參數，完成歷史走勢依賴的無縫穿透
              CategoryNavigation.openCategory(context, e, historyRepository);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '資金流 ${e.score.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      e.trendStrength.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

`

### lib\presentation\widgets\trend_sparkline.dart

`dart
import 'package:flutter/material.dart';

class TrendSparkline extends StatelessWidget {
  final List<double> values;
  final double? max;
  final double? min;
  final double height;
  final double width;

  const TrendSparkline({
    super.key,
    required this.values,
    this.max,
    this.min,
    this.height = 40,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(width: width, height: height);

    // 計算最大最小值以供歸一化坐標系使用
    double computedMax = max ?? values.reduce((a, b) => a > b ? a : b);
    double computedMin = min ?? values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          max: computedMax,
          min: computedMin,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final double max;
  final double min;

  _SparklinePainter({
    required this.values,
    required this.max,
    required this.min,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 頭尾數值對比判定趨勢顏色（漲紅跌綠，符合台股文化）
    final positive = values.last >= values.first;
    paint.color = positive ? Colors.redAccent : Colors.green;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x =
          (i / (values.length - 1 == 0 ? 1 : values.length - 1)) * size.width;

      final range = max - min;
      final normalized = (range == 0) ? 0.5 : (values[i] - min) / range;

      // 畫布座標 Y 軸向下，需用高度相減進行反轉
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    // 🚀 【性能優化核心：精準重繪屏障】
    // 只有在最大、最小值發生變動，或者數據源長度、內容不一致時，才允許 Canvas 重新繪製
    if (oldDelegate.max != max || oldDelegate.min != min) return true;
    if (oldDelegate.values.length != values.length) return true;

    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }

    return false; // 資料完全相同，直接複用上一幀緩衝（Bitmap Cache），達到 0% 運算浪費
  }
}

`

