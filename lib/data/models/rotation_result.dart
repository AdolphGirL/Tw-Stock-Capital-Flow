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

  Map<String, dynamic> toJson() {
    return {
      'fromCategory': fromCategory,
      'toCategory': toCategory,
      'score': score,
      'inflowStrength': inflowStrength,
    };
  }

  factory RotationResult.fromJson(Map<String, dynamic> json) {
    return RotationResult(
      fromCategory: json['fromCategory'],

      toCategory: json['toCategory'],

      score: (json['score'] ?? 0).toDouble(),

      inflowStrength: (json['inflowStrength'] ?? 0).toDouble(),
    );
  }
}
