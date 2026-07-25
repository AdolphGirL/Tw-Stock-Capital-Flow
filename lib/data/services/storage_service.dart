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

  // ── 快照存取（原始格式保留供向下相容）────────────────────────────────────

  Future<void> saveDailySnapshot(StockDaySnapshot snapshot) async {
    final filePath = await _buildFilePath(snapshot.date);
    dev.log('儲存快照: ${snapshot.date}', name: 'StorageService');
    final file = File(filePath);
    final jsonString = jsonEncode(snapshot.toJson());
    await file.writeAsString(jsonString);
  }

  // ── 分市場存取（新格式：listed_YYYMMDD / otc_YYYMMDD）─────────────────

  Future<void> saveListedSnapshot(StockDaySnapshot snapshot) async {
    final filePath = await _buildFilePath('listed_${snapshot.date}');
    dev.log('儲存上市快照: listed_${snapshot.date}', name: 'StorageService');
    await File(filePath).writeAsString(jsonEncode(snapshot.toJson()));
  }

  Future<void> saveOtcSnapshot(StockDaySnapshot snapshot) async {
    final filePath = await _buildFilePath('otc_${snapshot.date}');
    dev.log('儲存上櫃快照: otc_${snapshot.date}', name: 'StorageService');
    await File(filePath).writeAsString(jsonEncode(snapshot.toJson()));
  }

  Future<StockDaySnapshot?> loadListedSnapshot(String date) async {
    return await _loadSnapshotFromFile('listed_$date');
  }

  Future<StockDaySnapshot?> loadOtcSnapshot(String date) async {
    return await _loadSnapshotFromFile('otc_$date');
  }

  /// 從指定 fileKey 讀取快照（不含副檔名）。
  Future<StockDaySnapshot?> _loadSnapshotFromFile(String fileKey) async {
    try {
      final filePath = await _buildFilePath(fileKey);
      final file = File(filePath);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return StockDaySnapshot.fromJson(jsonDecode(content));
    } catch (e) {
      dev.log('loadSnapshot 解析失敗($fileKey)，已略過: $e', name: 'StorageService');
      return null;
    }
  }

  /// 讀取快照：優先嘗試新格式（listed_+otc_），若不存在則回退舊格式（YYYMMDD）。
  Future<StockDaySnapshot?> loadSnapshot(String date) async {
    final listed = await _loadSnapshotFromFile('listed_$date');
    if (listed != null) {
      final otc = await _loadSnapshotFromFile('otc_$date');
      final merged = [...listed.stocks, ...?otc?.stocks];
      return StockDaySnapshot(date: date, stocks: merged);
    }
    return await _loadSnapshotFromFile(date);
  }

  /// 取得已知的上市（listed_）日期清單（降序）。
  Future<List<String>> listListedDates() async {
    final all = await listAvailableDates();
    final pattern = RegExp(r'^listed_(\d{7,8})$');
    return all
        .where((d) => pattern.hasMatch(d))
        .map((d) => pattern.firstMatch(d)!.group(1)!)
        .toList();
  }

  /// 取得已知的上櫃（otc_）日期清單（降序）。
  Future<List<String>> listOtcDates() async {
    final all = await listAvailableDates();
    final pattern = RegExp(r'^otc_(\d{7,8})$');
    return all
        .where((d) => pattern.hasMatch(d))
        .map((d) => pattern.firstMatch(d)!.group(1)!)
        .toList();
  }

  /// 取得本地最新可用的交易日期（按日期由新到舊排序）。
  /// 同時識別舊格式（YYYMMDD）與新格式（listed_YYYMMDD）。
  Future<String?> getLatestAvailableDate() async {
    try {
      final all = await listAvailableDates();

      final oldPattern = RegExp(r'^\d{7,8}$');
      final newPattern = RegExp(r'^listed_(\d{7,8})$');

      final dates = <String>{};
      for (final d in all) {
        if (oldPattern.hasMatch(d)) dates.add(d);
        final m = newPattern.firstMatch(d);
        if (m != null) dates.add(m.group(1)!);
      }

      if (dates.isEmpty) return null;

      final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
      return sorted.first;
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

  /// 保留最近 [keepCount] 筆快照，刪除更舊的檔案。
  /// 同時處理三種格式：舊版 YYYMMDD、新版 listed_YYYMMDD、otc_YYYMMDD。
  Future<void> pruneOldSnapshots({int keepCount = 7}) async {
    try {
      final dir = await _getDailyDirectory();
      final allFiles = dir.listSync().whereType<File>().toList();

      void pruneGroup(RegExp groupPattern) {
        final group = allFiles
            .where((f) => groupPattern.hasMatch(path.basenameWithoutExtension(f.path)))
            .toList();
        if (group.length <= keepCount) return;
        group.sort((a, b) => path
            .basenameWithoutExtension(b.path)
            .compareTo(path.basenameWithoutExtension(a.path)));
        final toDelete = group.skip(keepCount).toList();
        for (final f in toDelete) {
          f.deleteSync();
          dev.log('🗑️ 已清理舊快照: ${path.basename(f.path)}', name: 'StorageService');
        }
      }

      pruneGroup(RegExp(r'^\d{7,8}$'));           // 舊格式
      pruneGroup(RegExp(r'^listed_\d{7,8}$'));    // 新格式 listed
      pruneGroup(RegExp(r'^otc_\d{7,8}$'));       // 新格式 otc

      dev.log('快照清理完成（三組各保留最近 $keepCount 筆）', name: 'StorageService');
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
