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

      // 決定這筆要合併哪個上櫃日期：
      // - i==0（目前顯示在畫面上的那一份快照）優先判斷「上櫃是否比上市新」——
      //   上櫃收盤資料公告時間通常早於上市（上市開放 API 常常隔天才有當日資料），
      //   若這裡只做「同日期比對」，上市還停在昨天時，會因為「昨天剛好也有上櫃
      //   檔案」而誤判成同日期可用，於是繼續合併昨天的上櫃資料——上櫃日期標籤
      //   看起來正確（來自 SyncManager 回傳值，與這裡無關），但個股清單、板塊
      //   分數全部還是昨天的上櫃資料，且完全抓到的「今天」上櫃檔案沒被用上。
      // - 其餘情況（含 i>0 的歷史列）沿用舊邏輯：找同日期，找不到才退回最新一筆。
      final otcDateMatched = otcDates.contains(ld);
      String? otcDate;
      if (i == 0 && otcDates.isNotEmpty && otcDates.first.compareTo(ld) > 0) {
        otcDate = otcDates.first;
      } else if (otcDateMatched) {
        otcDate = ld;
      } else {
        otcDate = otcDates.isNotEmpty ? otcDates.first : null;
      }
      final otcSnap = otcDate != null ? await storageService.loadOtcSnapshot(otcDate) : null;

      // i==0 且上市/上櫃最終合併的日期對不上時提出警告，涵蓋「上櫃落後上市」
      // 與「上櫃領先上市」兩種方向（原本只偵測前者，後者完全沒有警告）。
      if (i == 0 && otcDate != ld) {
        DebugLogService.log(
          'History',
          '⚠️ 最新一筆(listed=$ld)與實際採用的上櫃快照(otc=$otcDate)日期不同，'
          '個股清單改用上櫃 $otcDate（可能導致上市/上櫃個股顯示非同一交易日資料）',
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
