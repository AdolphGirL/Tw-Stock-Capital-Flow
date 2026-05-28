class MarketCalendarService {
  bool isNewTradingDay({
    required String latestApiDate,
    required List<String> localDates,
  }) {
    return !localDates.contains(latestApiDate);
  }
}
