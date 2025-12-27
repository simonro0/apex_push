// logic/workout_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../data/sensor_service.dart';
import '../models/workout.dart';

class WorkoutProvider with ChangeNotifier {
  final SensorService _sensors = SensorService();
  List<Workout> _history = [];
  final TrainingPlan _currentPlan = TrainingPlan(dailyTarget: 20);

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
    bool verified = _sensors.verifyPushUp();
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

  void updatePlanManual(int newTarget) {
    _currentPlan.dailyTarget = newTarget;
    notifyListeners();
  }

  Future<void> saveWorkout() async {
    if (_startTime == null) return;

    final duration = DateTime.now().difference(_startTime!).inSeconds;
    double rpm = duration > 0 ? (_currentSessionCount / (duration / 60)) : 0;

    final newWorkout = Workout(
      date: DateTime.now(),
      count: _currentSessionCount,
      durationSeconds: duration,
      avgRpm: rpm,
      isVerified: _lastRepVerified,
      isImported: false,
    );

    // Persist to SQLite
    await DatabaseHelper.instance.createWorkout(newWorkout);

    // Refresh local list
    await loadHistoryFromDb();
  }

  // Persists the new target to local storage so it survives app restarts
  Future<void> saveNewPlan(int newReps) async {
    _currentPlan.dailyTarget = newReps;

    // Use SharedPreferences for simple settings like the Daily Target
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_target', newReps);

    notifyListeners();
  }

  // Used by the CSV Import logic to save data in bulk efficiently
  Future<void> saveMultipleWorkouts(List<Workout> importedWorkouts) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    for (var workout in importedWorkouts) {
      batch.insert('workouts', workout.toMap());
    }

    await batch.commit(noResult: true); // noResult: true makes it faster

    // Refresh local history list from DB
    await loadHistoryFromDb();
    notifyListeners();
  }

  // Helper to load plan on app startup
  Future<void> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    _currentPlan.dailyTarget = prefs.getInt('daily_target') ?? 20;
    notifyListeners();
  }

  // This is called when the app starts and after imports
  Future<void> loadHistoryFromDb() async {
    _history = await DatabaseHelper.instance.readAllWorkouts();
    notifyListeners();
  }
}
