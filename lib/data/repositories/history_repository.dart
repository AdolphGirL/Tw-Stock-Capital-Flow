import 'dart:developer' as dev;

import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';
import 'package:tw_stock_capital_flow/data/services/debug_log_service.dart'; // TODO(debug): 除錯用

class HistoryRepository {
  final StorageService storageService;

  HistoryRepository({required this.storageService});

  Future<List<StockDaySnapshot>> loadRecentSnapshots(int days) async {
    final listedDates = await storageService.listListedDates();
    return await _loadFromSplitFiles(listedDates, days);
  }

  /// 從 listed_* 和 otc_* 分別讀取後合併成單一快照，供分析引擎使用。
  Future<List<StockDaySnapshot>> _loadFromSplitFiles(
    List<String> listedDates,
    int days,
  ) async {
    final otcDates = await storageService.listOtcDates();
    final recentDates = listedDates.take(days).toList();

    dev.log('loadRecentSnapshots[新格式]: listed ${recentDates.length} 筆', name: 'HistoryRepository');

    final result = <StockDaySnapshot>[];
    for (int i = 0; i < recentDates.length; i++) {
      final ld = recentDates[i];
      final listedSnap = await storageService.loadListedSnapshot(ld);

      // 優先找同日期的 OTC；若不存在則取最近可用的
      final otcDateMatched = otcDates.contains(ld);
      final otcDate = otcDateMatched ? ld : (otcDates.isNotEmpty ? otcDates.first : null);
      final otcSnap = otcDate != null ? await storageService.loadOtcSnapshot(otcDate) : null;

      // i==0 是「目前顯示在畫面上」的那一份快照（個股漲跌/成交量的直接來源）。
      // 若這一筆上市/上櫃日期對不上，個股清單會混用「今天的上市」+「非今天的上櫃」，
      // 使用者會看到上市正確、但上櫃個股停留在前一個可用交易日的數字。
      if (i == 0 && !otcDateMatched) {
        DebugLogService.log(
          'History',
          '⚠️ 最新一筆(listed=$ld)找不到同日期上櫃快照，個股清單改用上櫃 $otcDate（可能導致上櫃個股顯示非當日資料）',
        );
      }

      final merged = [...?listedSnap?.stocks, ...?otcSnap?.stocks];
      if (merged.isNotEmpty) {
        result.add(StockDaySnapshot(date: ld, stocks: merged));
        dev.log('loadRecentSnapshots: $ld 合併 ${merged.length} 檔（OTC: $otcDate）', name: 'HistoryRepository');
      }
    }
    return result;
  }
}
