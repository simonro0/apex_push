import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../logic/settings_provider.dart';
import '../models/rep_detail.dart';
import '../models/workout.dart';
import 'database_helper.dart';

typedef BackupResult = ({
  int  workouts,
  int  repDetails,
  bool settings,
  bool checksumMismatch,
  bool conflictAborted,   // import aborted because data differs for an existing ID
  int  skipped,           // workouts already present with identical data
});

class BackupService {
  // ── Export ─────────────────────────────────────────────────────────────────

  /// Opens the system "Save file" dialog (SAF) and writes the backup there.
  /// Returns the saved path, or null if the user cancelled.
  static Future<String?> exportBackup(SettingsProvider settings) async {
    final workouts   = await DatabaseHelper.instance.readAllWorkouts();
    final repDetails = await DatabaseHelper.instance.getAllRepDetails();

    final wBytes = _workoutsCsv(workouts);
    final rBytes = _repDetailsCsv(repDetails);
    final sBytes = _settingsCsv(settings.toBackupMap());
    final cBytes = _buildChecksums(wBytes, rBytes);

    final archive = Archive()
      ..addFile(ArchiveFile('workouts.csv',    wBytes.length, wBytes))
      ..addFile(ArchiveFile('rep_details.csv', rBytes.length, rBytes))
      ..addFile(ArchiveFile('settings.csv',    sBytes.length, sBytes))
      ..addFile(ArchiveFile('checksums.txt',   cBytes.length, cBytes));

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    // SAF "Save as" dialog — the user picks the folder (e.g. Downloads).
    // No storage permission needed; the platform writes via ContentResolver.
    return FilePicker.platform.saveFile(
      fileName: 'apex_push_backup_${_timestamp()}.apxbak',
      bytes:    zipBytes,
    );
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Returns (workouts: n, repDetails: m, settings: bool),
  /// or (workouts: -1, ...) when user cancelled the picker.
  static Future<BackupResult> importBackup(SettingsProvider settings) async {
    FilePickerResult? result;
    try {
      // withData: true → file_picker reads via ContentResolver, avoiding
      // content:// URI path issues that cause silent import failures on Android.
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
    } catch (_) {
      return (workouts: -1, repDetails: 0, settings: false, checksumMismatch: false, conflictAborted: false, skipped: 0);
    }

    if (result == null) {
      return (workouts: -1, repDetails: 0, settings: false, checksumMismatch: false, conflictAborted: false, skipped: 0);
    }

    final file = result.files.single;

    // Prefer in-memory bytes from withData; fall back to path read.
    final Uint8List? bytes = file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);

    if (bytes == null) {
      return (workouts: -1, repDetails: 0, settings: false, checksumMismatch: false, conflictAborted: false, skipped: 0);
    }

    // Detect format by ZIP magic bytes (PK\x03\x04) — do not rely on extension
    // because Android SAF paths may not preserve the original filename.
    final isZip = bytes.length >= 4 &&
        bytes[0] == 0x50 && bytes[1] == 0x4B &&
        bytes[2] == 0x03 && bytes[3] == 0x04;

    return isZip ? _importZip(bytes, settings) : _importLegacyCsv(bytes);
  }

  // ── ZIP import ─────────────────────────────────────────────────────────────

  static Future<BackupResult> _importZip(
      Uint8List bytes, SettingsProvider settingsProvider) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      List<Workout>?          workouts;
      List<RepDetail>?        repDetails;
      Map<String, String>?    settingsMap;
      Map<String, String>?    storedChecksums;

      // Raw bytes kept for checksum verification before parsing
      List<int>? rawWorkouts;
      List<int>? rawRepDetails;

      for (final entry in archive) {
        if (!entry.isFile) continue;
        final raw = entry.content as List<int>;
        switch (entry.name) {
          case 'workouts.csv':
            rawWorkouts = raw;
            workouts    = _parseWorkouts(utf8.decode(raw));
          case 'rep_details.csv':
            rawRepDetails = raw;
            repDetails    = _parseRepDetails(utf8.decode(raw));
          case 'settings.csv':
            settingsMap = _parseSettings(utf8.decode(raw));
          case 'checksums.txt':
            storedChecksums = _parseChecksumFile(utf8.decode(raw));
        }
      }

      // ── Checksum verification ────────────────────────────────────────────────
      var integrityOk = false;
      if (storedChecksums != null) {
        var allMatch = true;
        if (rawWorkouts != null &&
            storedChecksums['workouts.csv'] != _sha256hex(rawWorkouts)) {
          allMatch = false;
        }
        if (rawRepDetails != null &&
            storedChecksums['rep_details.csv'] != _sha256hex(rawRepDetails)) {
          allMatch = false;
        }
        integrityOk = allMatch;
      }
      final checksumMismatch = !integrityOk;

      // ── Conflict detection ──────────────────────────────────────────────────
      // Load existing workouts and index by ID for O(1) lookup.
      final existingAll = await DatabaseHelper.instance.readAllWorkouts();
      final existingMap = <int, Workout>{
        for (final w in existingAll) if (w.id != null) w.id!: w,
      };

      final toImport  = <Workout>[];
      final skipIds   = <int>{};  // backup IDs that are already present
      var   skipped   = 0;
      bool  conflict  = false;

