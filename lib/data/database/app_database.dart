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
import 'package:tw_stock_capital_flow/data/database/tables/watchlist_table.dart';
import 'package:tw_stock_capital_flow/data/database/tables/signal_snapshot_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CategoryHistoryTable,
    MainstreamHistoryTable, // V2 新增
    LifecycleHistoryTable, // V3 新增
    RotationHistoryTable, // V3 新增
    WatchlistTable, // V4 新增
    SignalSnapshotTable, // V5 新增
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(mainstreamHistoryTable);
      }
      if (from < 3) {
        await m.createTable(lifecycleHistoryTable);
        await m.createTable(rotationHistoryTable);
      }
      if (from < 4) {
        await m.createTable(watchlistTable);
      }
      if (from < 5) {
        await m.createTable(signalSnapshotTable);
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
