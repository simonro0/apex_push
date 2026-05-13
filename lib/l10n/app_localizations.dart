import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/settings_provider.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _t = {
    'de': {
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
      'export_csv': 'CSV exportieren',
      'import_csv': 'CSV importieren',
      'import_puud': '.puud importieren',
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'theme': 'Theme',
      'theme_dark': 'Dunkel',
      'theme_light': 'Hell',
      'theme_system': 'System',
      'no_data_imported': 'Keine Daten importiert.',
      'entries_imported': 'Einträge importiert.',
      'opening_file': 'Datei wird geöffnet…',
      'cancelled': 'Abgebrochen.',
      'no_data_found': 'Keine Daten gefunden.',
      'german': 'Deutsch',
      'english': 'Englisch',
      'appearance': 'Erscheinungsbild',
      'data': 'Daten',
      'sensor_threshold': 'Sensor-Schwellwert',
      'close': 'Schließen',
      'clear_all_data': 'Alle Daten löschen',
      'clear_all_data_confirm':
          'Alle Trainingsdaten werden unwiderruflich gelöscht. Fortfahren?',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'all_data_deleted': 'Alle Daten wurden gelöscht.',
    },
    'en': {
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
      'export_csv': 'Export CSV',
      'import_csv': 'Import CSV',
      'import_puud': 'Import .puud',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'theme_dark': 'Dark',
      'theme_light': 'Light',
      'theme_system': 'System',
      'no_data_imported': 'No data imported.',
      'entries_imported': 'entries imported.',
      'opening_file': 'Opening file…',
      'cancelled': 'Cancelled.',
      'no_data_found': 'No data found.',
      'german': 'German',
      'english': 'English',
      'appearance': 'Appearance',
      'data': 'Data',
      'sensor_threshold': 'Sensor Threshold',
      'close': 'Close',
      'clear_all_data': 'Clear All Data',
      'clear_all_data_confirm':
          'All training data will be permanently deleted. Continue?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'all_data_deleted': 'All data has been deleted.',
    },
  };

  static String translate(String key, String locale) =>
      _t[locale]?[key] ?? _t['de']![key] ?? key;
}

extension AppLocalizationsExt on BuildContext {
  String t(String key) {
    final locale = watch<SettingsProvider>().locale;
    return AppLocalizations.translate(key, locale);
  }

  String tr(String key) {
    final locale = read<SettingsProvider>().locale;
    return AppLocalizations.translate(key, locale);
  }
}
