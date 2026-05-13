typedef LevelStep = ({String unitId, String difficulty});

class TrainingData {
  TrainingData._();

  static const Map<String, int> restSeconds = {
    'Easy': 30,
    'Normal': 60,
    'Hard': 120,
  };

  static const List<String> difficulties = ['Easy', 'Normal', 'Hard'];

  /// All unit IDs in ascending program order, including generated levels 9–20.
  static final List<String> allUnitIds = [
    '1-1', '1-2', '1-3',
    '2-1', '2-2', '2-3',
    '3-1', '3-2', '3-3',
    '4-1', '4-2', '4-3',
    '5-1', '5-2', '5-3',
    '6-1', '6-2', '6-3',
    '7-1', '7-2', '7-3',
    '8-1', '8-2', '8-3',
    for (var l = 9; l <= 20; l++)
      for (var u = 1; u <= 3; u++) '$l-$u',
  ];

  /// Reps per set for all 72 hardcoded programmes (8 levels × 3 units × 3 difficulties).
  static const Map<String, Map<String, List<int>>> programs = {
    '1-1': {
      'Easy':   [2,  2,  2,  2,  3],
      'Normal': [6,  6,  5,  4,  5],
      'Hard':   [9,  9,  8,  6,  7],
    },
    '1-2': {
      'Easy':   [4,  3,  2,  2,  4],
      'Normal': [8,  8,  6,  5,  7],
      'Hard':   [11, 11, 9,  9,  10],
    },
    '1-3': {
      'Easy':   [5,  4,  4,  3,  5],
      'Normal': [9,  8,  8,  5,  9],
      'Hard':   [14, 12, 10, 10, 14],
    },
    '2-1': {
      'Easy':   [4,  5,  4,  4,  5],
      'Normal': [8,  7,  5,  4,  6],
      'Hard':   [11, 11, 8,  6,  9],
    },
    '2-2': {
      'Easy':   [6,  5,  3,  4,  6],
      'Normal': [10, 8,  6,  7,  9],
      'Hard':   [12, 12, 10, 10, 12],
    },
    '2-3': {
      'Easy':   [5,  6,  4,  5,  6],
      'Normal': [9,  9,  7,  7,  9],
      'Hard':   [14, 14, 11, 11, 10],
    },
    '3-1': {
      'Easy':   [9,  8,  10, 8,  10],
      'Normal': [14, 10, 9,  11, 8],
      'Hard':   [16, 14, 12, 11, 13],
    },
    '3-2': {
      'Easy':   [13, 10, 11, 11, 10],
      'Normal': [15, 15, 13, 13, 10],
      'Hard':   [18, 15, 14, 13, 17],
    },
    '3-3': {
      'Easy':   [15, 11, 14, 10, 11],
      'Normal': [20, 14, 14, 12, 18],
      'Hard':   [21, 15, 16, 14, 20],
    },
    '4-1': {
      'Easy':   [14, 11, 11, 9,  13],
      'Normal': [14, 12, 14, 12, 15],
      'Hard':   [20, 16, 18, 15, 22],
    },
    '4-2': {
      'Easy':   [14, 12, 12, 10, 13],
      'Normal': [20, 12, 14, 13, 16],
      'Hard':   [22, 18, 17, 16, 23],
    },
    '4-3': {
      'Easy':   [18, 11, 13, 12, 13],
      'Normal': [20, 17, 14, 15, 19],
      'Hard':   [25, 19, 18, 18, 24],
    },
    '5-1': {
      'Easy':   [21, 18, 14, 13, 19],
      'Normal': [22, 21, 16, 20, 22],
      'Hard':   [26, 22, 18, 21, 25],
    },
    '5-2': {
      'Easy':   [18, 11, 13, 12, 13],
      'Normal': [13, 12, 10, 8,  28],
      'Hard':   [15, 14, 12, 10, 32],
    },
    '5-3': {
      'Easy':   [14, 11, 11, 9,  13],
      'Normal': [10, 10, 8,  7,  28],
      'Hard':   [14, 12, 10, 8,  33],
    },
    '6-1': {
      'Easy':   [25, 21, 20, 18, 25],
      'Normal': [29, 25, 21, 20, 30],
      'Hard':   [34, 26, 24, 21, 32],
    },
    '6-2': {
      'Easy':   [13, 12, 10, 8,  28],
      'Normal': [15, 14, 12, 10, 33],
      'Hard':   [16, 14, 11, 10, 36],
    },
    '6-3': {
      'Easy':   [10, 10, 8,  7,  28],
      'Normal': [14, 12, 10, 8,  33],
      'Hard':   [14, 12, 10, 8,  36],
    },
    '7-1': {
      'Easy':   [30, 21, 26, 18, 25],
      'Normal': [34, 25, 21, 25, 35],
      'Hard':   [41, 26, 33, 25, 35],
    },
    '7-2': {
      'Easy':   [25, 14, 10, 8,  23],
      'Normal': [13, 14, 11, 10, 33],
      'Hard':   [20, 18, 11, 10, 28],
    },
    '7-3': {
      'Easy':   [19, 12, 10, 8,  28],
      'Normal': [14, 12, 10, 8,  30],
      'Hard':   [14, 12, 10, 18, 36],
    },
    '8-1': {
      'Easy':   [36, 28, 25, 24, 33],
      'Normal': [46, 36, 32, 34, 46],
      'Hard':   [52, 41, 38, 36, 52],
    },
    '8-2': {
      'Easy':   [18, 16, 13, 11, 38],
      'Normal': [21, 18, 18, 14, 46],
      'Hard':   [26, 21, 21, 18, 52],
    },
    '8-3': {
      'Easy':   [24, 21, 19, 18, 46],
      'Normal': [27, 24, 24, 20, 54],
      'Hard':   [31, 27, 27, 24, 60],
    },
  };

