import 'package:tw_stock_capital_flow/core/extensions/market_type_extension.dart';

enum MarketType { listed, otc }

class StockData {
  final String code;
  final String name;
  final MarketType market;
  final String mainCategory;
  final String subCategory;
  final double open;
  final double high;
  final double low;
  final double close;
  final double change;
  final double changePercent;
  final int volume;
  final int value;

  StockData({
    required this.code,
    required this.name,
    required this.market,
    required this.mainCategory,
    required this.subCategory,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.value,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      code: json['code'],
      name: json['name'],
      market: MarketTypeExtension.fromString(json['market']),
      mainCategory: json['mainCategory'],
      subCategory: json['subCategory'],
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
      value: json['value'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'market': market.value,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'value': value,
    };
  }
}
