import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tw_stock_capital_flow/domain/models/institutional_flow_result.dart';

class InstitutionalFlowService {
  /// 查詢指定交易日三大法人買賣超（億元）。
  ///
  /// [dateKey] 格式為 YYYYMMDD，例如 '20260703'。
  /// 若 API 不可用、非交易日或解析失敗，回傳 null。
  static Future<InstitutionalFlowResult?> fetchForDate(
      String dateKey) async {
    if (dateKey.length != 8) return null;

    try {
      final weekDate = _mondayOf(dateKey);
      final ts = DateTime.now().millisecondsSinceEpoch;

      final uri = Uri.https(
        'www.twse.com.tw',
        '/rwd/zh/fund/BFI82U',
        {
          'type': 'day',
          'dayDate': dateKey,
          'weekDate': weekDate,
          'monthDate': '',
          'response': 'json',
          '_': ts.toString(),
        },
      );

      final response = await http
          .get(uri, headers: {
            'Accept': 'application/json, text/plain, */*',
            'Referer':
                'https://www.twse.com.tw/zh/trading/fund/BFI82U.html',
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
          })
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> jsonBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (jsonBody['stat'] != 'OK') return null;

      // 逐元素安全轉換，避免 lazy cast 在非預期格式下拋出 CastError
      final rawList = jsonBody['data'] as List<dynamic>? ?? [];
      final rows = rawList
          .whereType<List<dynamic>>()
          .toList();

      // ── 找出所需各行 ──────────────────────────────────────────────────────
      // 外資及陸資(不含外資自營商)
      final rowForeignMain   = _row(rows, (s) => s.contains('外資及陸資'));
      // 外資自營商（可能全為 0，允許缺失）
      final rowForeignDealer = _row(rows, (s) => s.trim() == '外資自營商');
      // 投信
      final rowTrust         = _row(rows, (s) => s.trim() == '投信');
      // 自營商(自行買賣)
      final rowDealerSelf    = _row(rows, (s) => s.contains('自行買賣'));
      // 自營商(避險)
      final rowDealerHedge   = _row(rows, (s) => s.contains('避險'));
      // 合計
      final rowTotal         = _row(rows, (s) => s.contains('合計'));

      if (rowForeignMain == null || rowTrust == null ||
          rowDealerSelf == null || rowDealerHedge == null ||
          rowTotal == null) {
        return null;
      }

      // 外資自營商若缺失以 0 計算
      final fdBuy  = rowForeignDealer != null ? _yi(rowForeignDealer[1]) : 0.0;
      final fdSell = rowForeignDealer != null ? _yi(rowForeignDealer[2]) : 0.0;
      final fdNet  = rowForeignDealer != null ? _yi(rowForeignDealer[3]) : 0.0;

      // ── 分組加總 ──────────────────────────────────────────────────────────
      // 外資 = 外資及陸資 + 外資自營商
      final foreign = InstitutionalGroup(
        name: '外資',
        buyYi:  _yi(rowForeignMain[1]) + fdBuy,
        sellYi: _yi(rowForeignMain[2]) + fdSell,
        netYi:  _yi(rowForeignMain[3]) + fdNet,
      );

      // 投信
      final trust = InstitutionalGroup(
        name: '投信',
        buyYi:  _yi(rowTrust[1]),
        sellYi: _yi(rowTrust[2]),
        netYi:  _yi(rowTrust[3]),
      );

      // 自營商 = 自行買賣 + 避險
      final dealer = InstitutionalGroup(
        name: '自營商',
        buyYi:  _yi(rowDealerSelf[1]) + _yi(rowDealerHedge[1]),
        sellYi: _yi(rowDealerSelf[2]) + _yi(rowDealerHedge[2]),
        netYi:  _yi(rowDealerSelf[3]) + _yi(rowDealerHedge[3]),
      );

      // 總額 = 合計行（直接取用，不重新加總以確保與 TWSE 一致）
      final total = InstitutionalGroup(
        name: '三大法人合計',
        buyYi:  _yi(rowTotal[1]),
        sellYi: _yi(rowTotal[2]),
        netYi:  _yi(rowTotal[3]),
      );

      final result = InstitutionalFlowResult(
        date: dateKey,
        foreign: foreign,
        trust: trust,
        dealer: dealer,
        total: total,
      );

      return result;
    } catch (_) {
      return null;
    }
  }

  // ── 內部工具 ───────────────────────────────────────────────────────────────

  /// 在 rows 中找到第一個符合條件的行，找不到回傳 null。
  static List<dynamic>? _row(
    List<List<dynamic>> rows,
    bool Function(String) test,
  ) {
    try {
      return rows.firstWhere(
        (r) => r.isNotEmpty && test(r[0].toString()),
      );
    } catch (_) {
      return null;
    }
  }

  /// "447,310,392,567" → 4473.10（億元）
  static double _yi(dynamic raw) {
    final cleaned =
        raw.toString().replaceAll(',', '').replaceAll('+', '').trim();
    return (double.tryParse(cleaned) ?? 0.0) / 100000000.0;
  }

  /// 給定日期字串，回傳所在週的週一（YYYYMMDD）。
  static String _mondayOf(String dateKey) {
    final year  = int.parse(dateKey.substring(0, 4));
    final month = int.parse(dateKey.substring(4, 6));
    final day   = int.parse(dateKey.substring(6, 8));
    final date  = DateTime(year, month, day);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}'
        '${monday.month.toString().padLeft(2, '0')}'
        '${monday.day.toString().padLeft(2, '0')}';
  }

}
