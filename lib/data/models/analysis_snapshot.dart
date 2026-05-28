class AnalysisSnapshot {
  final String date;

  final List<dynamic> mainstreams;

  final List<dynamic> lifecycles;

  final List<dynamic> rotations;

  final Map<String, dynamic> sentiment;

  const AnalysisSnapshot({
    required this.date,
    required this.mainstreams,
    required this.lifecycles,
    required this.rotations,
    required this.sentiment,
  });
}
