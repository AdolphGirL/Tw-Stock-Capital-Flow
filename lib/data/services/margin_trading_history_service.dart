import 'dart:developer' as dev;

import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/domain/models/margin_trading_result.dart';

/// 融資融券餘額每日歷史存取。
/// 資料存於 daily 目錄下的 margin_trading_history.json（不受快照清理影響）。
class MarginTradingHistoryService {
  static const _filename = 'margin_trading_history.json';
  static const _maxKeep = 30; // 保留最近 30 個交易日

  /// 將今日結果追加（或更新）至歷史 JSON，最多保留 [_maxKeep] 筆。
  static Future<void> save(
    StorageService storage,
    MarginTradingResult result,
  ) async {
    try {
      final existing = await _load(storage);
      // 移除相同日期的舊紀錄（idempotent upsert）
      existing.removeWhere((e) => e.date == result.date);
      existing.add(result);
      // 按日期排序後只保留最新 N 筆
      existing.sort((a, b) => a.date.compareTo(b.date));
      final kept = existing.length > _maxKeep
          ? existing.sublist(existing.length - _maxKeep)
          : existing;

      await storage.writeJson(
        _filename,
        {'entries': kept.map((e) => e.toJson()).toList()},
      );
      dev.log('[融資融券歷史] 已儲存 ${result.date}，共 ${kept.length} 筆', name: 'MarginTradingHistory');
    } catch (e) {
      dev.log('[融資融券歷史] 儲存失敗（不影響主流程）: $e', name: 'MarginTradingHistory');
    }
  }

  /// 讀取歷史，由舊到新排序（index 0 = 最舊）。
  static Future<List<MarginTradingResult>> loadRecent(
    StorageService storage, {
    int limit = _maxKeep,
  }) async {
    final all = await _load(storage);
    if (all.isEmpty) return [];
    all.sort((a, b) => a.date.compareTo(b.date));
    return all.length > limit ? all.sublist(all.length - limit) : all;
  }

  static Future<List<MarginTradingResult>> _load(StorageService storage) async {
    try {
      final json = await storage.readJson(_filename);
      if (json == null) return [];
      final rawList = json['entries'] as List<dynamic>? ?? [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(MarginTradingResult.fromJson)
          .toList();
    } catch (e) {
      dev.log('[融資融券歷史] 讀取失敗: $e', name: 'MarginTradingHistory');
      return [];
    }
  }
}
