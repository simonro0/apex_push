import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../logic/settings_provider.dart';
import '../models/rep_detail.dart';
import '../models/workout.dart';
import 'database_helper.dart';

typedef BackupResult = ({int workouts, int repDetails, bool settings});

class BackupService {
  /// Path where the last export was saved on device, or null if unavailable.
  static String? lastSavedPath;

  // ── Export ─────────────────────────────────────────────────────────────────

  static Future<void> exportBackup(SettingsProvider settings) async {
    final workouts   = await DatabaseHelper.instance.readAllWorkouts();
    final repDetails = await DatabaseHelper.instance.getAllRepDetails();

    final wBytes = _workoutsCsv(workouts);
    final rBytes = _repDetailsCsv(repDetails);
    final sBytes = _settingsCsv(settings.toBackupMap());

    final archive = Archive()
      ..addFile(ArchiveFile('workouts.csv',    wBytes.length, wBytes))
      ..addFile(ArchiveFile('rep_details.csv', rBytes.length, rBytes))
      ..addFile(ArchiveFile('settings.csv',    sBytes.length, sBytes));

    final zipBytes = ZipEncoder().encode(archive)!;

    // Write to a user-accessible location first (Downloads on Android).
    final savedPath = await _saveToDevice(zipBytes);
    lastSavedPath = savedPath;

    // Also share so the user can send it elsewhere.
    final shareFile = savedPath != null
        ? File(savedPath)
        : File('${(await getTemporaryDirectory()).path}/apex_push_backup.apxbak')
            ..writeAsBytesSync(zipBytes);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(shareFile.path)],
      text:  'ApexPush Backup',
    ));
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Returns (workouts: n, repDetails: m, settings: bool),
  /// or (workouts: -1, ...) when user cancelled the picker.
  static Future<BackupResult> importBackup(SettingsProvider settings) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apxbak', 'csv'],
      );
    } catch (_) {
      return (workouts: -1, repDetails: 0, settings: false);
    }

    if (result == null || result.files.single.path == null) {
      return (workouts: -1, repDetails: 0, settings: false);
    }

    final path = result.files.single.path!;

    if (path.endsWith('.apxbak')) {
      return _importZip(path, settings);
    } else {
      return _importLegacyCsv(path);
    }
  }

  // ── Device storage ─────────────────────────────────────────────────────────

  static Future<String?> _saveToDevice(List<int> bytes) async {
    try {
      // Prefer external storage (SD card / shared Downloads) on Android.
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      final path = '${dir.path}/apex_push_backup.apxbak';
      await File(path).writeAsBytes(bytes);
      return path;
    } catch (_) {
      return null;
    }
  }

  // ── ZIP import ─────────────────────────────────────────────────────────────

  static Future<BackupResult> _importZip(
      String path, SettingsProvider settingsProvider) async {
    try {
      final bytes   = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      List<Workout>?          workouts;
      List<RepDetail>?        repDetails;
      Map<String, String>?    settingsMap;

      for (final entry in archive) {
        if (!entry.isFile) continue;
        final content = utf8.decode(entry.content as List<int>);
        switch (entry.name) {
          case 'workouts.csv':    workouts    = _parseWorkouts(content);
          case 'rep_details.csv': repDetails  = _parseRepDetails(content);
          case 'settings.csv':    settingsMap = _parseSettings(content);
        }
      }

      // Insert workouts one-by-one to capture new DB IDs
      final idMap        = <int, int>{};
      var   workoutCount = 0;
      for (final w in workouts ?? <Workout>[]) {
        final newW = Workout(
          date:            w.date,
          count:           w.count,
          durationSeconds: w.durationSeconds,
          avgRpm:          w.avgRpm,
          isImported:      true,
          isVerified:      w.isVerified,
          isFreeTraining:  w.isFreeTraining,
          levelId:         w.levelId,
          difficulty:      w.difficulty,
        );
        final newId = await DatabaseHelper.instance.createWorkout(newW);
        if (w.id != null) idMap[w.id!] = newId;
        workoutCount++;
      }

      // Insert rep_details with remapped workout_ids
      var repCount = 0;
      if (repDetails != null && repDetails.isNotEmpty) {
        final remapped = repDetails.map((d) => RepDetail(
          workoutId:    idMap[d.workoutId] ?? d.workoutId,
          repIndex:     d.repIndex,
          timestampMs:  d.timestampMs,
          peakG:        d.peakG,
          isNear:       d.isNear,
          proximityVal: d.proximityVal,
        )).toList();
        await DatabaseHelper.instance.insertRepDetailsBatch(remapped);
        repCount = remapped.length;
      }

      // Restore settings
      var settingsRestored = false;
      if (settingsMap != null) {
        await settingsProvider.restoreFromBackup(settingsMap);
        settingsRestored = true;
      }

      return (workouts: workoutCount, repDetails: repCount, settings: settingsRestored);
    } catch (_) {
      return (workouts: 0, repDetails: 0, settings: false);
    }
  }

  // ── Legacy CSV import (workouts only) ──────────────────────────────────────

  static Future<BackupResult> _importLegacyCsv(String path) async {
    try {
      final content  = await File(path).readAsString();
      final rows     = const CsvToListConverter().convert(content);
      if (rows.length < 2) return (workouts: 0, repDetails: 0, settings: false);
      final workouts = rows.skip(1).map((r) => Workout.fromCsv(r)).toList();
      if (workouts.isEmpty) return (workouts: 0, repDetails: 0, settings: false);
      await DatabaseHelper.instance.batchInsert(workouts);
      return (workouts: workouts.length, repDetails: 0, settings: false);
    } catch (_) {
      return (workouts: 0, repDetails: 0, settings: false);
    }
  }

  // ── CSV builders ───────────────────────────────────────────────────────────

  static List<int> _workoutsCsv(List<Workout> workouts) {
    final rows = <List<dynamic>>[
      ['id', 'date', 'count', 'duration_seconds', 'avg_rpm',
       'is_verified', 'is_free_training', 'level_id', 'difficulty'],
    ];
    for (final w in workouts) {
      rows.add([
        w.id, w.date.toIso8601String(), w.count, w.durationSeconds, w.avgRpm,
        w.isVerified ? 1 : 0, w.isFreeTraining ? 1 : 0,
        w.levelId ?? '', w.difficulty ?? '',
      ]);
    }
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  static List<int> _repDetailsCsv(List<RepDetail> details) {
    final rows = <List<dynamic>>[
      ['workout_id', 'rep_index', 'timestamp_ms', 'peak_g', 'is_near', 'proximity_val'],
    ];
    for (final d in details) {
      rows.add([
        d.workoutId, d.repIndex, d.timestampMs,
        d.peakG, d.isNear ? 1 : 0, d.proximityVal,
      ]);
    }
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  static List<int> _settingsCsv(Map<String, String> map) {
    final rows = <List<dynamic>>[['key', 'value']];
    map.forEach((k, v) => rows.add([k, v]));
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  // ── CSV parsers ────────────────────────────────────────────────────────────

  static List<Workout> _parseWorkouts(String csv) {
    final rows = const CsvToListConverter().convert(csv);
    if (rows.length < 2) return [];
    return rows.skip(1).map((r) {
      return Workout(
        id:              _int(r[0]),
        date:            DateTime.parse(r[1].toString()),
        count:           _int(r[2]) ?? 0,
        durationSeconds: _int(r[3]) ?? 0,
        avgRpm:          _dbl(r[4]) ?? 0.0,
        isVerified:      r[5] == 1 || r[5] == '1',
        isFreeTraining:  r[6] == 1 || r[6] == '1',
        levelId:         r.length > 7 ? _str(r[7]) : null,
        difficulty:      r.length > 8 ? _str(r[8]) : null,
      );
    }).toList();
  }

  static List<RepDetail> _parseRepDetails(String csv) {
    final rows = const CsvToListConverter().convert(csv);
    if (rows.length < 2) return [];
    return rows.skip(1).map((r) {
      return RepDetail(
        workoutId:    _int(r[0]) ?? 0,
        repIndex:     _int(r[1]) ?? 0,
        timestampMs:  _int(r[2]) ?? 0,
        peakG:        _dbl(r[3]) ?? 0.0,
        isNear:       r[4] == 1 || r[4] == '1',
        proximityVal: r.length > 5 ? (_dbl(r[5]) ?? 0.0) : 0.0,
      );
    }).toList();
  }

  static Map<String, String> _parseSettings(String csv) {
    final rows = const CsvToListConverter().convert(csv);
    if (rows.length < 2) return {};
    final map = <String, String>{};
    for (final r in rows.skip(1)) {
      if (r.length >= 2) map[r[0].toString()] = r[1].toString();
    }
    return map;
  }

  // ── Tiny converters ────────────────────────────────────────────────────────

  static int?    _int(dynamic v) => v == null || v == '' ? null : (v is int ? v : int.tryParse(v.toString()));
  static double? _dbl(dynamic v) => v == null || v == '' ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
  static String? _str(dynamic v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }
}
