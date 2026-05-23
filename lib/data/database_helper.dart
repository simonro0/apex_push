import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/rep_detail.dart';
import '../models/workout.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('workouts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = join(await getDatabasesPath(), filePath);
    return openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        date          TEXT    NOT NULL,
        count         INTEGER NOT NULL,
        duration      INTEGER NOT NULL,
        rpm           REAL    NOT NULL,
        isImported    INTEGER NOT NULL DEFAULT 0,
        isVerified    INTEGER NOT NULL DEFAULT 0,
        isFreeTraining INTEGER NOT NULL DEFAULT 0,
        levelId       TEXT,
        difficulty    TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_workouts_date ON workouts(date)',
    );
    await db.execute('''
      CREATE TABLE rep_details (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id   INTEGER NOT NULL,
        rep_index    INTEGER NOT NULL,
        set_index    INTEGER NOT NULL DEFAULT 0,
        timestamp_ms INTEGER NOT NULL,
        peak_g         REAL    NOT NULL,
        is_near        INTEGER NOT NULL DEFAULT 0,
        proximity_val  REAL    NOT NULL DEFAULT 0,
        FOREIGN KEY (workout_id) REFERENCES workouts(id)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE workouts ADD COLUMN isFreeTraining INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE workouts ADD COLUMN levelId TEXT');
      await db.execute('ALTER TABLE workouts ADD COLUMN difficulty TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rep_details (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id     INTEGER NOT NULL,
          rep_index      INTEGER NOT NULL,
          timestamp_ms   INTEGER NOT NULL,
          peak_g         REAL    NOT NULL,
          is_near        INTEGER NOT NULL DEFAULT 0,
          proximity_val  REAL    NOT NULL DEFAULT 0,
          FOREIGN KEY (workout_id) REFERENCES workouts(id)
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE rep_details ADD COLUMN proximity_val REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE rep_details ADD COLUMN set_index INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_workouts_date ON workouts(date)',
      );
    }
  }

  Future<int> createWorkout(Workout workout) async {
    final db = await instance.database;
    return db.insert('workouts', workout.toMap());
  }

  /// Page size used by [WorkoutProvider] for lazy loading.
  static const int pageSize = 500;

  /// Returns [limit] workouts starting at [offset], newest first.
  Future<List<Workout>> readAllWorkouts({
    int limit  = pageSize,
    int offset = 0,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'workouts',
      orderBy: 'date DESC',
      limit:   limit,
      offset:  offset,
    );
    return result.map(Workout.fromMap).toList();
  }

  /// Total number of workout rows (for pagination boundary check).
  Future<int> getWorkoutCount() async {
    final db  = await instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) AS c FROM workouts');
    return (res.first['c'] as int?) ?? 0;
  }

  /// Sum of all rep counts across all workouts.
  Future<int> getTotalReps() async {
    final db  = await instance.database;
    final res = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) AS t FROM workouts',
    );
    return (res.first['t'] as int?) ?? 0;
  }

  /// Maximum total reps in a single calendar day.
  Future<int> getBestDayReps() async {
    final db  = await instance.database;
    final res = await db.rawQuery('''
      SELECT COALESCE(MAX(daily), 0) AS m
      FROM (SELECT SUM(count) AS daily
            FROM workouts
            GROUP BY substr(date, 1, 10))
    ''');
    return (res.first['m'] as int?) ?? 0;
  }

  /// Average total reps per calendar day that has at least one workout.
  Future<double> getAverageDailyReps() async {
    final db  = await instance.database;
    final res = await db.rawQuery('''
      SELECT COALESCE(AVG(daily), 0.0) AS a
      FROM (SELECT SUM(count) AS daily
            FROM workouts
            GROUP BY substr(date, 1, 10))
    ''');
    final val = res.first['a'];
    return val == null ? 0.0 : (val as num).toDouble();
  }

  Future<void> batchInsert(List<Workout> workouts) async {
    final db = await instance.database;
    // Process in chunks to stay within SQLite transaction limits.
    const chunkSize = 500;
    for (var i = 0; i < workouts.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, workouts.length);
      final batch = db.batch();
      for (final w in workouts.sublist(i, end)) {
        batch.insert('workouts', w.toMap());
      }
      await batch.commit(noResult: true);
    }
  }

  /// Inserts all puud records in a single transaction. Returns count inserted.
  Future<int> importPuudRecords(List<({Workout workout, List<RepDetail> repDetails})> records) async {
    if (records.isEmpty) return 0;
    final db = await instance.database;
    await db.transaction((txn) async {
      for (final r in records) {
        final id = await txn.insert('workouts', r.workout.toMap());
        if (r.repDetails.isNotEmpty) {
          final batch = txn.batch();
          for (final d in r.repDetails) {
            batch.insert('rep_details', {
              'workout_id':    id,
              'set_index':     d.setIndex,
              'rep_index':     d.repIndex,
              'timestamp_ms':  d.timestampMs,
              'peak_g':        d.peakG,
              'is_near':       d.isNear ? 1 : 0,
              'proximity_val': d.proximityVal,
            });
          }
          await batch.commit(noResult: true);
        }
      }
    });
    return records.length;
  }

  Future<void> deleteAllWorkouts() async {
    final db = await instance.database;
    await db.delete('workouts');
  }

  Future<void> insertRepDetails(int workoutId, List<RepDetail> details) async {
    if (details.isEmpty) return;
    final db = await instance.database;
    final batch = db.batch();
    for (final d in details) {
      batch.insert('rep_details', {
        'workout_id':    workoutId,
        'rep_index':     d.repIndex,
        'set_index':     d.setIndex,
        'timestamp_ms':  d.timestampMs,
        'peak_g':        d.peakG,
        'is_near':       d.isNear ? 1 : 0,
        'proximity_val': d.proximityVal,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<RepDetail>> getRepDetailsForWorkout(int workoutId) async {
    final db = await instance.database;
    final rows = await db.query(
      'rep_details',
      where:     'workout_id = ?',
      whereArgs: [workoutId],
      orderBy:   'rep_index ASC',
    );
    return rows.map(RepDetail.fromMap).toList();
  }

  Future<List<RepDetail>> getAllRepDetails() async {
    final db = await instance.database;
    final rows = await db.query(
      'rep_details',
      orderBy: 'workout_id ASC, rep_index ASC',
    );
    return rows.map(RepDetail.fromMap).toList();
  }

  /// Batch-inserts rep_details using each row's own workoutId field.
  Future<void> insertRepDetailsBatch(List<RepDetail> details) async {
    if (details.isEmpty) return;
    final db = await instance.database;
    const chunkSize = 500;
    for (var i = 0; i < details.length; i += chunkSize) {
      final end   = (i + chunkSize).clamp(0, details.length);
      final batch = db.batch();
      for (final d in details.sublist(i, end)) {
        batch.insert('rep_details', {
          'workout_id':    d.workoutId,
          'rep_index':     d.repIndex,
          'set_index':     d.setIndex,
          'timestamp_ms':  d.timestampMs,
          'peak_g':        d.peakG,
          'is_near':       d.isNear ? 1 : 0,
          'proximity_val': d.proximityVal,
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> close() async => (await instance.database).close();
}
