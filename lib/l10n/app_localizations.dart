import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      'export_backup': 'Backup exportieren',
      'import_backup': 'Backup importieren',
      'backup_restored': '{w} Trainings, {r} Wdh.-Details importiert.',
      'settings_restored': 'Einstellungen wiederhergestellt.',
      'backup_saved_to': 'Gespeichert: {path}',
      'checksum_mismatch': 'Prüfsumme ungültig – Datei möglicherweise verändert!',
      'select_session': 'Sitzung auswählen',
      'import_conflict_aborted': 'Import abgebrochen – Konflikt bei vorhandenen Datensätzen.',
      'import_skipped': '{n} bereits vorhandene Einträge übersprungen.',
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
      'structured_training_label': 'Strukturiertes Training',
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
      // ── Audio settings ────────────────────────────────────────────────────
      'audio': 'Audio',
      'audio_enabled': 'Audio-Feedback',
      'rep_sound': 'Ton pro Wiederholung',
      'audio_volume': 'Lautstärke',
      // ── Training settings ─────────────────────────────────────────────────
      'training_settings': 'Training',
      'rest_easy': 'Pause (Leicht)',
      'rest_normal': 'Pause (Normal)',
      'rest_hard': 'Pause (Schwer)',
      'sensor_sensitivity': 'Sensor-Empfindlichkeit',
      'sensitivity_high': 'Hoch',
      'sensitivity_medium': 'Mittel',
      'sensitivity_low': 'Niedrig',
      // ── Sensor / session stats ────────────────────────────────────────────
      'sensor_verified':    'Verifiziert',
      'sensor_chart_title': 'Sensor-Daten',
      'peak_g_label':       'Beschleunigung (G)',
      'proximity_label':    'Abstand (cm)',
      'stat_min':           'Min',
      'stat_max':           'Max',
      'stat_avg':           'Ø',
      'stat_var':           'Var',
      'stat_diff_label':    'Δ zwischen Wdh.',
      // ── Weekday abbreviations (0 = Monday … 6 = Sunday) ──────────────────
      'weekday_0': 'Mo',
      'weekday_1': 'Di',
      'weekday_2': 'Mi',
      'weekday_3': 'Do',
      'weekday_4': 'Fr',
      'weekday_5': 'Sa',
      'weekday_6': 'So',
      // ── Weekly overview ───────────────────────────────────────────────────
      'week_overview':   'Diese Woche',
      'week_total':      '{n} Wdh.',
      'streak_days':     '{n} Tage Streak',
      'reps_per_min':    'Wdh./min',
      'vs_prev_week':    'vs. Vorwoche',
      // ── Burnout set ───────────────────────────────────────────────────────
      'burnout':      'BURNOUT',
      'burnout_chip': 'max',
      'burnout_next': 'Nächster Satz: BURNOUT',
      // ── Practice recommendation ───────────────────────────────────────────
      'practice_rec_title': 'Level-Empfehlung',
      'practice_rec_body':
          'Du hast {n} Wdh. absolviert.\n\nEmpfehlung: Level {level} ({diff})\nSätze: {reps}',
      'skip': 'ÜBERSPRINGEN',
      // ── Notifications ─────────────────────────────────────────────────────
      'notifications': 'Benachrichtigungen',
      'daily_reminder': 'Tägliche Erinnerung',
      'daily_reminder_desc': 'Erinnert dich täglich ans Training',
      'reminder_time': 'Uhrzeit',
      'notifications_hint':
          'Aktiviere die tägliche Erinnerung, um eine Benachrichtigung zu erhalten.',
      'notif_title': 'Zeit für dein Training!',
      'notif_body': 'Starte jetzt deine Liegestütze und erreiche dein Ziel.',
      'streak_reminder':      'Streak-Schutz',
      'streak_reminder_desc': 'Warnt dich, wenn heute der letzte Tag für deinen Streak ist',
      'streak_notif_title':   'Streak in Gefahr!',
      'streak_notif_body':    'Noch ca. {h}h bis Mitternacht – trainiere heute, um deinen Streak zu erhalten.',
      // ── About ─────────────────────────────────────────────────────────────
      'about':           'Über die App',
      'version':         'Version',
      'impressum':       'Impressum',
      'impressum_text':  'ApexPush ist eine private, nicht-kommerzielle App zur Unterstützung deines Liegestütz-Trainings.',
      'support_the_app': 'App unterstützen',
      'donation_text':   'Wenn dir die App gefällt, freue ich mich über eine kleine Spende.',
      'donate':          'Spenden',
      // ── Share ─────────────────────────────────────────────────────────────
      'share_workout':   'Training teilen',
      'share_btn':       'TEILEN',
      // ── Workout countdown ─────────────────────────────────────────────────
      'countdown_remaining': 'noch {n} Wdh.',
      'countdown_extra':     '{n} zusätzl. Wdh.',
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
      'export_backup': 'Export Backup',
      'import_backup': 'Import Backup',
      'backup_restored': '{w} workouts, {r} rep details imported.',
      'settings_restored': 'Settings restored.',
      'backup_saved_to': 'Saved: {path}',
      'checksum_mismatch': 'Checksum invalid — file may have been modified!',
      'select_session': 'Select session',
      'import_conflict_aborted': 'Import aborted — conflict with existing records.',
      'import_skipped': '{n} already present entries skipped.',
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
      'structured_training_label': 'Structured Training',
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
      // ── Audio settings ────────────────────────────────────────────────────
      'audio': 'Audio',
      'audio_enabled': 'Audio Feedback',
      'rep_sound': 'Rep Sound',
      'audio_volume': 'Volume',
      // ── Training settings ─────────────────────────────────────────────────
      'training_settings': 'Training',
      'rest_easy': 'Rest (Easy)',
      'rest_normal': 'Rest (Normal)',
      'rest_hard': 'Rest (Hard)',
      'sensor_sensitivity': 'Sensor Sensitivity',
      'sensitivity_high': 'High',
      'sensitivity_medium': 'Medium',
      'sensitivity_low': 'Low',
      // ── Sensor / session stats ────────────────────────────────────────────
      'sensor_verified':    'Verified',
      'sensor_chart_title': 'Sensor Data',
      'peak_g_label':       'Acceleration (G)',
      'proximity_label':    'Distance (cm)',
      'stat_min':           'Min',
      'stat_max':           'Max',
      'stat_avg':           'Avg',
      'stat_var':           'Var',
      'stat_diff_label':    'Δ between reps',
      // ── Weekday abbreviations (0 = Monday … 6 = Sunday) ──────────────────
      'weekday_0': 'Mo',
      'weekday_1': 'Tu',
      'weekday_2': 'We',
      'weekday_3': 'Th',
      'weekday_4': 'Fr',
      'weekday_5': 'Sa',
      'weekday_6': 'Su',
      // ── Weekly overview ───────────────────────────────────────────────────
      'week_overview':   'This Week',
      'week_total':      '{n} reps',
      'streak_days':     '{n}-day streak',
      'reps_per_min':    'reps/min',
      'vs_prev_week':    'vs. prev. week',
      // ── Burnout set ───────────────────────────────────────────────────────
      'burnout':      'BURNOUT',
      'burnout_chip': 'max',
      'burnout_next': 'Next set: BURNOUT',
      // ── Practice recommendation ───────────────────────────────────────────
      'practice_rec_title': 'Level Recommendation',
      'practice_rec_body':
          'You completed {n} reps.\n\nRecommended: Level {level} ({diff})\nSets: {reps}',
      'skip': 'SKIP',
      // ── Notifications ─────────────────────────────────────────────────────
      'notifications': 'Notifications',
      'daily_reminder': 'Daily Reminder',
      'daily_reminder_desc': 'Reminds you to work out every day',
      'reminder_time': 'Time',
      'notifications_hint':
          'Enable the daily reminder to receive a notification.',
      'notif_title': 'Time for your workout!',
      'notif_body': 'Start your push-ups now and reach your goal.',
      'streak_reminder':      'Streak Protection',
      'streak_reminder_desc': 'Warns you when today is the last day to keep your streak',
      'streak_notif_title':   'Streak at risk!',
      'streak_notif_body':    'About {h}h until midnight – train today to keep your streak alive.',
      // ── About ─────────────────────────────────────────────────────────────
      'about':           'About',
      'version':         'Version',
      'impressum':       'Legal Notice',
      'impressum_text':  'ApexPush is a private, non-commercial app to support your push-up training.',
      'support_the_app': 'Support the App',
      'donation_text':   'If you enjoy the app, a small donation is always appreciated.',
      'donate':          'Donate',
      // ── Share ─────────────────────────────────────────────────────────────
      'share_workout':   'Share Workout',
      'share_btn':       'SHARE',
      // ── Workout countdown ─────────────────────────────────────────────────
      'countdown_remaining': '{n} left',
      'countdown_extra':     '{n} extra',
    },
  };

  static String translate(String key, String locale) =>
      _t[locale]?[key] ?? _t['de']![key] ?? key;

  /// Formats a date as e.g. "Di., 15. Mai 2026" (de) or "Tue, May 15, 2026" (en).
  static String formatDate(DateTime d, String locale) =>
      DateFormat.yMMMEd(locale).format(d);

  /// Formats a month as e.g. "Mai 2026" (de) or "May 2026" (en).
  static String formatMonth(DateTime d, String locale) =>
      DateFormat.yMMM(locale).format(d);
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
