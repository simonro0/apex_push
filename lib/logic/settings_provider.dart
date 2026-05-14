import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_service.dart';

class SettingsProvider with ChangeNotifier {
  // ── Appearance ─────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;
  String    _locale    = 'de';

  // ── Audio ──────────────────────────────────────────────────────────────────
  bool   _audioEnabled    = true;
  bool   _repSoundEnabled = true;
  double _audioVolume     = 1.0;

  // ── Notifications ──────────────────────────────────────────────────────────
  bool _notificationsEnabled = false;
  int  _reminderHour         = 9;
  int  _reminderMinute       = 0;

  // ── Training ───────────────────────────────────────────────────────────────
  int    _restSecondsEasy   = 30;
  int    _restSecondsNormal = 60;
  int    _restSecondsHard   = 120;
  double _sensorThreshold   = 12.0;

  // ── Getters ────────────────────────────────────────────────────────────────

  ThemeMode get themeMode        => _themeMode;
  String    get locale           => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  int  get reminderHour         => _reminderHour;
  int  get reminderMinute       => _reminderMinute;

  bool      get audioEnabled     => _audioEnabled;
  bool      get repSoundEnabled  => _repSoundEnabled;
  double    get audioVolume      => _audioVolume;
  int       get restSecondsEasy   => _restSecondsEasy;
  int       get restSecondsNormal => _restSecondsNormal;
  int       get restSecondsHard   => _restSecondsHard;
  double    get sensorThreshold  => _sensorThreshold;

  int getRestSeconds(String difficulty) => switch (difficulty) {
    'Easy'   => _restSecondsEasy,
    'Normal' => _restSecondsNormal,
    _        => _restSecondsHard,
  };

  // ── Load / Save ────────────────────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode        = _modeFromString(prefs.getString('theme_mode') ?? 'dark');
    _locale           = prefs.getString('locale')              ?? 'de';
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    _reminderHour         = prefs.getInt('reminder_hour')          ?? 9;
    _reminderMinute       = prefs.getInt('reminder_minute')        ?? 0;
    _audioEnabled     = prefs.getBool('audio_enabled')         ?? true;
    _repSoundEnabled  = prefs.getBool('rep_sound_enabled')     ?? true;
    _audioVolume      = prefs.getDouble('audio_volume')        ?? 1.0;
    _restSecondsEasy  = prefs.getInt('rest_easy')              ?? 30;
    _restSecondsNormal= prefs.getInt('rest_normal')            ?? 60;
    _restSecondsHard  = prefs.getInt('rest_hard')              ?? 120;
    _sensorThreshold  = prefs.getDouble('sensor_threshold')    ?? 12.0;
    AudioService.instance.volume = _audioVolume;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _modeToString(mode));
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour   = hour;
    _reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    notifyListeners();
  }

  Future<void> setAudioEnabled(bool value) async {
    _audioEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_enabled', value);
    notifyListeners();
  }

  Future<void> setRepSoundEnabled(bool value) async {
    _repSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rep_sound_enabled', value);
    notifyListeners();
  }

  Future<void> setAudioVolume(double value) async {
    _audioVolume = value;
    AudioService.instance.volume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_volume', value);
    notifyListeners();
  }

  Future<void> setRestSecondsEasy(int value) async {
    _restSecondsEasy = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rest_easy', value);
    notifyListeners();
  }

  Future<void> setRestSecondsNormal(int value) async {
    _restSecondsNormal = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rest_normal', value);
    notifyListeners();
  }

  Future<void> setRestSecondsHard(int value) async {
    _restSecondsHard = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rest_hard', value);
    notifyListeners();
  }

  Future<void> setSensorThreshold(double value) async {
    _sensorThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sensor_threshold', value);
    notifyListeners();
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  Map<String, String> toBackupMap() => {
    'theme_mode':             _modeToString(_themeMode),
    'locale':                 _locale,
    'audio_enabled':          _audioEnabled.toString(),
    'rep_sound_enabled':      _repSoundEnabled.toString(),
    'audio_volume':           _audioVolume.toString(),
    'notifications_enabled':  _notificationsEnabled.toString(),
    'reminder_hour':          _reminderHour.toString(),
    'reminder_minute':        _reminderMinute.toString(),
    'rest_easy':              _restSecondsEasy.toString(),
    'rest_normal':            _restSecondsNormal.toString(),
    'rest_hard':              _restSecondsHard.toString(),
    'sensor_threshold':       _sensorThreshold.toString(),
  };

  Future<void> restoreFromBackup(Map<String, String> map) async {
    if (map.containsKey('theme_mode'))
      await setThemeMode(_modeFromString(map['theme_mode']!));
    if (map.containsKey('locale'))
      await setLocale(map['locale']!);
    if (map.containsKey('audio_enabled'))
      await setAudioEnabled(map['audio_enabled'] == 'true');
    if (map.containsKey('rep_sound_enabled'))
      await setRepSoundEnabled(map['rep_sound_enabled'] == 'true');
    if (map.containsKey('audio_volume'))
      await setAudioVolume(double.tryParse(map['audio_volume']!) ?? 1.0);
    if (map.containsKey('notifications_enabled'))
      await setNotificationsEnabled(map['notifications_enabled'] == 'true');
    if (map.containsKey('reminder_hour'))
      await setReminderTime(
        int.tryParse(map['reminder_hour']!)  ?? 9,
        int.tryParse(map['reminder_minute'] ?? '0') ?? 0,
      );
    if (map.containsKey('rest_easy'))
      await setRestSecondsEasy(int.tryParse(map['rest_easy']!) ?? 30);
    if (map.containsKey('rest_normal'))
      await setRestSecondsNormal(int.tryParse(map['rest_normal']!) ?? 60);
    if (map.containsKey('rest_hard'))
      await setRestSecondsHard(int.tryParse(map['rest_hard']!) ?? 120);
    if (map.containsKey('sensor_threshold'))
      await setSensorThreshold(double.tryParse(map['sensor_threshold']!) ?? 12.0);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static ThemeMode _modeFromString(String s) => switch (s) {
    'light'  => ThemeMode.light,
    'system' => ThemeMode.system,
    _        => ThemeMode.dark,
  };

  static String _modeToString(ThemeMode m) => switch (m) {
    ThemeMode.light  => 'light',
    ThemeMode.system => 'system',
    _                => 'dark',
  };
}
