import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as dev; // 用於專業日誌
import 'package:tw_stock_capital_flow/data/models/stock_data.dart';

class StockService {
  static final Map<String, Map<String, String>> _mapping = {};
  static String lastDataDate = ""; // 新增：記錄最後一次抓取的日期

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
    try {
      final data = await _fetchJsonWithRetry(
        'https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL',
      );

      if (data.isEmpty) {
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
      }

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
              changePercent: open != 0 ? (change / open) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上市資料處理完成，${StockService.lastDataDate}，共 ${filtered.length} 檔',
        name: 'StockService',
      );

      return filtered;
    } catch (e, stack) {
      dev.log(
        'fetchListed 發生例外',
        name: 'StockService',
        error: e,
        stackTrace: stack,
      );

      return [];
    }
  }

  static Future<List<StockData>> fetchOTC() async {
    dev.log('抓取上櫃資料中...', name: 'StockService');
    try {
      final data = await _fetchJsonWithRetry(
        'https://www.tpex.org.tw/openapi/v1/tpex_mainboard_daily_close_quotes',
      );

      if (data.isEmpty) {
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
      }

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
              changePercent: open != 0 ? (change / open) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上櫃資料處理完成，${StockService.lastDataDate}，共 ${filtered.length} 檔',
        name: 'StockService',
      );

      return filtered;
    } catch (e, stack) {
      dev.log(
        'fetchOTC 發生例外',
        name: 'StockService',
        error: e,
        stackTrace: stack,
      );

      return [];
    }
  }

  static Future<List<dynamic>> _fetchJsonWithRetry(
    String url, {
    int maxRetry = 3,
  }) async {
    final client = http.Client();

    try {
      for (int attempt = 1; attempt <= maxRetry; attempt++) {
        try {
          dev.log('開始請求 [$attempt/$maxRetry] $url', name: 'StockService');

          final request = http.Request('GET', Uri.parse(url));

          final streamedResponse = await client.send(request);

          if (streamedResponse.statusCode == 200) {
            final responseBody = await streamedResponse.stream.bytesToString();

            final decoded = json.decode(responseBody);

            if (decoded is List<dynamic>) {
              dev.log('請求成功，共 ${decoded.length} 筆', name: 'StockService');
              return decoded;
            }

            dev.log('資料格式異常，不是 List', name: 'StockService');

            return [];
          }

          dev.log(
            'HTTP Error: ${streamedResponse.statusCode}',
            name: 'StockService',
          );
        } catch (e, stack) {
          dev.log(
            '第 $attempt 次請求失敗',
            name: 'StockService',
            error: e,
            stackTrace: stack,
          );
        }

        if (attempt < maxRetry) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }

      dev.log('重試 $maxRetry 次後仍失敗：$url', name: 'StockService');

      return [];
    } finally {
      client.close();
    }
  }
}
