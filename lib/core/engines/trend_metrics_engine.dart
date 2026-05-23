import 'package:tw_stock_capital_flow/core/models/trend_metrics.dart';

class TrendMetricsEngine {
  const TrendMetricsEngine();

  TrendMetrics analyze(List<double> values) {
    if (values.length < 2) {
      return const TrendMetrics(
        slope: 0,
        acceleration: 0,
        stability: 0,
        volatility: 0,
      );
    }

    final first = values.first;

    final last = values.last;

    final slope = last - first;

    double acceleration = 0;

    if (values.length >= 3) {
      final mid = values[values.length ~/ 2];

      acceleration = (last - mid) - (mid - first);
    }

    double volatility = 0;

    final avg = values.reduce((a, b) => a + b) / values.length;

    for (final value in values) {
      volatility += (value - avg).abs();
    }

    volatility /= values.length;

    final stability = 100 - volatility;

    return TrendMetrics(
      slope: slope,

      acceleration: acceleration,

      stability: stability,

      volatility: volatility,
    );
  }
}
