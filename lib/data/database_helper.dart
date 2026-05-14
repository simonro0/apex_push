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
      version: 4,
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
    await db.execute('''
      CREATE TABLE rep_details (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id   INTEGER NOT NULL,
        rep_index    INTEGER NOT NULL,
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
  }

  Future<int> createWorkout(Workout workout) async {
    final db = await instance.database;
    return db.insert('workouts', workout.toMap());
  }

  Future<List<Workout>> readAllWorkouts() async {
    final db = await instance.database;
    final result = await db.query('workouts', orderBy: 'date DESC');
    return result.map(Workout.fromMap).toList();
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

  Future<void> close() async => (await instance.database).close();
}
