import 'dart:convert';

import 'package:tw_stock_capital_flow/services/storage_service.dart';

class AnalysisCacheService {
  final StorageService storageService;

  AnalysisCacheService({required this.storageService});

  Future<void> save(String date, Map<String, dynamic> json) async {
    await storageService.writeJson('analysis_$date.json', json);
  }

  Future<Map<String, dynamic>?> load(String date) async {
    return await storageService.readJson('analysis_$date.json');
  }
}
