import 'package:tw_stock_capital_flow/core/enums/lifecycle_stage.dart';

class LifecycleResult {
  final String category;

  final LifecycleStage stage;

  final double strength;

  final double acceleration;

  final double persistence;

  final double diffusion;

  final bool hotMoneyIn;

  const LifecycleResult({
    required this.category,
    required this.stage,
    required this.strength,
    required this.acceleration,
    required this.persistence,
    required this.diffusion,
    required this.hotMoneyIn,
  });
}
