class ProgressionEngine {
  static double calculateNewTarget(int currentTarget, String feedback) {
    switch (feedback) {
      case 'Too Easy':
        return currentTarget * 1.20; // 20% jump
      case 'Just Right':
        return currentTarget * 1.05; // 5% steady climb
      case 'Too Hard':
        return currentTarget * 0.90; // 10% reduction to build confidence
      default:
        return currentTarget.toDouble();
    }
  }
}
