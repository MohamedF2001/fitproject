class FitnessUtils {
  const FitnessUtils._();
  static double? bmi(
      {required double? weightKg, required double? heightMeters}) {
    if (weightKg == null || heightMeters == null || heightMeters <= 0) {
      return null;
    }
    return weightKg / (heightMeters * heightMeters);
  }

  static String formatDuration(Duration value) =>
      '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}
