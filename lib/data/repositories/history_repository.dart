import 'dart:developer' as dev;

import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';

class HistoryRepository {
  final StorageService storageService;

  HistoryRepository({required this.storageService});

  Future<List<StockDaySnapshot>> loadRecentSnapshots(int days) async {
    // 優先嘗試新格式（listed_YYYMMDD + otc_YYYMMDD）
    final listedDates = await storageService.listListedDates();
    if (listedDates.isNotEmpty) {
      return await _loadFromSplitFiles(listedDates, days);
    }

    // 回退舊格式（YYYMMDD）
    final dates = await storageService.listAvailableDates();
    final datePattern = RegExp(r'^\d{7,8}$');
    final validDates = dates.where((d) => datePattern.hasMatch(d)).take(days).toList();
    dev.log('loadRecentSnapshots[舊格式]: ${validDates.length} 筆: $validDates', name: 'HistoryRepository');

    final result = <StockDaySnapshot>[];
    for (final date in validDates) {
      final snapshot = await storageService.loadSnapshot(date);
      if (snapshot != null && snapshot.date.isNotEmpty) result.add(snapshot);
    }
    return result;
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
    for (final ld in recentDates) {
      final listedSnap = await storageService.loadListedSnapshot(ld);

      // 優先找同日期的 OTC；若不存在則取最近可用的
      final otcDate = otcDates.contains(ld) ? ld : (otcDates.isNotEmpty ? otcDates.first : null);
      final otcSnap = otcDate != null ? await storageService.loadOtcSnapshot(otcDate) : null;

      final merged = [...?listedSnap?.stocks, ...?otcSnap?.stocks];
      if (merged.isNotEmpty) {
        result.add(StockDaySnapshot(date: ld, stocks: merged));
        dev.log('loadRecentSnapshots: $ld 合併 ${merged.length} 檔（OTC: $otcDate）', name: 'HistoryRepository');
      }
    }
    return result;
  }
}
