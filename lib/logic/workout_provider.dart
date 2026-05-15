import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../data/puud_import_service.dart';
import '../data/sensor_service.dart';
import '../models/rep_detail.dart';
import '../models/training_data.dart';
import '../models/workout.dart';

class WorkoutProvider with ChangeNotifier {
  late SensorService _sensors;

  List<Workout> _history = [];
  ActiveProgram _activeProgram = const ActiveProgram(unitId: '1-1', difficulty: 'Easy');

  int _currentSessionCount = 0;
  DateTime? _startTime;
  bool _lastRepVerified = false;
  int  _verifiedRepsCount = 0;

  /// Per-rep sensor data collected during the current session.
  List<RepDetail> _repBuffer = [];

  /// Rep counts for each completed set in the current session.
  List<int> _sessionSplits = [];

  WorkoutProvider() : _sensors = SensorService();

  // ── Getters ────────────────────────────────────────────────────────────────

  int get currentCount => _currentSessionCount;
  List<Workout> get history => _history;
  ActiveProgram get activeProgram => _activeProgram;

  /// Immutable view of per-set rep counts recorded this session.
  List<int> get sessionSplits => List.unmodifiable(_sessionSplits);

  /// Number of sensor-verified reps in the last completed session.
  int get lastVerifiedReps => _verifiedRepsCount;

  /// Pre-computed stats derived from history.
  int get bestDayCount {
    if (_history.isEmpty) return 0;
    final totals = _dailyTotals();
    return totals.values.reduce((a, b) => a > b ? a : b);
  }

  int get totalCount => _history.fold(0, (s, w) => s + w.count);

  double get averageDailyCount {
    final totals = _dailyTotals();
    if (totals.isEmpty) return 0;
    final sum = totals.values.fold(0, (s, v) => s + v);
    return sum / totals.length;
  }

  Map<String, int> _dailyTotals() {
    final map = <String, int>{};
    for (final w in _history) {
      final key = '${w.date.year}-${w.date.month}-${w.date.day}';
      map[key] = (map[key] ?? 0) + w.count;
    }
    return map;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sensors.dispose();
    super.dispose();
  }

  // ── Active programme ───────────────────────────────────────────────────────

  Future<void> loadActiveProgram() async {
    final prefs = await SharedPreferences.getInstance();
    final unitId     = prefs.getString('active_unit_id')    ?? '1-1';
    final difficulty = prefs.getString('active_difficulty') ?? 'Easy';
    _activeProgram = ActiveProgram(unitId: unitId, difficulty: difficulty);
    notifyListeners();
  }

  Future<void> saveActiveProgram(ActiveProgram program) async {
    _activeProgram = program;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_unit_id',    program.unitId);
    await prefs.setString('active_difficulty', program.difficulty);
    notifyListeners();
  }

  /// Moves the active programme one step up (too easy) or down (too hard).
  /// [direction] must be 'up', 'down', or 'keep'.
  Future<void> stepDifficulty(String direction) async {
    if (direction == 'keep') return;
    final step = direction == 'up'
        ? TrainingData.stepUp(_activeProgram.unitId, _activeProgram.difficulty)
        : TrainingData.stepDown(_activeProgram.unitId, _activeProgram.difficulty);
    await saveActiveProgram(ActiveProgram(unitId: step.unitId, difficulty: step.difficulty));
  }

  // ── Workout session ────────────────────────────────────────────────────────

  void startWorkout({double sensorThreshold = 12.0}) {
    _sensors.dispose();
    _sensors             = SensorService(impactThreshold: sensorThreshold);
    _currentSessionCount = 0;
    _lastRepVerified     = false;
    _verifiedRepsCount   = 0;
    _repBuffer           = [];
    _sessionSplits       = [];
    _startTime           = DateTime.now();
    _sensors.init();
    notifyListeners();
  }

  void incrementCount() {
    final result = _sensors.verifyPushUp();
    _lastRepVerified = result.verified;
    if (result.verified) _verifiedRepsCount++;
    _repBuffer.add(RepDetail(
      workoutId:    0, // filled in by saveWorkout after DB insert
      repIndex:     _currentSessionCount,
      setIndex:     _sessionSplits.length,
      timestampMs:  _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
      peakG:        result.peakG,
      isNear:       result.isNear,
      proximityVal: result.proximityRaw,
    ));
    _currentSessionCount++;
    notifyListeners();
  }

  /// Records the rep count for a completed (or aborted) set.
  void recordSetSplit(int count) {
    _sessionSplits.add(count);
    // no notifyListeners needed – UI doesn't watch splits directly
  }

  /// Saves the current session to the database and returns the saved [Workout].
  Future<Workout> saveWorkout({bool isFreeTraining = false}) async {
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
    final rpm = duration > 0 ? _currentSessionCount / (duration / 60.0) : 0.0;

    final workout = Workout(
      date:            DateTime.now(),
      count:           _currentSessionCount,
      durationSeconds: duration,
      avgRpm:          rpm,
      isVerified:      _lastRepVerified,
      isFreeTraining:  isFreeTraining,
      levelId:         isFreeTraining ? null : _activeProgram.unitId,
      difficulty:      isFreeTraining ? null : _activeProgram.difficulty,
    );

    final workoutId   = await DatabaseHelper.instance.createWorkout(workout);
    final savedWorkout = Workout(
      id:              workoutId,
      date:            workout.date,
      count:           workout.count,
      durationSeconds: workout.durationSeconds,
      avgRpm:          workout.avgRpm,
      isImported:      workout.isImported,
      isVerified:      workout.isVerified,
      isFreeTraining:  workout.isFreeTraining,
      levelId:         workout.levelId,
      difficulty:      workout.difficulty,
    );
    await DatabaseHelper.instance.insertRepDetails(workoutId, _repBuffer);
    await loadHistoryFromDb();
    return savedWorkout;
  }

  // ── Data management ────────────────────────────────────────────────────────

  Future<void> loadHistoryFromDb() async {
    _history = await DatabaseHelper.instance.readAllWorkouts();
    notifyListeners();
  }

  Future<void> saveMultipleWorkouts(List<Workout> workouts) async {
    await DatabaseHelper.instance.batchInsert(workouts);
    await loadHistoryFromDb();
  }

  Future<void> clearAllData() async {
    await DatabaseHelper.instance.deleteAllWorkouts();
    await loadHistoryFromDb();
  }

  /// Imports from a .puud backup file. Returns the number of imported workouts,
  /// or -1 if the user cancelled the file picker.
  Future<int> importFromPuud() async {
    final records = await PuudImportService.importFromPuud();
    if (records == null) return -1;
    if (records.isEmpty) return 0;
    for (final r in records) {
      final id = await DatabaseHelper.instance.createWorkout(r.workout);
      if (r.repDetails.isNotEmpty) {
        final details = r.repDetails
            .map((d) => RepDetail(
                  workoutId:    id,
                  setIndex:     d.setIndex,
                  repIndex:     d.repIndex,
                  timestampMs:  d.timestampMs,
                  peakG:        d.peakG,
                  isNear:       d.isNear,
                  proximityVal: d.proximityVal,
                ))
            .toList();
        await DatabaseHelper.instance.insertRepDetailsBatch(details);
      }
    }
    await loadHistoryFromDb();
    return records.length;
  }
}