      for (final w in workouts ?? <Workout>[]) {
        if (w.id == null) {
          toImport.add(w);
          continue;
        }
        final existing = existingMap[w.id!];
        if (existing == null) {
          toImport.add(w);
        } else if (_workoutsMatch(existing, w)) {
          skipIds.add(w.id!);
          skipped++;
        } else {
          conflict = true;
          break;
        }
      }

      if (conflict) {
        return (workouts: 0, repDetails: 0, settings: false,
                checksumMismatch: false, conflictAborted: true, skipped: 0);
      }

      // ── Insert new workouts ─────────────────────────────────────────────────
      final idMap = <int, int>{};
      for (final w in toImport) {
        final newW = Workout(
          date:            w.date,
          count:           w.count,
          durationSeconds: w.durationSeconds,
          avgRpm:          w.avgRpm,
          isImported:      true,
          isVerified:      integrityOk && w.isVerified,
          isFreeTraining:  w.isFreeTraining,
          levelId:         w.levelId,
          difficulty:      w.difficulty,
        );
        final newId = await DatabaseHelper.instance.createWorkout(newW);
        if (w.id != null) idMap[w.id!] = newId;
      }

      // ── Insert rep_details for new workouts only ────────────────────────────
      var repCount = 0;
      if (repDetails != null && repDetails.isNotEmpty) {
        final toImportReps = repDetails
            .where((d) => !skipIds.contains(d.workoutId))
            .map((d) => RepDetail(
                  workoutId:    idMap[d.workoutId] ?? d.workoutId,
                  repIndex:     d.repIndex,
                  timestampMs:  d.timestampMs,
                  peakG:        d.peakG,
                  isNear:       d.isNear,
                  proximityVal: d.proximityVal,
                ))
            .toList();
        await DatabaseHelper.instance.insertRepDetailsBatch(toImportReps);
        repCount = toImportReps.length;
      }

      // ── Restore settings ────────────────────────────────────────────────────
      var settingsRestored = false;
      if (settingsMap != null) {
        await settingsProvider.restoreFromBackup(settingsMap);
        settingsRestored = true;
      }

      return (workouts: toImport.length, repDetails: repCount,
              settings: settingsRestored, checksumMismatch: checksumMismatch,
              conflictAborted: false, skipped: skipped);
    } catch (_) {
      return (workouts: 0, repDetails: 0, settings: false,
              checksumMismatch: false, conflictAborted: false, skipped: 0);
    }
  }

  // ── Legacy CSV import (workouts only) ──────────────────────────────────────

  static Future<BackupResult> _importLegacyCsv(Uint8List bytes) async {
    try {
      final content  = utf8.decode(bytes);
      final rows     = const CsvToListConverter().convert(content);
      if (rows.length < 2) {
        return (workouts: 0, repDetails: 0, settings: false, checksumMismatch: false, conflictAborted: false, skipped: 0);
      }
      final workouts = rows.skip(1).map((r) => Workout.fromCsv(r)).toList();
      if (workouts.isEmpty) {
        return (workouts: 0, repDetails: 0, settings: false, checksumMismatch: false, conflictAborted: false, skipped: 0);
      }
      await DatabaseHelper.instance.batchInsert(workouts);
      return (workouts: workouts.length, repDetails: 0, settings: false, checksumMismatch: false, conflictAborted: false, skipped: 0);
    } catch (_) {
      return (workouts: 0, repDetails: 0, settings: false, checksumMismatch: false, conflictAborted: false, skipped: 0);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _timestamp() {
    final n = DateTime.now();
    return '${n.year}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}'
        '_${n.hour.toString().padLeft(2, '0')}'
        '${n.minute.toString().padLeft(2, '0')}';
  }

  // ── Checksum helpers ───────────────────────────────────────────────────────

  static String _sha256hex(List<int> bytes) =>
      sha256.convert(bytes).toString();

  static List<int> _buildChecksums(List<int> wBytes, List<int> rBytes) {
    final lines = [
      'workouts.csv=${_sha256hex(wBytes)}',
      'rep_details.csv=${_sha256hex(rBytes)}',
    ].join('\n');
    return utf8.encode(lines);
  }

  static Map<String, String> _parseChecksumFile(String content) {
    final map = <String, String>{};
    for (final line in content.split('\n')) {
      final idx = line.indexOf('=');
      if (idx > 0) map[line.substring(0, idx)] = line.substring(idx + 1).trim();
    }
    return map;
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

  // ── Conflict helper ────────────────────────────────────────────────────────

  static bool _workoutsMatch(Workout a, Workout b) =>
      a.date == b.date &&
      a.count == b.count &&
      a.durationSeconds == b.durationSeconds &&
      a.isFreeTraining == b.isFreeTraining &&
      a.levelId == b.levelId &&
      a.difficulty == b.difficulty;

  // ── Tiny converters ────────────────────────────────────────────────────────

  static int?    _int(dynamic v) => v == null || v == '' ? null : (v is int ? v : int.tryParse(v.toString()));
  static double? _dbl(dynamic v) => v == null || v == '' ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
  static String? _str(dynamic v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }
}
