import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:tw_stock_capital_flow/core/constants/app_constants.dart';
import 'package:tw_stock_capital_flow/core/utils/date_utils.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<Directory> _getDailyDirectory() async {
    final root = await getApplicationDocumentsDirectory();

    final dailyPath = path.join(root.path, AppConstants.dailyFolder);

    final dir = Directory(dailyPath);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  Future<String> _buildFilePath(String date) async {
    final dir = await _getDailyDirectory();

    return path.join(dir.path, '$date.json');
  }

  Future<bool> exists(String date) async {
    final filePath = await _buildFilePath(date);

    return File(filePath).exists();
  }

  Future<void> saveDailySnapshot(StockDaySnapshot snapshot) async {
    final alreadyExists = await exists(snapshot.date);
    dev.log('日期: ${snapshot.date}，檔案是否存在: $alreadyExists');
    if (alreadyExists) {
      return;
    }

    final filePath = await _buildFilePath(snapshot.date);
    dev.log('日期: ${snapshot.date}，建構檔案路徑: $filePath');

    final file = File(filePath);

    final jsonString = jsonEncode(snapshot.toJson());

    await file.writeAsString(jsonString);
  }

  Future<StockDaySnapshot?> loadSnapshot(String date) async {
    final filePath = await _buildFilePath(date);

    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();

    final jsonData = jsonDecode(content);

    return StockDaySnapshot.fromJson(jsonData);
  }

  /// 取得本地最新可用的交易日期（按日期由新到舊排序）
  Future<String?> getLatestAvailableDate() async {
    try {
      final dates = await listAvailableDates();

      if (dates.isEmpty) {
        return null;
      }

      // 確保日期是字串格式 YYYYMMDD，先排序再取最新
      dates.sort((a, b) => b.compareTo(a)); // 降序：最新的在前面

      return dates.first;
    } catch (e) {
      dev.log('取得最新可用日期失敗: $e', name: 'StorageService', error: e);
      return null;
    }
  }

  Future<List<String>> listAvailableDates() async {
    final dir = await _getDailyDirectory();

    final files = dir.listSync();

    final dates = files
        .whereType<File>()
        .map((e) => path.basenameWithoutExtension(e.path))
        .toList();

    return AppDateUtils.sortDesc(dates);
  }

  Future<String> buildCustomFilePath(String filename) async {
    final dir = await _getDailyDirectory();

    return path.join(dir.path, filename);
  }

  Future<void> writeFile(String filename, String content) async {
    final filePath = await buildCustomFilePath(filename);

    final file = File(filePath);

    await file.writeAsString(content);
  }

  Future<String?> readFile(String filename) async {
    final filePath = await buildCustomFilePath(filename);

    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    return await file.readAsString();
  }

  Future<void> writeJson(String filename, Map<String, dynamic> json) async {
    await writeFile(filename, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> readJson(String filename) async {
    final content = await readFile(filename);

    if (content == null) {
      return null;
    }

    return jsonDecode(content);
  }

  // ── 分級保留清理 ─────────────────────────────────────────────────────────

  /// 保留最近 [keepCount] 筆原始快照（YYYYMMDD.json），刪除更舊的檔案。
  /// 計算引擎只需 5 天；保留 7 天提供週末 / 補假緩衝，固定佔用約 3.5–7 MB。
  Future<void> pruneOldSnapshots({int keepCount = 7}) async {
    try {
      final dir = await _getDailyDirectory();
      final allFiles = dir.listSync().whereType<File>().toList();

      // 只針對純日期格式檔案 (YYYYMMDD.json)，不觸碰快取或其他檔案
      final datePattern = RegExp(r'^\d{8}$');
      final dateFiles = allFiles
          .where(
            (f) => datePattern.hasMatch(path.basenameWithoutExtension(f.path)),
          )
          .toList();

      if (dateFiles.length <= keepCount) return;

      // 依檔名（即日期字串）降序排列，最新的在前
      dateFiles.sort(
        (a, b) => path
            .basenameWithoutExtension(b.path)
            .compareTo(path.basenameWithoutExtension(a.path)),
      );

      final toDelete = dateFiles.skip(keepCount).toList();
      for (final file in toDelete) {
        await file.delete();
        dev.log(
          '🗑️ 已清理舊快照: ${path.basename(file.path)}',
          name: 'StorageService',
        );
      }
      dev.log(
        '快照清理完成，保留最近 $keepCount 天，刪除 ${toDelete.length} 筆',
        name: 'StorageService',
      );
    } catch (e) {
      dev.log('快照清理失敗（不影響主流程）: $e', name: 'StorageService', error: e);
    }
  }

  /// 保留最近 [keepCount] 份分析結果快取（bootstrap_cache_*.json），刪除更舊的。
  /// 離線防禦模式需 1 份；保留 3 份覆蓋連假斷線情境，固定佔用約 150–300 KB。
  Future<void> pruneOldBootstrapCaches({int keepCount = 3}) async {
    try {
      final dir = await _getDailyDirectory();
      final allFiles = dir.listSync().whereType<File>().toList();

      final cacheFiles = allFiles
          .where(
            (f) => path.basename(f.path).startsWith('bootstrap_cache_'),
          )
          .toList();

      if (cacheFiles.length <= keepCount) return;

      // 依檔名降序（日期在 prefix 之後），最新的在前
      cacheFiles.sort(
        (a, b) => path.basename(b.path).compareTo(path.basename(a.path)),
      );

      final toDelete = cacheFiles.skip(keepCount).toList();
      for (final file in toDelete) {
        await file.delete();
        dev.log(
          '🗑️ 已清理舊快取: ${path.basename(file.path)}',
          name: 'StorageService',
        );
      }
      dev.log(
        '快取清理完成，保留最近 $keepCount 份，刪除 ${toDelete.length} 筆',
        name: 'StorageService',
      );
    } catch (e) {
      dev.log('快取清理失敗（不影響主流程）: $e', name: 'StorageService', error: e);
    }
  }

  // ── SharedPreferences 輔助 ────────────────────────────────────────────────

  /// 🚀 獲取目前本地儲存的所有快取 Key
  Future<List<String>> getAllKeys() async {
    try {
      // 1. 在方法內部直接獲取原生實體，100% 免疫欄位未定義錯誤
      final SharedPreferences prefsInstance =
          await SharedPreferences.getInstance();

      // 2. 呼叫原生 getKeys() 並轉為 List 丢出
      return prefsInstance.getKeys().toList();
    } catch (e) {
      dev.log('❌ [StorageService] 獲取全部 Keys 失敗: $e');
      return [];
    }
  }
}
