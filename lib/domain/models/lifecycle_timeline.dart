class LifecycleTimeline {
  final String category;

  final List<double> scores;

  final List<double> flows;

  final List<double> diffusions;

  const LifecycleTimeline({
    required this.category,
    required this.scores,
    required this.flows,
    required this.diffusions,
  });
}
