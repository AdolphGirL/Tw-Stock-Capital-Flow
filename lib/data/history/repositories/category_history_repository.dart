import 'dart:developer' as dev;

import 'package:tw_stock_capital_flow/data/database/app_database.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';
import 'package:tw_stock_capital_flow/domain/models/mainstream_result.dart';
import 'package:tw_stock_capital_flow/domain/models/lifecycle_result.dart';
import 'package:tw_stock_capital_flow/data/models/rotation_result.dart';
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

  /// 取出近 [days] 個自然日內所有板塊的歷史，以板塊名稱分組回傳。
  /// 用於異常資金偵測：一次查詢，避免 N 個板塊各別發 query。
  Future<Map<String, List<CategoryHistoryData>>> loadAllCategoriesHistory({
    int days = 35,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = '${cutoff.year}'
        '${cutoff.month.toString().padLeft(2, '0')}'
        '${cutoff.day.toString().padLeft(2, '0')}';

    final rows = await (db.select(db.categoryHistoryTable)
          ..where((t) => t.tradeDate.isBiggerOrEqualValue(cutoffStr))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.tradeDate,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();

    final Map<String, List<CategoryHistoryData>> grouped = {};
    for (final r in rows) {
      grouped.putIfAbsent(r.categoryName, () => []).add(r);
    }
    return grouped;
  }

  /// 刪除四張歷史表中超過 [keepDays] 天的舊紀錄（在一個事務內完成）。
  ///
  /// tradeDate 欄位為 YYYYMMDD 字串，字典序等同時間序，可直接做字串比較。
  /// 每次新交易日資料存入後呼叫，保持 SQLite 在合理大小（上限約 40–80 MB）。
  Future<void> pruneOldHistory({int keepDays = 365}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: keepDays));
      final cutoffStr = '${cutoff.year}'
          '${cutoff.month.toString().padLeft(2, '0')}'
          '${cutoff.day.toString().padLeft(2, '0')}';

      int totalDeleted = 0;

      await db.transaction(() async {
        totalDeleted += await (db.delete(db.categoryHistoryTable)
              ..where((t) => t.tradeDate.isSmallerThan(Variable<String>(cutoffStr))))
            .go();

        totalDeleted += await (db.delete(db.mainstreamHistoryTable)
              ..where((t) => t.tradeDate.isSmallerThan(Variable<String>(cutoffStr))))
            .go();

        totalDeleted += await (db.delete(db.lifecycleHistoryTable)
              ..where((t) => t.tradeDate.isSmallerThan(Variable<String>(cutoffStr))))
            .go();

        totalDeleted += await (db.delete(db.rotationHistoryTable)
              ..where((t) => t.tradeDate.isSmallerThan(Variable<String>(cutoffStr))))
            .go();
      });

      dev.log(
        'SQLite 歷史清理完成，cutoff=$cutoffStr，共刪除 $totalDeleted 筆舊紀錄',
        name: 'CategoryHistoryRepository',
      );
    } catch (e) {
      dev.log(
        'SQLite 歷史清理失敗（不影響主流程）: $e',
        name: 'CategoryHistoryRepository',
        error: e,
      );
    }
  }

  /// 儲存每日完整的板塊快照至 SQLite（每次啟動有新交易日資料時呼叫）。
  /// 使用強型別參數，避免 dynamic 欄位存取錯誤。
  Future<void> saveDailySnapshot({
    required String dateKey,
    required List<CategoryUiModel> categories,
    required List<MainstreamResult> mainstreams,
    required List<LifecycleResult> lifecycles,
    required List<RotationResult> rotations,
  }) async {
    await db.transaction(() async {
      // 1. 板塊每日指標 (category_history) — 儲存上市 + 上櫃所有主板塊
      for (final cat in categories) {
        await db.into(db.categoryHistoryTable).insertOnConflictUpdate(
          CategoryHistoryTableCompanion.insert(
            tradeDate: dateKey,
            categoryName: cat.name,
            score: cat.score,
            hotScore: cat.hotScore,
            persistence: cat.persistence,
            trendStrength: cat.trendStrength,
            riseCount: cat.riseCount,
            fallCount: cat.fallCount,
            totalCount: cat.totalCount,
          ),
        );
      }

      // 2. 主流排行 (mainstream_history)
      for (int i = 0; i < mainstreams.length; i++) {
        final ms = mainstreams[i];
        await db.into(db.mainstreamHistoryTable).insertOnConflictUpdate(
          MainstreamHistoryTableCompanion.insert(
            tradeDate: dateKey,
            categoryName: ms.category,
            rankNo: i + 1,
            score: ms.mainstreamScore,
          ),
        );
      }

      // 3. 生命週期階段 (lifecycle_history)
      for (final lc in lifecycles) {
        await db.into(db.lifecycleHistoryTable).insertOnConflictUpdate(
          LifecycleHistoryTableCompanion.insert(
            tradeDate: dateKey,
            categoryName: lc.category,
            stage: lc.stage.name,
          ),
        );
      }

      // 4. 資金輪動 (rotation_history)
      for (final rt in rotations) {
        await db.into(db.rotationHistoryTable).insertOnConflictUpdate(
          RotationHistoryTableCompanion.insert(
            tradeDate: dateKey,
            fromCategory: rt.fromCategory,
            toCategory: rt.toCategory,
            score: rt.score,
          ),
        );
      }
    });

    dev.log(
      'SQLite 歷史快照已寫入：dateKey=$dateKey，板塊=${categories.length}，'
      '主流=${mainstreams.length}，生命週期=${lifecycles.length}，輪動=${rotations.length}',
      name: 'CategoryHistoryRepository',
    );
  }
}