  // ── Accessors ──────────────────────────────────────────────────────────────

  static List<int> getReps(String unitId, String difficulty) {
    final byUnit = programs[unitId];
    if (byUnit != null) return byUnit[difficulty]!;
    return _generateReps(unitId, difficulty);
  }

  /// Generates reps for level 9+ by scaling the corresponding level-8 unit
  /// by 15 % per level beyond 8.
  static List<int> _generateReps(String unitId, String difficulty) {
    final parts = unitId.split('-');
    final level = int.parse(parts[0]);
    final unit  = parts[1]; // '1', '2', or '3'
    final base  = programs['8-$unit']![difficulty]!;
    final scale = 1.0 + (level - 8) * 0.15;
    return base.map((r) => (r * scale).round()).toList();
  }

  static int getRestSeconds(String difficulty) => restSeconds[difficulty]!;

  static int maxRepsForUnit(String unitId, String difficulty) =>
      getReps(unitId, difficulty).reduce((a, b) => a > b ? a : b);

  static int totalRepsForUnit(String unitId, String difficulty) =>
      getReps(unitId, difficulty).reduce((a, b) => a + b);

  // ── Level recommendation ───────────────────────────────────────────────────

  /// Recommends the unit whose max set is the smallest value above [practiceReps].
  /// Falls back to the first unit if none qualifies.
  static String recommendUnit(int practiceReps, String difficulty) {
    String best = allUnitIds.last; // fallback: highest level when reps exceed all maxima
    int bestGap = 0x7fffffff;
    for (final id in allUnitIds) {
      final max = maxRepsForUnit(id, difficulty);
      final gap = max - practiceReps;
      if (gap > 0 && gap < bestGap) {
        bestGap = gap;
        best = id;
      }
    }
    return best;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  static String? nextUnit(String unitId) {
    final idx = allUnitIds.indexOf(unitId);
    if (idx >= 0) return idx < allUnitIds.length - 1 ? allUnitIds[idx + 1] : null;
    // Fallback for IDs beyond the pre-generated range (level > 20).
    final parts = unitId.split('-');
    if (parts.length != 2) return null;
    final level = int.tryParse(parts[0]);
    final unit  = int.tryParse(parts[1]);
    if (level == null || unit == null) return null;
    return unit < 3 ? '$level-${unit + 1}' : '${level + 1}-1';
  }

  static String? previousUnit(String unitId) {
    final idx = allUnitIds.indexOf(unitId);
    if (idx > 0)  return allUnitIds[idx - 1];
    if (idx == 0) return null;
    // Fallback for IDs beyond the pre-generated range (level > 20).
    final parts = unitId.split('-');
    if (parts.length != 2) return null;
    final level = int.tryParse(parts[0]);
    final unit  = int.tryParse(parts[1]);
    if (level == null || unit == null) return null;
    if (unit > 1) return '$level-${unit - 1}';
    if (level <= 1) return null;
    return '${level - 1}-3';
  }

  static String? nextDifficulty(String difficulty) {
    final idx = difficulties.indexOf(difficulty);
    if (idx < 0 || idx >= difficulties.length - 1) return null;
    return difficulties[idx + 1];
  }

  static String? previousDifficulty(String difficulty) {
    final idx = difficulties.indexOf(difficulty);
    if (idx <= 0) return null;
    return difficulties[idx - 1];
  }

  /// "Too easy": Easy→Normal→Hard, then next unit at Easy.
  static LevelStep stepUp(String unitId, String difficulty) {
    final nextDiff = nextDifficulty(difficulty);
    if (nextDiff != null) return (unitId: unitId, difficulty: nextDiff);
    final nextU = nextUnit(unitId);
    if (nextU != null) return (unitId: nextU, difficulty: 'Easy');
    return (unitId: unitId, difficulty: difficulty); // already at maximum
  }

  /// "Too hard": Hard→Normal→Easy, then previous unit at Hard.
  static LevelStep stepDown(String unitId, String difficulty) {
    final prevDiff = previousDifficulty(difficulty);
    if (prevDiff != null) return (unitId: unitId, difficulty: prevDiff);
    final prevU = previousUnit(unitId);
    if (prevU != null) return (unitId: prevU, difficulty: 'Hard');
    return (unitId: unitId, difficulty: difficulty); // already at minimum
  }
}
