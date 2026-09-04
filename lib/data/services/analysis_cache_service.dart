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
import 'dart:developer' as dev;

class AnalysisCacheService {
  final StorageService _storageService;
  static const String _cachePrefix = 'bootstrap_cache_';

  AnalysisCacheService(this._storageService);

  /// 將全域計算好的 AppBootstrapResult 轉換成 JSON，寫入 `bootstrap_cache_{dateKey}.json`
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
        'listedLifecycles': result.listedLifecycles
            .map((e) => _lifecycleToMap(e))
            .toList(),
        'otcLifecycles': result.otcLifecycles
            .map((e) => _lifecycleToMap(e))
            .toList(),
        'listedRotations': result.listedRotations
            .map((e) => e.toJson())
            .toList(), // 點 4：使用專案內建的 toJson
        'otcRotations': result.otcRotations
            .map((e) => e.toJson())
            .toList(),
        'sentiment': _sentimentToMap(result.sentiment),
      };

      final jsonString = jsonEncode(jsonMap);
      await _storageService.writeFile('$_cachePrefix$dateKey.json', jsonString);
    } catch (_) {}
  }

  /// 嘗試讀取今日快取，完美還原為強型別物件
  Future<AppBootstrapResult?> loadBootstrapCache(String dateKey) async {
    try {
      final jsonString = await _storageService.readFile('$_cachePrefix$dateKey.json');
      if (jsonString == null || jsonString.isEmpty) return null;

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
        // listedLifecycles/otcLifecycles 為舊版快取所無的欄位，缺省時退回空清單
        // （StrategyDashboardPage 會在下次有新資料時自然補齊，不影響其他頁面）
        listedLifecycles: jsonMap['listedLifecycles'] == null
            ? const []
            : (jsonMap['listedLifecycles'] as List)
                .map((e) => _mapToLifecycle(e))
                .toList(),
        otcLifecycles: jsonMap['otcLifecycles'] == null
            ? const []
            : (jsonMap['otcLifecycles'] as List)
                .map((e) => _mapToLifecycle(e))
                .toList(),
        listedRotations: jsonMap['listedRotations'] == null
            ? const []
            : (jsonMap['listedRotations'] as List)
                .map((e) => RotationResult.fromJson(e))
                .toList(), // 點 4：使用專案內建的 fromJson
        otcRotations: jsonMap['otcRotations'] == null
            ? const []
            : (jsonMap['otcRotations'] as List)
                .map((e) => RotationResult.fromJson(e))
                .toList(),
        sentiment: _mapToSentiment(jsonMap['sentiment']),
      );
    } catch (_) {
      return null;
    }
  }

  /// 離線防禦兜底機制：掃描本地快照目錄找出最新一份 bootstrap_cache_*.json
  Future<AppBootstrapResult?> tryGetAnyLatestCache() async {
    try {
      final List<String> allFiles = await _storageService.listAvailableDates();

      // 篩選屬於資金流快取的檔名
      final cacheKeys = allFiles
          .where((k) => k.startsWith(_cachePrefix))
          .toList();
      if (cacheKeys.isEmpty) return null;

      // 排序並還原日期標籤
      cacheKeys.sort((a, b) => b.compareTo(a));
      final String latestCacheKey = cacheKeys.first.replaceFirst(
        _cachePrefix,
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
