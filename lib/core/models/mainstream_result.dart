class MainstreamResult {
  final String category;

  final double mainstreamScore;

  final double flowScore;

  final double persistenceScore;

  final double diffusionScore;

  final double leaderScore;

  final bool strengthening;

  final bool weakening;

  const MainstreamResult({
    required this.category,
    required this.mainstreamScore,
    required this.flowScore,
    required this.persistenceScore,
    required this.diffusionScore,
    required this.leaderScore,
    required this.strengthening,
    required this.weakening,
  });
}
