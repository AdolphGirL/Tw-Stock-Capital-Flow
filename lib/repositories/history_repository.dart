import 'package:tw_stock_capital_flow/models/stock_day_snapshot.dart';
import 'package:tw_stock_capital_flow/services/storage_service.dart';

class HistoryRepository {
  final StorageService storageService;

  HistoryRepository({required this.storageService});

  Future<List<StockDaySnapshot>> loadRecentSnapshots(int days) async {
    final dates = await storageService.listAvailableDates();

    final selectedDates = dates.take(days).toList();

    final result = <StockDaySnapshot>[];

    for (final date in selectedDates) {
      final snapshot = await storageService.loadSnapshot(date);

      if (snapshot != null) {
        result.add(snapshot);
      }
    }

    return result;
  }
}
