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
    final response = await http.get(
      Uri.parse('https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty && data[0]['Date'] != null) {
        String rawDate = data[0]['Date'].toString(); // 假設為 "20260227"
        if (rawDate.length == 8) {
          int year = int.parse(rawDate.substring(0, 4));
          String monthDay = rawDate.substring(4);
          int rocYear = year - 1911; // 西元轉民國
          lastDataDate = "$rocYear$monthDay"; // 結果為 "1150227"
        } else {
          lastDataDate = rawDate;
        }
      }

      // 修正過濾邏輯：長度為 4 且 非 00 開頭
      final filtered = data
          .where((item) {
            final String code = item['Code'] ?? '';
            return code.length == 4 && !code.startsWith('00');
          })
          .map((item) {
            final code = item['Code'];
            final map = _mapping[code];
            final close = double.tryParse(item['ClosingPrice']) ?? 0;
            final change = double.tryParse(item['Change']) ?? 0;
            final open = double.tryParse(item['OpeningPrice']) ?? close;
            final volume = int.tryParse(item['TradeVolume'] ?? '0') ?? 0;
            final value = int.tryParse(item['TradeValue'] ?? '0') ?? 0;

            return StockData(
              code: code,
              name: item['Name'],
              market: MarketType.listed,
              mainCategory: map?['main'] ?? '其他',
              subCategory: map?['sub'] ?? '其他', // 確保細分類被正確帶入
              open: open,
              high: double.tryParse(item['HighestPrice']) ?? 0,
              low: double.tryParse(item['LowestPrice']) ?? 0,
              close: close,
              change: change,
              changePercent: open != 0 ? (change / open) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上市資料處理完成，${StockService.lastDataDate}，過濾後共 ${filtered.length} 檔',
        name: 'StockService',
      );
      return filtered;
    }
    return [];
  }

  static Future<List<StockData>> fetchOTC() async {
    dev.log('抓取上櫃資料中...', name: 'StockService');
    final response = await http.get(
      Uri.parse(
        'https://www.tpex.org.tw/openapi/v1/tpex_mainboard_daily_close_quotes',
      ),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty && data[0]['Date'] != null) {
        String rawDate = data[0]['Date'].toString(); // 假設為 "20260227"
        if (rawDate.length == 8) {
          int year = int.parse(rawDate.substring(0, 4));
          String monthDay = rawDate.substring(4);
          int rocYear = year - 1911; // 西元轉民國
          lastDataDate = "$rocYear$monthDay"; // 結果為 "1150227"
        } else {
          lastDataDate = rawDate;
        }
      }

      // 修正過濾邏輯：長度為 4 且 非 00 開頭
      final filtered = data
          .where((item) {
            final String code = item['SecuritiesCompanyCode'] ?? '';
            return code.length == 4 && !code.startsWith('00');
          })
          .map((item) {
            final code = item['SecuritiesCompanyCode'];
            final map = _mapping[code];
            final close = double.tryParse(item['Close']) ?? 0;
            final change =
                double.tryParse(
                  item['Change']?.toString().replaceAll('+', '').trim() ?? '0',
                ) ??
                0;
            final open = double.tryParse(item['Open']) ?? close;
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
              subCategory: map?['sub'] ?? '其他', // 確保細分類被正確帶入
              open: open,
              high: double.tryParse(item['High']) ?? 0,
              low: double.tryParse(item['Low']) ?? 0,
              close: close,
              change: change,
              changePercent: open != 0 ? (change / open) * 100 : 0,
              volume: volume,
              value: value,
            );
          })
          .toList();

      dev.log(
        '上櫃資料處理完成，${StockService.lastDataDate}，過濾後共 ${filtered.length} 檔',
        name: 'StockService',
      );
      return filtered;
    }
    return [];
  }
}
