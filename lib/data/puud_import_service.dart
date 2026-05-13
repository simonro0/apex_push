import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/workout.dart';

/// Imports training history from the original "Push Ups" app backup (.puud).
///
/// A .puud file is a ZIP archive containing PushUps_Mos.db (SQLite).
/// Schema: PushUpsRecord(_id, year, month, day, target, level, num, which)
///   which=1  free session (small counts)
///   which=2  individual programme set
///   which=3  session total from structured training
class PuudImportService {
  /// Opens a file picker, extracts and reads the .puud database.
  /// Returns the imported [Workout] list, or null if the user cancelled.
  static Future<List<Workout>?> importFromPuud() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['puud'],
      );
    } catch (_) {
      return null;
    }
    if (result == null || result.files.single.path == null) return null;

    final puudPath = result.files.single.path!;
    final tmpDir = await getTemporaryDirectory();
    final dbPath = '${tmpDir.path}/puud_import_${DateTime.now().millisecondsSinceEpoch}.db';

    try {
      final bytes = await File(puudPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final dbEntry = archive.files.where((f) => f.name == 'PushUps_Mos.db').firstOrNull;
      if (dbEntry == null) return null;

      await File(dbPath).writeAsBytes(dbEntry.content as List<int>);

      final db = await openDatabase(dbPath, readOnly: true);
      try {
        final rows = await db.query('PushUpsRecord', where: 'num > 0');
        return rows.map(_rowToWorkout).toList();
      } finally {
        await db.close();
      }
    } finally {
      final f = File(dbPath);
      if (await f.exists()) await f.delete();
    }
  }

  static Workout _rowToWorkout(Map<String, dynamic> row) {
    final year  = row['year']  as int;
    final month = row['month'] as int;
    final day   = row['day']   as int;
    final num   = row['num']   as int;
    final which = row['which'] as int;

    // which=3 are session totals from the structured programme (not free training).
    final isFree = which != 3;

    return Workout(
      date: DateTime(year, month, day),
      count: num,
      durationSeconds: 0,
      avgRpm: 0,
      isImported: true,
      isVerified: false,
      isFreeTraining: isFree,
    );
  }
}
