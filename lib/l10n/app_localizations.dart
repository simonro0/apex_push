import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/settings_provider.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _t = {
    'de': {
      // ── App / Dashboard ──────────────────────────────────────────────────
      'app_title': 'ApexPush',
      'history': 'Verlauf',
      'no_history': 'Kein Training vorhanden. Jetzt starten!',
      'sessions': 'Sessions',
      'training': 'TRAINING',
      'practice': 'PRACTICE',
      'record': 'RECORD',
      'best_record': 'Best Record',
      'total': 'Total',
      'average': 'Schnitt',
      'current_level': 'Aktuelles Level',
      // ── Settings ─────────────────────────────────────────────────────────
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'theme': 'Theme',
      'theme_dark': 'Dunkel',
      'theme_light': 'Hell',
      'theme_system': 'System',
      'german': 'Deutsch',
      'english': 'Englisch',
      'appearance': 'Erscheinungsbild',
      'data': 'Daten',
      'sensor_threshold': 'Sensor-Schwellwert',
      'close': 'Schließen',
      // ── Data management ───────────────────────────────────────────────────
      'export_csv': 'CSV exportieren',
      'import_csv': 'CSV importieren',
      'import_puud': '.puud importieren',
      'no_data_imported': 'Keine Daten importiert.',
      'entries_imported': 'Einträge importiert.',
      'opening_file': 'Datei wird geöffnet…',
      'cancelled': 'Abgebrochen.',
      'no_data_found': 'Keine Daten gefunden.',
      'clear_all_data': 'Alle Daten löschen',
      'clear_all_data_confirm':
          'Alle Trainingsdaten werden unwiderruflich gelöscht. Fortfahren?',
      'all_data_deleted': 'Alle Daten wurden gelöscht.',
      // ── Generic actions ───────────────────────────────────────────────────
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'back': 'ZURÜCK',
      'apply': 'ÜBERNEHMEN',
      'continue_upper': 'WEITER',
      'keep_going': 'WEITERMACHEN',
      'abort': 'ABBRECHEN',
      'ok': 'OK',
      'home': 'Home',
      // ── Workout screen ────────────────────────────────────────────────────
      'free_training': 'FREIES TRAINING',
      'finish_session': 'SESSION BEENDEN',
      'set_x_of_y': 'Satz {set} von {total}',
      'target_reps': 'Ziel: {n} Wdh.',
      'finish_training': 'TRAINING ABSCHLIESSEN',
      'finish_set': 'SATZ ABSCHLIESSEN',
      'abort_training_btn': 'TRAINING ABBRECHEN',
      'abort_set_btn': 'SATZ ABBRECHEN',
      'abort_training_link': 'Training abbrechen',
      'rest': 'PAUSE',
      'next_set_reps': 'Nächster Satz: {n} Wdh.',
      'skip_rest': 'PAUSE ÜBERSPRINGEN',
      'reps_short': 'Wdh.',
      // ── Post-training dialogs ─────────────────────────────────────────────
      'training_finished': 'Training beendet',
      'how_was_difficulty': 'Wie war die Schwierigkeit?',
      'too_hard': 'ZU SCHWER',
      'just_right': 'PASST SO',
      'too_easy': 'ZU LEICHT',
      'level_adjusted': 'Level angepasst',
      'new_level_info': 'Neues Level: {unit} ({diff})\nSätze: {reps}',
      // ── Abort dialogs ─────────────────────────────────────────────────────
      'abort_set_title': 'Satz abbrechen?',
      'abort_set_msg':
          'Der aktuelle Satz wird mit den bisher erreichten Wiederholungen gewertet.',
      'abort_last_title': 'Training abbrechen?',
      'abort_last_msg':
          'Das Training wird mit den bisher erreichten Wiederholungen gespeichert.',
      'abort_session_title': 'Training abbrechen?',
      'abort_session_msg':
          'Das Training wird mit den bisher erreichten Wiederholungen gespeichert.',
      // ── Session detail ────────────────────────────────────────────────────
      'training_completed': 'Training abgeschlossen',
      'sets_section': 'Sätze',
      'set_n': 'Satz {n}',
      'target_label': 'Ziel: {n}',
      'reached_label': 'Erreicht: {n}',
      'date_label': 'Datum',
      'level_label': 'Level',
      'total_label': 'Gesamt',
      'duration_label': 'Dauer',
      'calories_label': 'Kalorien',
      'free_training_label': 'Freies Training',
      'reps_unit': 'Wdh.',
      'min_sec': '{min} min {sec} s',
      'kcal_approx': '≈ {n} kcal',
      // ── Level picker ──────────────────────────────────────────────────────
      'select_level': 'Level auswählen',
      'level_n': 'Level {n}',
      // ── Record screen ─────────────────────────────────────────────────────
      'pushups_tab': 'Liegestütze',
      'calories_tab': 'Kalorien',
      // ── Workout stat card ─────────────────────────────────────────────────
      'pushups': 'Liegestütze',
      'rpm': 'W/Min',
    },
    'en': {
      // ── App / Dashboard ──────────────────────────────────────────────────
      'app_title': 'ApexPush',
      'history': 'History',
      'no_history': 'No workouts yet. Start now!',
      'sessions': 'Sessions',
      'training': 'TRAINING',
      'practice': 'PRACTICE',
      'record': 'RECORD',
      'best_record': 'Best Record',
      'total': 'Total',
      'average': 'Average',
      'current_level': 'Current Level',
      // ── Settings ─────────────────────────────────────────────────────────
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'theme_dark': 'Dark',
      'theme_light': 'Light',
      'theme_system': 'System',
      'german': 'German',
      'english': 'English',
      'appearance': 'Appearance',
      'data': 'Data',
      'sensor_threshold': 'Sensor Threshold',
      'close': 'Close',
      // ── Data management ───────────────────────────────────────────────────
      'export_csv': 'Export CSV',
      'import_csv': 'Import CSV',
      'import_puud': 'Import .puud',
      'no_data_imported': 'No data imported.',
      'entries_imported': 'entries imported.',
      'opening_file': 'Opening file…',
      'cancelled': 'Cancelled.',
      'no_data_found': 'No data found.',
      'clear_all_data': 'Clear All Data',
      'clear_all_data_confirm':
          'All training data will be permanently deleted. Continue?',
      'all_data_deleted': 'All data has been deleted.',
      // ── Generic actions ───────────────────────────────────────────────────
      'cancel': 'Cancel',
      'delete': 'Delete',
      'back': 'BACK',
      'apply': 'APPLY',
      'continue_upper': 'CONTINUE',
      'keep_going': 'KEEP GOING',
      'abort': 'ABORT',
      'ok': 'OK',
      'home': 'Home',
      // ── Workout screen ────────────────────────────────────────────────────
      'free_training': 'FREE TRAINING',
      'finish_session': 'FINISH SESSION',
      'set_x_of_y': 'Set {set} of {total}',
      'target_reps': 'Target: {n} reps',
      'finish_training': 'FINISH TRAINING',
      'finish_set': 'FINISH SET',
      'abort_training_btn': 'ABORT TRAINING',
      'abort_set_btn': 'ABORT SET',
      'abort_training_link': 'Abort training',
      'rest': 'REST',
      'next_set_reps': 'Next set: {n} reps',
      'skip_rest': 'SKIP REST',
      'reps_short': 'reps',
      // ── Post-training dialogs ─────────────────────────────────────────────
      'training_finished': 'Training Finished',
      'how_was_difficulty': 'How was the difficulty?',
      'too_hard': 'TOO HARD',
      'just_right': 'JUST RIGHT',
      'too_easy': 'TOO EASY',
      'level_adjusted': 'Level Adjusted',
      'new_level_info': 'New level: {unit} ({diff})\nSets: {reps}',
      // ── Abort dialogs ─────────────────────────────────────────────────────
      'abort_set_title': 'Abort set?',
      'abort_set_msg': 'The current set will be counted with reps achieved so far.',
      'abort_last_title': 'Abort training?',
      'abort_last_msg': 'The training will be saved with reps achieved so far.',
      'abort_session_title': 'Abort training?',
      'abort_session_msg': 'The training will be saved with reps achieved so far.',
      // ── Session detail ────────────────────────────────────────────────────
      'training_completed': 'Training Completed',
      'sets_section': 'Sets',
      'set_n': 'Set {n}',
      'target_label': 'Target: {n}',
      'reached_label': 'Reached: {n}',
      'date_label': 'Date',
      'level_label': 'Level',
      'total_label': 'Total',
      'duration_label': 'Duration',
      'calories_label': 'Calories',
      'free_training_label': 'Free Training',
      'reps_unit': 'reps',
      'min_sec': '{min} min {sec} s',
      'kcal_approx': '≈ {n} kcal',
      // ── Level picker ──────────────────────────────────────────────────────
      'select_level': 'Select Level',
      'level_n': 'Level {n}',
      // ── Record screen ─────────────────────────────────────────────────────
      'pushups_tab': 'Push-Ups',
      'calories_tab': 'Calories',
      // ── Workout stat card ─────────────────────────────────────────────────
      'pushups': 'Push-Ups',
      'rpm': 'reps/min',
    },
  };

  static const _weekdays = {
    'de': ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  };

  static const _months = {
    'de': ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
           'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  };

  static String translate(String key, String locale) =>
      _t[locale]?[key] ?? _t['de']![key] ?? key;

  static String formatDate(DateTime d, String locale) {
    final wd = _weekdays[locale]![d.weekday - 1];
    final mo = _months[locale]![d.month - 1];
    return '$wd, ${d.day}. $mo ${d.year}';
  }

  static String formatMonth(DateTime d, String locale) {
    final mo = _months[locale]![d.month - 1];
    return '$mo ${d.year}';
  }
}

extension AppLocalizationsExt on BuildContext {
  /// Use inside build() — registers a watch dependency on locale changes.
  String t(String key) {
    final locale = watch<SettingsProvider>().locale;
    return AppLocalizations.translate(key, locale);
  }

  /// Use in callbacks / event handlers — no watch dependency.
  String tr(String key) {
    final locale = read<SettingsProvider>().locale;
    return AppLocalizations.translate(key, locale);
  }

  /// Like tr() but replaces {placeholders} in the string.
  String tp(String key, Map<String, String> params) {
    var s = tr(key);
    params.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  String formatDate(DateTime d) =>
      AppLocalizations.formatDate(d, read<SettingsProvider>().locale);

  String formatMonth(DateTime d) =>
      AppLocalizations.formatMonth(d, read<SettingsProvider>().locale);
}
