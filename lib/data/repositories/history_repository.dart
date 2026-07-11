import 'dart:developer' as dev;

import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/data/services/storage_service.dart';

class HistoryRepository {
  final StorageService storageService;

  HistoryRepository({required this.storageService});

  Future<List<StockDaySnapshot>> loadRecentSnapshots(int days) async {
    final dates = await storageService.listAvailableDates();

    // 只保留純日期格式（民國年 7碼或西元年 8碼）的檔案，跳過 bootstrap_cache 等非快照檔案
    final datePattern = RegExp(r'^\d{7,8}$');
    final validDates = dates.where((d) => datePattern.hasMatch(d)).take(days).toList();

    dev.log('loadRecentSnapshots: 有效日期 ${validDates.length} 筆: $validDates', name: 'HistoryRepository');

    final result = <StockDaySnapshot>[];

    for (final date in validDates) {
      final snapshot = await storageService.loadSnapshot(date);

      if (snapshot != null && snapshot.date.isNotEmpty) {
        result.add(snapshot);
      }
    }

    return result;
  }
}
