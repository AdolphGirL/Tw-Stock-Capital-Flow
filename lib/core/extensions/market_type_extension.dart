import 'package:tw_stock_capital_flow/models/stock_data.dart';

extension MarketTypeExtension on MarketType {
  String get value {
    switch (this) {
      case MarketType.listed:
        return 'listed';
      case MarketType.otc:
        return 'otc';
    }
  }

  static MarketType fromString(String value) {
    switch (value) {
      case 'listed':
        return MarketType.listed;
      case 'otc':
        return MarketType.otc;
      default:
        return MarketType.listed;
    }
  }
}
