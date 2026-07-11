import 'stock_data.dart';

class StockDaySnapshot {
  final String date;

  final List<StockData> stocks;

  StockDaySnapshot({required this.date, required this.stocks});

  factory StockDaySnapshot.fromJson(Map<String, dynamic> json) {
    return StockDaySnapshot(
      date: json['date']?.toString() ?? '',
      stocks: (json['stocks'] as List?)
              ?.map((e) => StockData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'stocks': stocks.map((e) => e.toJson()).toList()};
  }
}
