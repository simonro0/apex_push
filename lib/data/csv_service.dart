import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages

import '../models/workout.dart';

class CsvService {
  static Future<void> exportToCsv(List<Workout> workouts) async {
    List<List<dynamic>> rows = [
      ['date', 'count', 'duration_seconds', 'avg_rpm', 'is_verified', 'is_free_training'],
    ];
    for (final w in workouts) {
      rows.add([
        w.date.toIso8601String(),
        w.count,
        w.durationSeconds,
        w.avgRpm,
        w.isVerified ? 1 : 0,
        w.isFreeTraining ? 1 : 0,
      ]);
    }
    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/apex_push_export.csv');
    await file.writeAsString(csvData);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'ApexPush Export'));
  }

  /// Returns imported workouts, or an empty list on cancel / parse error.
  static Future<List<Workout>> importFromCsv() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
    } catch (_) {
      return [];
    }

    if (result == null || result.files.single.path == null) return [];

    try {
      final input = await File(result.files.single.path!).readAsString();
      final rows = const CsvToListConverter().convert(input);
      if (rows.length < 2) return [];

      return rows.skip(1).map((row) => Workout.fromCsv(row)).toList();
    } catch (_) {
      return [];
    }
  }
}
