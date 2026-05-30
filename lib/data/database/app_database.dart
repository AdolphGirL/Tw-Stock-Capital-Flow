import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:tw_stock_capital_flow/data/database/tables/category_history_table.dart';

part 'package:tw_stock_capital_flow/data/database/app_database.g.dart';

@DriftDatabase(tables: [CategoryHistoryTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(p.join(dir.path, 'capital_flow.db'));

    return NativeDatabase(file);
  });
}
