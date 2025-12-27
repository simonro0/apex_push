// logic/workout_provider.dart
import 'package:flutter/material.dart';

import '../data/sensor_service.dart';
import '../models/workout.dart';

class WorkoutProvider with ChangeNotifier {
  final SensorService _sensors = SensorService();
  List<Workout> _history = [];
  TrainingPlan _currentPlan = TrainingPlan(dailyTarget: 20);

  int _currentSessionCount = 0;
  DateTime? _startTime;
  bool _lastRepVerified = true;

  int get currentCount => _currentSessionCount;
  List<Workout> get history => _history;
  TrainingPlan get plan => _currentPlan;

  void startWorkout() {
    _currentSessionCount = 0;
    _startTime = DateTime.now();
    _sensors.init();
    notifyListeners();
  }

  void incrementCount() {
    bool verified = _sensors.verifyPushup();
    _currentSessionCount++;
    _lastRepVerified = verified; // Fact-checking the rep
    notifyListeners();
  }

  // ADAPTIVE LOGIC
  void adjustDifficulty(String feedback) {
    if (feedback == "Too Easy") {
      _currentPlan.dailyTarget = (_currentPlan.dailyTarget * 1.2).round();
    } else if (feedback == "Too Hard") {
      _currentPlan.dailyTarget = (_currentPlan.dailyTarget * 0.8).round();
    }
    // "Just Right" stays the same
    notifyListeners();
  }

  Future<void> saveWorkout() async {
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    final newWorkout = Workout(
      date: DateTime.now(),
      count: _currentSessionCount,
      durationSeconds: duration,
      avgRpm: (_currentSessionCount / (duration / 60)),
      isVerified: _lastRepVerified,
    );
    _history.insert(0, newWorkout);
    // Here you would also call DatabaseHelper.save(newWorkout);
    notifyListeners();
  }
}
