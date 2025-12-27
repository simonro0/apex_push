// models/workout.dart
class Workout {
  final int? id;
  final DateTime date;
  final int count;
  final int durationSeconds;
  final double avgRpm;
  final bool isImported;
  final bool isVerified; // Result of anti-cheat check

  Workout({
    this.id,
    required this.date,
    required this.count,
    required this.durationSeconds,
    required this.avgRpm,
    this.isImported = false,
    this.isVerified = true,
  });

  // Convert for Database
  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'count': count,
    'duration': durationSeconds,
    'rpm': avgRpm,
    'isImported': isImported ? 1 : 0,
    'isVerified': isVerified ? 1 : 0,
  };

  // Create from CSV Row
  factory Workout.fromCsv(List<dynamic> row) {
    return Workout(
      date: DateTime.parse(row[0]),
      count: row[1],
      durationSeconds: row[2],
      avgRpm: row[3].toDouble(),
      isImported: true, // If it's coming from CSV, we mark it
    );
  }
}

// models/training_plan.dart
class TrainingPlan {
  int dailyTarget;
  double difficultyMultiplier; // e.g., 1.0, 1.1, 0.9

  TrainingPlan({required this.dailyTarget, this.difficultyMultiplier = 1.0});
}
