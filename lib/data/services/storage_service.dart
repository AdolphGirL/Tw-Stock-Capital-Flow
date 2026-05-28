import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:tw_stock_capital_flow/core/constants/app_constants.dart';
import 'package:tw_stock_capital_flow/core/utils/date_utils.dart';
import 'package:tw_stock_capital_flow/data/models/stock_day_snapshot.dart';
import 'dart:developer' as dev;

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
}
