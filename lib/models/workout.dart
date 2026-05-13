class Workout {
  final int? id;
  final DateTime date;
  final int count;
  final int durationSeconds;
  final double avgRpm;
  final bool isImported;
  final bool isVerified;
  final bool isFreeTraining;
  final String? levelId;    // e.g. "8-3"; null for free training
  final String? difficulty; // "Easy" / "Normal" / "Hard"; null for free training

  const Workout({
    this.id,
    required this.date,
    required this.count,
    required this.durationSeconds,
    required this.avgRpm,
    this.isImported = false,
    this.isVerified = false,
    this.isFreeTraining = false,
    this.levelId,
    this.difficulty,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'count': count,
    'duration': durationSeconds,
    'rpm': avgRpm,
    'isImported': isImported ? 1 : 0,
    'isVerified': isVerified ? 1 : 0,
    'isFreeTraining': isFreeTraining ? 1 : 0,
    'levelId': levelId,
    'difficulty': difficulty,
  };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
    id: map['id'] as int?,
    date: DateTime.parse(map['date'] as String),
    count: map['count'] as int,
    durationSeconds: map['duration'] as int,
    avgRpm: (map['rpm'] as num).toDouble(),
    isImported: map['isImported'] == 1,
    isVerified: map['isVerified'] == 1,
    isFreeTraining: map['isFreeTraining'] == 1,
    levelId: map['levelId'] as String?,
    difficulty: map['difficulty'] as String?,
  );

  factory Workout.fromCsv(List<dynamic> row) => Workout(
    date: DateTime.parse(row[0].toString()),
    count: row[1] is int ? row[1] as int : int.parse(row[1].toString()),
    durationSeconds: row[2] is int ? row[2] as int : int.parse(row[2].toString()),
    avgRpm: (row[3] as num).toDouble(),
    isImported: true,
    isVerified: row[4] == 1 || row[4] == '1',
    isFreeTraining: row.length > 5 && (row[5] == 1 || row[5] == '1'),
  );
}

class ActiveProgram {
  final String unitId;
  final String difficulty;

  const ActiveProgram({required this.unitId, required this.difficulty});

  @override
  String toString() => '$unitId ($difficulty)';
}
