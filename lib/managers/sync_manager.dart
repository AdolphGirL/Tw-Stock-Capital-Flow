import 'dart:developer' as dev;

import 'package:tw_stock_capital_flow/models/stock_data.dart';
import 'package:tw_stock_capital_flow/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/services/market_calendar_service.dart';
import 'package:tw_stock_capital_flow/services/storage_service.dart';
import 'package:tw_stock_capital_flow/services/stock_service.dart';

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

      return SyncResult(
        success: false,
        saved: false,
        message: e.toString(),
        date: '',
        stockCount: 0,
        stocks: [],
      );
    }
  }

  String _resolveLatestDate({
    required String listedDate,
    required String otcDate,
  }) {
    if (listedDate.isEmpty && otcDate.isEmpty) {
      return '';
    }

    if (listedDate.isEmpty) {
      return otcDate;
    }

    if (otcDate.isEmpty) {
      return listedDate;
    }

    return listedDate.compareTo(otcDate) < 0 ? listedDate : otcDate;
  }
}
