import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/rep_detail.dart';
import '../models/training_data.dart';
import '../models/workout.dart';

/// A parsed puud row: the workout and its synthetic rep_details.
/// workoutId in each RepDetail is a placeholder (0); the caller assigns
/// the real ID after DB insertion.
typedef PuudRecord = ({Workout workout, List<RepDetail> repDetails});

/// Imports training history from the original "Push Ups" app backup (.puud).
///
/// A .puud file is a ZIP archive containing PushUps_Mos.db (SQLite).
/// Schema: PushUpsRecord(_id, year, month, day, target, level, num, which)
///   which=1  free session
///   which=2  assessment (free-style test that determines next difficulty)
///   which=3  session total from structured training
///   target   0-based sequential programme unit (0→"1-1", 23→"8-3")
///   level    difficulty: 0=Easy, 1=Normal, 2=Hard
///   num      reps completed (rows with num=0 are excluded by the query)
class PuudImportService {
  /// Opens a file picker, extracts and reads the .puud database.
  /// Returns the imported [PuudRecord] list, or null if the user cancelled.
  static Future<List<PuudRecord>?> importFromPuud() async {
    FilePickerResult? result;
    try {
      // withData: true → reads via ContentResolver, avoiding content:// URI
      // path issues that cause silent import failures on Android.
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['puud'],
        withData: true,
      );
    } catch (_) {
      return null;
    }
    if (result == null) return null;

    final file = result.files.single;
    // Prefer in-memory bytes from withData; fall back to path read.
    final bytes = file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null) return null;

    final tmpDir = await getTemporaryDirectory();
    final dbPath = '${tmpDir.path}/puud_import_${DateTime.now().millisecondsSinceEpoch}.db';

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      final dbEntry = archive.files.where((f) => f.name == 'PushUps_Mos.db').firstOrNull;
      if (dbEntry == null) return null;

      await File(dbPath).writeAsBytes(dbEntry.content as List<int>);

      final db = await openDatabase(dbPath, readOnly: true);
      try {
        // rawQuery bypasses sqflite's Android CursorWindow row limit (~1000).
        final rows = await db.rawQuery(
          'SELECT * FROM PushUpsRecord WHERE num > 0',
        );
        return rows.map(_rowToRecord).toList();
      } finally {
        await db.close();
      }
    } finally {
      final f = File(dbPath);
      if (await f.exists()) await f.delete();
    }
  }

  static PuudRecord _rowToRecord(Map<String, dynamic> row) {
    final year   = row['year']   as int;
    final month  = row['month']  as int;
    final day    = row['day']    as int;
    final num    = row['num']    as int;
    final which  = row['which']  as int;
    final target = row['target'] as int?;
    final level  = row['level']  as int?;

    // which=1,2 = free session / assessment; which=3 = structured training.
    final isFree = which != 3;

    // target is a 0-based sequential unit index: 0→"1-1", 1→"1-2", 23→"8-3".
    final levelId = (!isFree && target != null)
        ? '${(target ~/ 3) + 1}-${(target % 3) + 1}'
        : null;

    // level encodes difficulty: 0=Easy, 1=Normal, 2=Hard.
    final difficulty = (!isFree && level != null)
        ? const ['Easy', 'Normal', 'Hard'][level.clamp(0, 2)]
        : null;

    final workout = Workout(
      date:            DateTime(year, month, day),
      count:           num,
      durationSeconds: 0,
      avgRpm:          0,
      isImported:      true,
      isVerified:      false,
      isFreeTraining:  isFree,
      levelId:         levelId,
      difficulty:      difficulty,
    );

    // Build synthetic rep_details for structured sessions so set splits are
    // stored in the DB and rendered without any special UI fallback.
    // workoutId is a placeholder (0); the caller replaces it with the real ID.
    final repDetails = _buildRepDetails(num, levelId, difficulty);

    return (workout: workout, repDetails: repDetails);
  }

  static List<RepDetail> _buildRepDetails(
      int total, String? levelId, String? difficulty) {
    if (levelId == null || difficulty == null) return [];
    final targets = TrainingData.programs[levelId]?[difficulty];
    if (targets == null || targets.isEmpty) return [];

    final details = <RepDetail>[];
    var remaining = total;
    for (var setIdx = 0; setIdx < targets.length; setIdx++) {
      final done = remaining.clamp(0, targets[setIdx]);
      for (var repIdx = 0; repIdx < done; repIdx++) {
        details.add(RepDetail(
          workoutId:    0,
          setIndex:     setIdx,
          repIndex:     repIdx,
          timestampMs:  0,
          peakG:        0.0,
          isNear:       false,
          proximityVal: 0.0,
        ));
      }
      remaining -= done;
      if (remaining <= 0) break;
    }
    return details;
  }
}
