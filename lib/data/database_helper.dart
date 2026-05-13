import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 2,
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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE workouts ADD COLUMN isFreeTraining INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE workouts ADD COLUMN levelId TEXT');
      await db.execute('ALTER TABLE workouts ADD COLUMN difficulty TEXT');
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
    final batch = db.batch();
    for (final w in workouts) {
      batch.insert('workouts', w.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async => (await instance.database).close();
}
