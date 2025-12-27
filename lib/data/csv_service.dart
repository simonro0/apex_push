import 'dart:io';

import 'package:csv/csv.dart';

import '../models/workout.dart';

class CsvService {
  // Exporting data to a human-readable file
  Future<String> exportWorkouts(List<Workout> workouts) async {
    List<List<dynamic>> rows = [
      ["Date", "Reps", "Seconds", "RepsPerMin", "Imported"],
    ];

    for (var w in workouts) {
      rows.add([
        w.date,
        w.reps,
        w.duration,
        w.rpm,
        w.isImported ? "YES" : "NO",
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    // Logic to save file to Documents folder
    return csvData;
  }

  // Importing data and forcing the 'imported' flag to true
  List<Workout> importCsv(String rawCsv) {
    List<List<dynamic>> rows = const CsvToListConverter().convert(rawCsv);
    // Skip header, map rows to Workout objects with isImported = true
    return rows.skip(1).map((row) => Workout.fromCsv(row)).toList();
  }
}
