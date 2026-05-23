class RotationResult {
  final String fromCategory;

  final String toCategory;

  final double score;

  final double inflowStrength;

  const RotationResult({
    required this.fromCategory,
    required this.toCategory,
    required this.score,
    required this.inflowStrength,
  });
}
