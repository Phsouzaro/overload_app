class OneRmCalculator {
  // Epley formula, rounded to nearest 0.25kg
  static double? estimate(double weight, int reps) {
    if (reps < 3 || reps > 20 || weight <= 0) return null;
    final raw = weight * (1 + reps / 30);
    return (raw * 4).round() / 4;
  }
}
