import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/workout.dart';

class CsvService {
  // EXPORT: List<Workout> -> CSV String -> Share Dialog
  static Future<void> exportToCsv(List<Workout> workouts) async {
    // 1. Define Headers
    List<List<dynamic>> rows = [
      ["date", "count", "duration_seconds", "avg_rpm", "is_verified"],
    ];

    // 2. Map data to rows
    for (var w in workouts) {
      rows.add([
        w.date.toIso8601String(),
        w.count,
        w.durationSeconds,
        w.avgRpm,
        w.isVerified ? 1 : 0,
      ]);
    }

    // 3. Convert to String using ListToCsvConverter
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Save to temporary file and share
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/apex_push_export.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'My PushUp Stats');
  }

  // IMPORT: Pick File -> CSV String -> List<Workout>
  static Future<List<Workout>> importFromCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final input = await file.readAsString();

      // Convert String to List<List<dynamic>>
      List<List<dynamic>> rows = const CsvToListConverter().convert(input);

      // Skip header and map to objects
      return rows.skip(1).map((row) {
        return Workout(
          date: DateTime.parse(row[0]),
          count: row[1],
          durationSeconds: row[2],
          avgRpm: row[3].toDouble(),
          isImported: true, // MARKING: Always mark as imported
          isVerified: row[4] == 1,
        );
      }).toList();
    }
    return [];
  }
}
