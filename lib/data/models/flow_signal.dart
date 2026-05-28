enum FlowDirection { inflow, outflow, neutral }

class FlowSignal {
  final double score;

  final double volumeRatio;

  final double momentumScore;

  final double persistenceScore;

  final FlowDirection direction;

  const FlowSignal({
    required this.score,
    required this.volumeRatio,
    required this.momentumScore,
    required this.persistenceScore,
    required this.direction,
  });
}
