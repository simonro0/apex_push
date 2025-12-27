// data/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/workout.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workouts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // We use INTEGER for booleans (0 = false, 1 = true)
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        count INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        rpm REAL NOT NULL,
        isImported INTEGER NOT NULL,
        isVerified INTEGER NOT NULL
      )
    ''');
  }

  // Insert a single workout
  Future<int> createWorkout(Workout workout) async {
    final db = await instance.database;
    return await db.insert('workouts', workout.toMap());
  }

  // Fetch all workouts sorted by date descending
  Future<List<Workout>> readAllWorkouts() async {
    final db = await instance.database;
    final result = await db.query('workouts', orderBy: 'date DESC');

    return result
        .map(
          (json) => Workout(
            id: json['id'] as int,
            date: DateTime.parse(json['date'] as String),
            count: json['count'] as int,
            durationSeconds: json['duration'] as int,
            avgRpm: json['rpm'] as double,
            isImported: json['isImported'] == 1,
            isVerified: json['isVerified'] == 1,
          ),
        )
        .toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
