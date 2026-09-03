import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as dev; // 用於專業日誌
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';
import 'package:tw_stock_capital_flow/data/services/debug_log_service.dart'; // TODO(debug): 除錯用

class StockService {
  static final Map<String, Map<String, String>> _mapping = {};
  static String lastDataDate   = ""; // 相容保留：最後一次抓取的日期
  static String lastListedDate = ""; // TWSE 上市日期（民國年 YYYMMDD）
  static String lastOtcDate    = ""; // TPEX 上櫃日期（民國年 YYYMMDD）

  static Future<void> loadMapping() async {
    try {
      final String content = await rootBundle.loadString(
        'assets/stock_mapping.txt',
      );
      final lines = content.split('\n');
      dev.log('開始解析本地對應表...', name: 'StockService');

      for (var line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          _mapping[parts[1]] = {
            'market': parts[0],
            'main': parts[2],
            'sub': parts[3],
          };
        }
      }
      dev.log('對應表解析完成，共載入 ${_mapping.length} 筆對應資料', name: 'StockService');
    } catch (e) {
      dev.log('解析對應表失敗: $e', name: 'StockService', error: e);
    }
  }

  static Future<List<StockData>> fetchListed() async {
    dev.log('抓取上市資料中...', name: 'StockService');
    DebugLogService.log('上市', '開始抓取 fetchListed()');
    try {
      final data = await _fetchJsonWithRetry(
        'https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL'
        '?_=${DateTime.now().millisecondsSinceEpoch}', // 避免中間層/系統 HTTP 快取回傳舊回應
        marketTag: '上市',
      );

      if (data.isEmpty) {
        DebugLogService.log('上市', '⚠️ 回應為空清單（重試 3 次後仍失敗，或伺服器回傳空陣列）');
        return [];
      }

      if (data[0]['Date'] != null) {
        String rawDate = data[0]['Date'].toString();

        if (rawDate.length == 8) {
          int year = int.parse(rawDate.substring(0, 4));
          String monthDay = rawDate.substring(4);
          int rocYear = year - 1911;
          lastDataDate = "$rocYear$monthDay";
        } else {
          lastDataDate = rawDate;
        }
        lastListedDate = lastDataDate;
      }
      DebugLogService.log('上市', '回應原始日期欄位: ${data[0]['Date']}，換算後 lastListedDate=$lastListedDate');

      final filtered = data
          .where((item) {
            final String code = item['Code'] ?? '';
            return code.length == 4 && !code.startsWith('00');
          })
          .map((item) {
            final code = item['Code'];
            final map = _mapping[code];

            final close =
                double.tryParse(item['ClosingPrice']?.toString() ?? '') ?? 0;

            final change =
                double.tryParse(item['Change']?.toString() ?? '') ?? 0;

            final open =
                double.tryParse(item['OpeningPrice']?.toString() ?? '') ??
                close;

            final volume =
                int.tryParse(item['TradeVolume']?.toString() ?? '0') ?? 0;

            final value =
                int.tryParse(item['TradeValue']?.toString() ?? '0') ?? 0;

            // 昨日收盤 = 今日收盤 - 漲跌值；changePercent 必須除以昨日收盤才與 Yahoo 一致
            final prevClose = close - change;

            return StockData(
              code: code,
              name: item['Name'],
              market: MarketType.listed,
              mainCategory: map?['main'] ?? '其他',
              subCategory: map?['sub'] ?? '其他',
              open: open,
              high:
                  double.tryParse(item['HighestPrice']?.toString() ?? '') ?? 0,
              low: double.tryParse(item['LowestPrice']?.toString() ?? '') ?? 0,
              close: close,
              change: change,
              changePercent: prevClose != 0 ? (change / prevClose) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上市資料處理完成，${StockService.lastDataDate}，共 ${filtered.length} 檔',
        name: 'StockService',
      );
      DebugLogService.log(
        '上市',
        '✅ 完成：日期=$lastListedDate，篩選後共 ${filtered.length} 檔（原始 ${data.length} 筆）',
      );

      return filtered;
    } catch (e, stack) {
      dev.log(
        'fetchListed 發生例外',
        name: 'StockService',
        error: e,
        stackTrace: stack,
      );
      DebugLogService.log('上市', '❌ 例外（${e.runtimeType}）: $e');

      return [];
    }
  }

  static Future<List<StockData>> fetchOTC() async {
    dev.log('抓取上櫃資料中...', name: 'StockService');
    DebugLogService.log('上櫃', '開始抓取 fetchOTC()');
    try {
      final data = await _fetchJsonWithRetry(
        'https://www.tpex.org.tw/openapi/v1/tpex_mainboard_daily_close_quotes'
        '?_=${DateTime.now().millisecondsSinceEpoch}', // 避免中間層/系統 HTTP 快取回傳舊回應
        marketTag: '上櫃',
      );

      if (data.isEmpty) {
        DebugLogService.log('上櫃', '⚠️ 回應為空清單（重試 3 次後仍失敗，或伺服器回傳空陣列）');
        return [];
      }

      if (data[0]['Date'] != null) {
        String rawDate = data[0]['Date'].toString();

        if (rawDate.length == 8) {
          int year = int.parse(rawDate.substring(0, 4));
          String monthDay = rawDate.substring(4);
          int rocYear = year - 1911;
          lastDataDate = "$rocYear$monthDay";
        } else {
          lastDataDate = rawDate;
        }
        lastOtcDate = lastDataDate;
      }
      DebugLogService.log('上櫃', '回應原始日期欄位: ${data[0]['Date']}，換算後 lastOtcDate=$lastOtcDate');

      final filtered = data
          .where((item) {
            final String code = item['SecuritiesCompanyCode']?.toString() ?? '';

            return code.length == 4 && !code.startsWith('00');
          })
          .map((item) {
            final code = item['SecuritiesCompanyCode'];
            final map = _mapping[code];

            final close = double.tryParse(item['Close']?.toString() ?? '') ?? 0;

            final change =
                double.tryParse(
                  item['Change']?.toString().replaceAll('+', '').trim() ?? '0',
                ) ??
                0;

            final open =
                double.tryParse(item['Open']?.toString() ?? '') ?? close;

            final volume =
                int.tryParse(item['TradingShares']?.toString().trim() ?? '0') ??
                0;

            final value =
                int.tryParse(
                  item['TransactionAmount']?.toString().trim() ?? '0',
                ) ??
                0;

            // 昨日收盤 = 今日收盤 - 漲跌值；changePercent 必須除以昨日收盤才與 Yahoo 一致
            final prevClose = close - change;

            return StockData(
              code: code,
              name: item['CompanyName'],
              market: MarketType.otc,
              mainCategory: map?['main'] ?? '其他',
              subCategory: map?['sub'] ?? '其他',
              open: open,
              high: double.tryParse(item['High']?.toString() ?? '') ?? 0,
              low: double.tryParse(item['Low']?.toString() ?? '') ?? 0,
              close: close,
              change: change,
              changePercent: prevClose != 0 ? (change / prevClose) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上櫃資料處理完成，${StockService.lastDataDate}，共 ${filtered.length} 檔',
        name: 'StockService',
      );
      DebugLogService.log(
        '上櫃',
        '✅ 完成：日期=$lastOtcDate，篩選後共 ${filtered.length} 檔（原始 ${data.length} 筆）',
      );

      return filtered;
    } catch (e, stack) {
      dev.log(
        'fetchOTC 發生例外',
        name: 'StockService',
        error: e,
        stackTrace: stack,
      );
      DebugLogService.log('上櫃', '❌ 例外（${e.runtimeType}）: $e');

      return [];
    }
  }

  static Future<List<dynamic>> _fetchJsonWithRetry(
    String url, {
    int maxRetry = 3,
    String marketTag = '',
  }) async {
    final client = http.Client();
    final tag = marketTag.isNotEmpty ? marketTag : 'StockService';

    try {
      for (int attempt = 1; attempt <= maxRetry; attempt++) {
        final attemptStart = DateTime.now();
        try {
          dev.log('開始請求 [$attempt/$maxRetry] $url', name: 'StockService');
          DebugLogService.log(tag, '請求 [$attempt/$maxRetry]…');

          final request = http.Request('GET', Uri.parse(url))
            ..headers['Cache-Control'] = 'no-cache'
            ..headers['Pragma'] = 'no-cache';

          // 上櫃等大型回應（上萬筆、數 MB）在較慢的行動網路下可能長時間卡住；
          // 原本完全沒有逾時保護，卡住的連線會拖到重試機制失去意義。
          // 每次嘗試最多等 20 秒，逾時就視為本次失敗、盡快進入下一次重試。
          final streamedResponse =
              await client.send(request).timeout(const Duration(seconds: 20));

          if (streamedResponse.statusCode == 200) {
            final responseBody = await streamedResponse.stream
                .bytesToString()
                .timeout(const Duration(seconds: 20));

            final elapsedMs = DateTime.now().difference(attemptStart).inMilliseconds;
            final decoded = json.decode(responseBody);

            if (decoded is List<dynamic>) {
              dev.log('請求成功，共 ${decoded.length} 筆', name: 'StockService');
              DebugLogService.log(
                tag,
                '[$attempt/$maxRetry] HTTP 200，耗時 ${elapsedMs}ms，共 ${decoded.length} 筆',
              );
              return decoded;
            }

            dev.log('資料格式異常，不是 List', name: 'StockService');
            DebugLogService.log(tag, '[$attempt/$maxRetry] ⚠️ 回應格式異常，不是 List');

            return [];
          }

          dev.log(
            'HTTP Error: ${streamedResponse.statusCode}',
            name: 'StockService',
          );
          DebugLogService.log(tag, '[$attempt/$maxRetry] ❌ HTTP ${streamedResponse.statusCode}');
        } catch (e, stack) {
          // 記錄實際錯誤類型與內容（例如 TimeoutException、SocketException），
          // 方便日後對照使用者回報的失敗時間點，診斷是逾時、斷線還是伺服器錯誤。
          final elapsedMs = DateTime.now().difference(attemptStart).inMilliseconds;
          dev.log(
            '第 $attempt 次請求失敗（${e.runtimeType}）: $e',
            name: 'StockService',
            error: e,
            stackTrace: stack,
          );
          DebugLogService.log(
            tag,
            '[$attempt/$maxRetry] ❌ ${e.runtimeType} after ${elapsedMs}ms: $e',
          );
        }

        if (attempt < maxRetry) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }

      dev.log('重試 $maxRetry 次後仍失敗：$url', name: 'StockService');
      DebugLogService.log(tag, '❌❌ 重試 $maxRetry 次後仍失敗，本次回傳空清單');

      return [];
    } finally {
      client.close();
    }
  }
}
