import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tw_stock_capital_flow/domain/models/margin_trading_result.dart';

class MarginTradingService {
  /// 查詢最新一筆集中市場（上市）信用交易統計（融資融券餘額）。
  ///
  /// 不帶 date 參數，由 TWSE 自行回傳最新可用資料；實際日期以回應中的
  /// `date` 欄位為準（不自行猜測／回溯日期）。
  /// 若 API 不可用或解析失敗，回傳 null。
  static Future<MarginTradingResult?> fetchLatest() => _fetch(null);

  /// 查詢指定交易日（YYYYMMDD）的信用交易統計；非交易日或解析失敗回傳 null。
  static Future<MarginTradingResult?> fetchForDate(String dateKey) {
    if (dateKey.length != 8) return Future.value(null);
    return _fetch(dateKey);
  }

  static Future<MarginTradingResult?> _fetch(String? dateKey) async {
    try {
      final params = <String, String>{
        'response': 'json',
        'selectType': 'MS', // 信用交易統計（大盤）
        '_': DateTime.now().millisecondsSinceEpoch.toString(), // 避免快取
      };
      if (dateKey != null) params['date'] = dateKey;

      final uri = Uri.https(
        'www.twse.com.tw',
        '/rwd/zh/marginTrading/MI_MARGN',
        params,
      );

      final response = await http
          .get(uri, headers: {
            'Accept': 'application/json, text/plain, */*',
            'Referer': 'https://www.twse.com.tw/zh/trading/exchange/MI_MARGN.html',
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
          })
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> jsonBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (jsonBody['stat'] != 'OK') return null;

      // 實際資料日期一律以回應內容為準，不沿用呼叫端傳入的 dateKey
      // （避免「回報日期跟實際資料不一致」的問題，參考 SyncManager 曾發生過的教訓）。
      final actualDate = jsonBody['date'] as String?;
      if (actualDate == null || actualDate.length != 8) return null;

      final tables = jsonBody['tables'] as List<dynamic>? ?? [];
      if (tables.isEmpty) return null;

      final rawRows = (tables[0] as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      final rows = rawRows.whereType<List<dynamic>>().toList();

      // ── 找出所需各行（項目、買進、賣出、現金(券)償還、前日餘額、今日餘額）─────
      final rowMargin      = _row(rows, (s) => s.contains('融資') && s.contains('交易單位'));
      final rowShortSale   = _row(rows, (s) => s.contains('融券') && s.contains('交易單位'));
      final rowMarginValue = _row(rows, (s) => s.contains('融資金額'));

      if (rowMargin == null || rowShortSale == null || rowMarginValue == null) {
        return null;
      }

      final margin = MarginEntry(
        name: '融資',
        buyLots: _num(rowMargin[1]),
        sellLots: _num(rowMargin[2]),
        redemptionLots: _num(rowMargin[3]),
        prevBalanceLots: _num(rowMargin[4]),
        todayBalanceLots: _num(rowMargin[5]),
      );

      final shortSale = MarginEntry(
        name: '融券',
        buyLots: _num(rowShortSale[1]),
        sellLots: _num(rowShortSale[2]),
        redemptionLots: _num(rowShortSale[3]),
        prevBalanceLots: _num(rowShortSale[4]),
        todayBalanceLots: _num(rowShortSale[5]),
      );

      // 融資金額單位為「仟元」，換算成億元：raw(仟元) × 1000 ÷ 1億 = raw ÷ 100000
      final marginValuePrevYi  = _num(rowMarginValue[4]) / 100000.0;
      final marginValueTodayYi = _num(rowMarginValue[5]) / 100000.0;

      return MarginTradingResult(
        date: actualDate,
        margin: margin,
        shortSale: shortSale,
        marginBalanceValueYi: marginValueTodayYi,
        marginBalanceValueChangeYi: marginValueTodayYi - marginValuePrevYi,
      );
    } catch (_) {
      return null;
    }
  }

  // ── 內部工具 ───────────────────────────────────────────────────────────────

  static List<dynamic>? _row(
    List<List<dynamic>> rows,
    bool Function(String) test,
  ) {
    try {
      return rows.firstWhere((r) => r.isNotEmpty && test(r[0].toString()));
    } catch (_) {
      return null;
    }
  }

  /// "345,253" → 345253.0
  static double _num(dynamic raw) {
    final cleaned = raw.toString().replaceAll(',', '').replaceAll('+', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
