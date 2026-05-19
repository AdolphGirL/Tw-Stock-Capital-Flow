extension AverageExtension on List<double> {
  double average() {
    if (isEmpty) {
      return 0;
    }

    return reduce((a, b) => a + b) / length;
  }
}
