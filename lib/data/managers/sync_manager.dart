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
  final String date;        // 相容欄位 = max(listedDate, otcDate)
  final String listedDate;  // TWSE 上市日期（民國年 YYYMMDD）
  final String otcDate;     // TPEX 上櫃日期（民國年 YYYMMDD）
  final int stockCount;
  final List<StockData> stocks;

  SyncResult({
    required this.success,
    required this.saved,
    required this.message,
    required this.date,
    required this.listedDate,
    required this.otcDate,
    required this.stockCount,
    required this.stocks,
  });
}

class SyncManager {
  final StorageService storageService;

  final MarketCalendarService calendarService;

  SyncManager({required this.storageService, required this.calendarService});

  /// [forceSync] 為 true 時完全略過 18:00 時間護欄（用於手動刷新）。
  Future<SyncResult> syncTodayData({bool forceSync = false}) async {
    try {
      // ── 時間護欄：18:00 前優先使用本地快照，但若資料超過 3 個日曆天則強制同步 ──
      // 台股收盤 13:30，TWSE/TPEX 資料通常 18:00 後才穩定。
      // 例外：連假後本地資料可能超過 3 天，此時即使未到 18:00 也必須強制取得新資料。
      // forceSync=true（手動刷新）時整段護欄跳過，直接向 API 取最新資料。
      final now = DateTime.now();
      if (!forceSync && now.hour < 18) {
        final localDate = await storageService.getLatestAvailableDate();
        if (localDate != null && localDate.isNotEmpty) {
          final localDt = _parseRocDate(localDate);
          final today = DateTime(now.year, now.month, now.day);
          final isStale = localDt == null || today.difference(localDt).inDays > 3;
          if (!isStale) {
            dev.log(
              '現在時間 ${now.hour}:${now.minute.toString().padLeft(2, '0')}，'
              '未達 18:00 且本地資料新鮮（$localDate），略過 API 同步',
              name: 'SyncManager',
            );
            final snapshot = await storageService.loadSnapshot(localDate);
            return SyncResult(
              success: true,
              saved: false,
              message: '未達 18:00，使用本地快照（$localDate）',
              date: localDate,
              listedDate: localDate,
              otcDate: localDate,
              stockCount: snapshot?.stocks.length ?? 0,
              stocks: snapshot?.stocks ?? [],
            );
          }
          dev.log(
            '本地資料超過 3 天（$localDate），18:00 前仍強制向 API 同步',
            name: 'SyncManager',
          );
        } else {
          dev.log('本地無快照，18:00 前仍需嘗試 API 同步', name: 'SyncManager');
        }
      }

      dev.log('開始同步今日股市資料', name: 'SyncManager');

      await StockService.loadMapping();

      dev.log('開始抓取上市資料', name: 'SyncManager');

      final listed = await StockService.fetchListed();

      final listedDate = StockService.lastListedDate;

      dev.log('上市資料筆數: ${listed.length}', name: 'SyncManager');

      dev.log('開始抓取上櫃資料', name: 'SyncManager');

      final otc = await StockService.fetchOTC();

      final otcDate = StockService.lastOtcDate;

      dev.log('上櫃資料筆數: ${otc.length}', name: 'SyncManager');

      if (listed.isEmpty && otc.isEmpty) {
        return SyncResult(
          success: false,
          saved: false,
          message: '上市與上櫃資料皆為空',
          date: '',
          listedDate: '',
          otcDate: '',
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
          listedDate: listedDate,
          otcDate: otcDate,
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

      // ── Rule 2：分市場 upsert，各自以正確日期存檔 ──────────────────────
      final effectiveListedDate = listedDate.isNotEmpty ? listedDate : latestDate;
      final effectiveOtcDate    = otcDate.isNotEmpty    ? otcDate    : latestDate;
      if (listed.isNotEmpty) {
        await storageService.saveListedSnapshot(
          StockDaySnapshot(date: effectiveListedDate, stocks: listed),
        );
      }
      if (otc.isNotEmpty) {
        await storageService.saveOtcSnapshot(
          StockDaySnapshot(date: effectiveOtcDate, stocks: otc),
        );
      }
      await storageService.pruneOldSnapshots(keepCount: 7);

      dev.log(
        isNewTradingDay
            ? '資料同步成功（新交易日）: $latestDate'
            : '已更新現有交易日資料: $latestDate',
        name: 'SyncManager',
      );

      return SyncResult(
        success: true,
        saved: true,
        message: isNewTradingDay ? '同步成功' : '已更新現有資料（$latestDate）',
        date: latestDate,
        listedDate: listedDate.isNotEmpty ? listedDate : latestDate,
        otcDate: otcDate.isNotEmpty ? otcDate : latestDate,
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
        listedDate: lastDate ?? '',
        otcDate: lastDate ?? '',
        stockCount: 0,
        stocks: [],
      );
    }
  }

  /// 民國年 YYYMMDD（7碼）→ [DateTime]；格式不符回傳 null。
  DateTime? _parseRocDate(String rocDate) {
    if (rocDate.length != 7) return null;
    final rocYear = int.tryParse(rocDate.substring(0, 3));
    final month   = int.tryParse(rocDate.substring(3, 5));
    final day     = int.tryParse(rocDate.substring(5, 7));
    if (rocYear == null || month == null || day == null) return null;
    return DateTime(rocYear + 1911, month, day);
  }

  String _resolveLatestDate({
    required String listedDate,
    required String otcDate,
  }) {
    if (listedDate.isEmpty && otcDate.isEmpty) return '';
    if (listedDate.isEmpty) return otcDate;
    if (otcDate.isEmpty) return listedDate;

    if (listedDate == otcDate) {
      dev.log('📅 上市上櫃日期一致: $listedDate', name: 'SyncManager');
      return listedDate;
    }

    // 兩個來源日期不同時，取「較新」的日期。
    // 原因：較新的日期代表至少有一個市場已更新到該交易日；
    // 取較舊的日期會導致另一個市場的新資料永遠被略過（本地已有舊日期 → isNewTradingDay=false）。
    // 實務上兩市場 API 更新時差通常在 1~2 小時以內，混合狀態屬可接受範圍。
    final newer = listedDate.compareTo(otcDate) > 0 ? listedDate : otcDate;
    dev.log(
      '📅 上市($listedDate)與上櫃($otcDate)日期不同步，採用較新日期: $newer',
      name: 'SyncManager',
    );
    return newer;
  }
}
