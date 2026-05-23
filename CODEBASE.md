# ApexPush – Codebase-Dokumentation

> Zuletzt aktualisiert: 2026-05-23  
> Basis: Aktueller Stand nach vollständiger Feature-Implementierung

---

## Inhaltsverzeichnis

1. [Projektbeschreibung](#1-projektbeschreibung)
2. [Verzeichnisstruktur](#2-verzeichnisstruktur)
3. [Architekturüberblick](#3-architekturüberblick)
4. [Schichten im Detail](#4-schichten-im-detail)
   - [Models](#41-models)
   - [Data](#42-data)
   - [Logic](#43-logic)
   - [UI](#44-ui)
5. [App-Flow](#5-app-flow)
6. [Datenbankschema](#6-datenbankschema)
7. [Abhängigkeiten](#7-abhängigkeiten)
8. [Offene Punkte & bekannte Bugs](#8-offene-punkte--bekannte-bugs)

---

## 1. Projektbeschreibung

**ApexPush** ist eine Flutter-App zur Liegestützen-Verfolgung mit strukturierten Trainingsplänen und adaptiver Schwierigkeitsanpassung.

Kernkonzept:

- Näherungssensor zählt Wiederholungen **vor** dem physischen Berühren des Displays (präziser als reine Touch-Erkennung). Screen-Tap dient als stiller Fallback.
- Strukturiertes satzbasiertes Training: 5 Sätze mit Zielvorgaben, automatische Pause-Countdown-Timers zwischen Sätzen.
- 72 hartcodierte Trainingsprogramme (8 Level × 3 Einheiten × 3 Schwierigkeiten).
- Historische Daten in SQLite mit vollständigem per-Wiederholung-Sensordatensatz.
- Vollständige Backup/Restore-Lösung: `.apxbak` ZIP mit Prüfsummen + Legacy-CSV-Kompatibilität.

---

## 2. Verzeichnisstruktur

```
apex_push/
├── lib/
│   ├── main.dart                              # Einstiegspunkt, Theme, Providers, Splash
│   ├── l10n/
│   │   └── app_localizations.dart             # DE/EN Texte + BuildContext-Extension
│   ├── models/
│   │   ├── workout.dart                       # Workout, ActiveProgram
│   │   ├── training_data.dart                 # 72-Programm-Matrix, Navigation, Empfehlung
│   │   └── rep_detail.dart                    # Per-Wiederholung-Sensordaten
│   ├── data/
│   │   ├── database_helper.dart               # SQLite Singleton (Schema v6)
│   │   ├── sensor_service.dart                # Näherung + Beschleunigung + Auto-Polarität
│   │   ├── csv_service.dart                   # Legacy CSV-Export
│   │   ├── backup_service.dart                # .apxbak ZIP Export/Import mit Prüfsummen
│   │   └── puud_import_service.dart           # Import aus originaler Push-Ups-App
│   ├── logic/
│   │   ├── workout_provider.dart              # Zentrales State-Management (paginiert)
│   │   ├── settings_provider.dart             # Einstellungen (Theme, Audio, Training)
│   │   ├── audio_service.dart                 # Synthetisierte Töne (Singleton)
│   │   ├── share_service.dart                 # RepaintBoundary → PNG → share_plus
│   │   └── notification_service.dart          # Tägliche Erinnerungen (Local Notifications)
│   └── ui/
│       ├── dashboard_screen.dart              # Startbildschirm
│       ├── level_picker_screen.dart           # 72-Einheiten-Auswahl
│       ├── record_screen.dart                 # Monatsansicht (provider-watch + lazy-load)
│       ├── session_detail_screen.dart         # Session-Detailansicht + Share-Funktion
│       ├── settings_screen.dart               # Einstellungsscreen
│       ├── notification_screen.dart           # Benachrichtigungseinstellungen
│       ├── about_screen.dart                  # App-Info
│       ├── workout/
│       │   └── workout_screen.dart            # Trainingsbildschirm (satzbasiert + frei)
│       └── widgets/
│           ├── workout_stat_card.dart         # Verlaufskarte
│           ├── monthly_combo_chart.dart       # fl_chart Balkendiagramm
│           └── share_card.dart               # Branded Share-Karte (dark, theme-unabhängig)
├── test/
│   ├── widget_test.dart                       # Sanity-Checks (reine Dart, kein SQLite)
│   └── training_data_test.dart                # 14 Unit-Tests für TrainingData
├── pubspec.yaml
├── README.md
├── CODEBASE.md
└── REQUIREMENTS.md
```

---

## 3. Architekturüberblick

```
┌──────────────────────────────────────────────────────────┐
│                       UI-Schicht                         │
│  DashboardScreen · WorkoutScreen · RecordScreen          │
│  LevelPickerScreen · SessionDetailScreen                 │
│  SettingsScreen · NotificationScreen · AboutScreen       │
├──────────────────────────────────────────────────────────┤
│                     Logic-Schicht                        │
│  WorkoutProvider  ·  SettingsProvider                    │
│  AudioService (Singleton)  ·  NotificationService (Singleton) │
├──────────────────────────────────────────────────────────┤
│                      Data-Schicht                        │
│  DatabaseHelper (SQLite)  ·  SensorService               │
│  BackupService  ·  CsvService  ·  PuudImportService      │
├──────────────────────────────────────────────────────────┤
│                     Modell-Schicht                       │
│  Workout  ·  ActiveProgram  ·  TrainingData  ·  RepDetail │
└──────────────────────────────────────────────────────────┘
```

**State-Management:** Flutter Provider (`ChangeNotifier`).  
`WorkoutProvider` und `SettingsProvider` werden über `MultiProvider` in `main.dart` bereitgestellt.  
`AudioService` und `NotificationService` sind Singletons ohne Provider-Integration.

---

## 4. Schichten im Detail

### 4.1 Models

**`Workout`** (`lib/models/workout.dart`)

| Feld              | Typ        | Beschreibung                                  |
|-------------------|------------|-----------------------------------------------|
| `id`              | `int?`     | Datenbankprimärschlüssel                      |
| `date`            | `DateTime` | Zeitstempel der Session                       |
| `count`           | `int`      | Gesamtwiederholungen                          |
| `durationSeconds` | `int`      | Sessiondauer                                  |
| `avgRpm`          | `double`   | Wiederholungen pro Minute                     |
| `isImported`      | `bool`     | Import-Kennzeichnung                          |
| `isVerified`      | `bool`     | Mindestens eine sensorverifizierte Wdh.       |
| `isFreeTraining`  | `bool`     | Freies Training (ohne Stufenbindung)          |
| `levelId`         | `String?`  | Einheit, z.B. `"3-2"` – null bei freiem Training |
| `difficulty`      | `String?`  | `"Easy"` / `"Normal"` / `"Hard"` – null bei freiem Training |

**`ActiveProgram`** (`lib/models/workout.dart`)

Leichtgewichtiger Value-Type: `unitId` (z.B. `"4-2"`) + `difficulty`. Wird in SharedPreferences persistiert.

**`TrainingData`** (`lib/models/training_data.dart`)

```dart
typedef LevelStep = ({String unitId, String difficulty});
```

| Methode / Konstante                            | Beschreibung                                              |
|------------------------------------------------|-----------------------------------------------------------|
| `allUnitIds` (24 Einträge)                     | Alle Einheiten in Programmreihenfolge                     |
| `difficulties` = `['Easy','Normal','Hard']`    | Schwierigkeitsstufen                                      |
| `programs` (72 Einträge)                       | Map: unitId → difficulty → `List<int>` (5 Sätze)         |
| `restSeconds` (per difficulty)                 | Standardruhezeiten (Easy=30 / Normal=60 / Hard=120 s)     |
| `getReps(unitId, difficulty)`                  | 5-Elemente-Liste der Satzziele                            |
| `getRestSeconds(difficulty)`                   | Standardruhezeit (überschreibbar via SettingsProvider)    |
| `recommendUnit(practiceReps, difficulty)`      | Erste Einheit, bei der `max(Sätze) > practiceReps` minimal |
| `stepUp(unitId, difficulty)`                   | Easy→Normal→Hard→nächste Einheit Easy                     |
| `stepDown(unitId, difficulty)`                 | Umgekehrt; Grenzen bleiben                                |
| `nextUnit(unitId)` / `previousUnit(unitId)`    | Navigation in Programmreihenfolge (null an den Enden)     |

**`RepDetail`** (`lib/models/rep_detail.dart`)

Per-Wiederholung-Sensordaten – wird bei jeder Wdh. erfasst und in der Tabelle `rep_details` gespeichert.

| Feld           | Typ      | Beschreibung                      |
|----------------|----------|-----------------------------------|
| `workoutId`    | `int`    | FK → workouts.id                  |
| `repIndex`     | `int`    | Position in der Session (0-basiert)|
| `setIndex`     | `int`    | Satznummer (0-basiert)            |
| `timestampMs`  | `int`    | ms seit Sessionstart              |
| `peakG`        | `double` | Maximale Beschleunigung im Zeitfenster |
| `isNear`       | `bool`   | War Näherungssensor aktiv?        |
| `proximityVal` | `double` | Rohwert des Näherungssensors      |

---

### 4.2 Data

**`DatabaseHelper`** (`lib/data/database_helper.dart`)

- Singleton, SQLite via `sqflite`, Schema **Version 6**
- Zwei Tabellen: `workouts` (10 Spalten), `rep_details` (8 Spalten + FK)
- Migrations: v1→2 (isFreeTraining, levelId, difficulty), v2→3 (rep_details Tabelle), v3→4 (proximity_val), v4→5 (set_index), v5→6 (Index `idx_workouts_date`)
- **Paginierung**: `readAllWorkouts({int limit = 500, int offset = 0})` — lädt seitenweise, neueste zuerst
- **SQL-Aggregate** (immer über alle Einträge, unabhängig von geladener Seite):
  - `getWorkoutCount()` → Gesamtzahl Workouts
  - `getTotalReps()` → `SUM(count)`
  - `getBestDayReps()` → `MAX` täglicher Summen
  - `getAverageDailyReps()` → `AVG` täglicher Summen
- Weitere Methoden: `createWorkout()`, `batchInsert()`, `insertRepDetails()`, `insertRepDetailsBatch()`, `importPuudRecords()`, `getRepDetailsForWorkout()`, `getAllRepDetails()`, `deleteAllWorkouts()`
- `importPuudRecords()`: nimmt `List<({Workout workout, List<RepDetail> repDetails})>`, führt einen einzelnen SQLite-Transaction-Block aus

**`SensorService`** (`lib/data/sensor_service.dart`)

```
Zustandsautomat:
  FAR  ──(event > 0*)──▶  NEAR  → proximityRepCallback()  → _wasNear = true
  NEAR ──(event == 0*)──▶  FAR   → bereit für nächste Wdh. → _wasNear = false
  * bei invertierten Geräten umgekehrt (0 = NEAR) – wird automatisch erkannt
```

- `proximityRepCallback` (öffentliches Feld): wird von `WorkoutProvider.startWorkout()` gesetzt
- Callback feuert auf **FAR→NEAR-Übergang** (vor physischem Berühren)
- **Auto-Polarity-Erkennung**: beim ersten Sensor-Event im Ruhezustand wird `_invertProximity` gesetzt — Geräte, die `0 = NEAR` melden, werden automatisch korrekt behandelt
- Beschleunigungsmesser (`userAccelerometerEventStream`) erfasst laufend den Peakwert für `verifyPushUp()`
- `verifyPushUp()` gibt `({bool verified, double peakG, bool isNear, double proximityRaw})` zurück; setzt 200 ms Cooldown zur Vermeidung von Tap-Vibrations-Doppelzählung
- Standard-`impactThreshold`: **6.0 m/s²** (gravity-removed); Presets: High=3.0, Medium=6.0, Low=12.0
- `dispose()` canceliert beide Subscriptions

**`BackupService`** (`lib/data/backup_service.dart`)

Vollständiges Backup-Format `.apxbak` (ZIP):

| Datei             | Inhalt                                                     |
|-------------------|------------------------------------------------------------|
| `workouts.csv`    | Alle Workouts mit ID                                       |
| `rep_details.csv` | Alle per-Rep-Sensordaten                                   |
| `settings.csv`    | Key-Value-Paare der SettingsProvider-Werte                 |
| `checksums.txt`   | SHA-256 von workouts.csv und rep_details.csv               |

Import-Logik: Prüfsummen-Verifikation → Konflikt-Erkennung (ID-Vergleich) → Deduplication (skip bei identischen Daten) → Abort bei abweichenden Konflikten. Abwärtskompatibel: reine CSV-Dateien werden als Legacy-Import erkannt (ZIP-Magic-Bytes Prüfung).

**`PuudImportService`** (`lib/data/puud_import_service.dart`)

Entpackt `.puud`-Datei (ZIP) → extrahiert `PushUps_Mos.db` → liest `PushUpsRecord`-Tabelle → mapped auf `Workout` + rekonstruiert per-Rep-Daten für `rep_details`.

**`CsvService`** (`lib/data/csv_service.dart`)

Legacy-Export (nur `workouts`, kein rep_details) via `share_plus`. Für vollständige Backups → `BackupService.exportBackup()`.

---

### 4.3 Logic

**`WorkoutProvider`** (`lib/logic/workout_provider.dart`)

Zentraler ChangeNotifier. Wichtige Zustände:

| Feld                     | Typ              | Beschreibung                                         |
|--------------------------|------------------|------------------------------------------------------|
| `_currentSessionCount`   | `int`            | Gesamtzähler der laufenden Session                   |
| `_sessionSplits`         | `List<int>`      | Rep-Anzahl pro abgeschlossenem Satz                  |
| `_repBuffer`             | `List<RepDetail>`| Per-Rep-Sensordaten bis zum Speichern                |
| `_lastProximityRepTime`  | `DateTime?`      | Debounce-Zeitstempel für Tap-Fallback                |
| `_activeProgram`         | `ActiveProgram`  | Aktuelle Einheit + Schwierigkeit                     |
| `_history`               | `List<Workout>`  | Geladene Seite(n) der Datenbank-Historie             |
| `_hasMoreHistory`        | `bool`           | True wenn weitere ältere Einträge in der DB vorhanden|
| `_totalReps`             | `int`            | SQL-Aggregat: Summe aller Wiederholungen             |
| `_bestDayReps`           | `int`            | SQL-Aggregat: Maximum einer täglichen Summe          |
| `_avgDailyReps`          | `double`         | SQL-Aggregat: Durchschnitt täglicher Summen          |

**Stats** (`totalCount`, `bestDayCount`, `averageDailyCount`) werden via SQL-Aggregat berechnet — immer korrekt, unabhängig davon wie viele Seiten geladen sind.

**Paginierung**: `loadHistoryFromDb()` lädt die erste Seite (500 Einträge) und alle Stats parallel; `loadMoreHistory()` hängt die nächste Seite an wenn `hasMoreHistory == true`.

Zählpfade:
- **Näherungssensor** (`_onProximityRep`): setzt `_lastProximityRepTime`, ruft `_countRep()`
- **Screen-Tap** (`incrementCount()`): überspringt, wenn `_lastProximityRepTime < 700 ms`; sonst `_countRep()`
- **`_countRep()`**: verifyPushUp → RepDetail-Buffer → count++ → notifyListeners()

Weitere Methoden: `loadActiveProgram()`, `saveActiveProgram()`, `stepDifficulty()`, `recordSetSplit()`, `saveWorkout()` (gibt `Workout` zurück), `importFromPuud()`, `clearAllData()`

**`SettingsProvider`** (`lib/logic/settings_provider.dart`)

Persistiert alle Benutzereinstellungen in SharedPreferences:

| Gruppe          | Einstellungen                                                             |
|-----------------|---------------------------------------------------------------------------|
| Erscheinungsbild| `themeMode` (dark/light/system), `locale` (de/en)                        |
| Audio           | `audioEnabled`, `repSoundEnabled`, `audioVolume`                          |
| Benachrichtigungen | `notificationsEnabled`, `reminderHour`, `reminderMinute`               |
| Training        | `restSecondsEasy/Normal/Hard` (überschreiben TrainingData-Defaults), `sensorThreshold` |

`toBackupMap()` / `restoreFromBackup()` für Integration mit BackupService.

**`AudioService`** (`lib/logic/audio_service.dart`)

Singleton mit Pre-loaded-Audio-Pool für minimale Latenz:

| Methode            | Ton        | Verwendung                                   |
|--------------------|------------|----------------------------------------------|
| `playRepTick()`    | 880 Hz, 60 ms  | Jede Wiederholung                        |
| `playCountdown()`  | 660 Hz, 110 ms | 3 / 2 / 1 s vor Pause-Ende              |
| `playRestEnd()`    | 1100 Hz, 300 ms| Pause abgelaufen, nächster Satz           |
| `playTargetReached()` | 1320 Hz, 200 ms | Satzziel erstmals erreicht          |

Töne werden zur Laufzeit als WAV-Bytes synthetisiert (kein Asset nötig). Drei `AudioPlayer` im Round-Robin für überlappende Rep-Ticks. Android-spezifisch: `AndroidAudioFocus.gainTransientMayDuck` für geringe Latenz.

**`ShareService`** (`lib/logic/share_service.dart`)

Statische Hilfsklasse zum Teilen eines Workout-Bildes:
1. `captureAndShare(GlobalKey repaintKey)` — rendert den an `repaintKey` gebundenen `RepaintBoundary` mit 3× Pixelratio
2. Speichert als PNG in `getTemporaryDirectory()`
3. Öffnet System-Share-Dialog via `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`

**`NotificationService`** (`lib/logic/notification_service.dart`)

Täglich wiederkehrende Erinnerung via `flutter_local_notifications` + `timezone`. Wird in `main.dart` initialisiert.

---

### 4.4 UI

**`DashboardScreen`**
- Stats-Zeile oben: Best Record / Total / Average
- Aktives Level (tippbar → öffnet LevelPickerScreen)
- Verlaufsliste mit `WorkoutStatCard`
- Navigation: TRAINING (strukturiert) · PRACTICE (freies Training) · RECORD (Monatsdiagramm)
- AppBar: Einstellungen-Icon; in Settings: CSV-Export, .apxbak-Export/-Import, .puud-Import, Daten löschen

**`WorkoutScreen`**
- **Freies Training**: schwarzer Vollbild-Tap-Zähler, FINISH-Button
- **Strukturiertes Training**:
  - Aktiver Satz: `Satz N von 5 – Ziel X Wdh.`, großer Zähler (grün bei Zielerreichung), SATZ/TRAINING-ABSCHLIESSEN-Button, Abbrechen-Link
  - Pause: Countdown (orange bei ≤ 3 s), Vorschau nächster Satz, PAUSE ÜBERSPRINGEN
  - Audio: Rep-Tick, Countdown 3-2-1, Pause-Ende, Ziel-Ton
- Post-Training-Flow: SessionDetailScreen → Schwierigkeitsfeedback-Dialog → ggf. Level-Änderung → Dashboard

**`LevelPickerScreen`**
- 8 Level-Sektionen, je 3 Einheitszeilen (z.B. `3-2: E: 13-10-11-11-10 | N: ... | H: ...`)
- Schwierigkeits-Chips farbkodiert: grün (Easy), orange (Normal), rot (Hard)
- ÜBERNEHMEN → `provider.saveActiveProgram()`

**`RecordScreen`**
- Monats-Navigation: ◄ / ► Buttons + horizontales Wischen (Swipe)
- Liest History via `context.watch<WorkoutProvider>().history` (kein Parameter mehr)
- Ruft `provider.loadMoreHistory()` auf, wenn der Nutzer in einen Monat navigiert der älter als die ältesten geladenen Daten ist
- Tabs: Liegestütze | Kalorien (× 0,5 kcal/Wdh.)
- `MonthlyComboChart`: 31 Slots (feste Breite), Balken pro Trainingstag, Farbe primär/gedimmt/transparent
- Tap auf Balken → SessionDetailScreen; mehrere Sessions am Tag → Bottom-Sheet-Picker

**`SessionDetailScreen`**
- Summary-Karte: Datum, Level, Gesamtreps, Dauer, Kalorien
- Satztabelle (wenn `splits` vorhanden): Ziel vs. Erreicht, Pass/Fail-Icon
- **Share-Button** (AppBar-Icon): öffnet Bottom Sheet mit `ShareCard`-Vorschau; Capture via `ShareService.captureAndShare()` erfolgt **vor** dem Schließen des Sheets (Widget muss im Tree sein)
- Post-Training: mit Splits (direkt nach Workout)
- Historisch: ohne Splits (aus RecordScreen geöffnet)

**`ShareCard`** (`lib/ui/widgets/share_card.dart`)
- Branded dark Card (360 px breit, fester Hintergrund `#0E0E1A`/`#1A1A2E`)
- Inhalt: App-Logo + Name, Datum, große Wiederholungszahl, Push-Up-Label, Level, Dauer-Chip, Kalorien-Chip
- Design ist **theme-unabhängig** — sieht im hellen und dunklen App-Theme immer gleich aus

**`SettingsScreen`** / **`NotificationScreen`** / **`AboutScreen`**
- Theme, Sprache (DE/EN)
- Audio-Toggle, Lautstärke-Slider, Rep-Sound-Toggle
- Ruhezeiten per Schwierigkeit (Easy/Normal/Hard)
- Sensor-Schwellwert (Slider)
- Benachrichtigungen (Zeit-Picker)
- Backup-Aktionen: Export, Import, .puud, CSV, Löschen
- App-Version via `package_info_plus`

---

## 5. App-Flow

```
App-Start
    ├── AudioService.init() (WAV-Pool pre-load)
    ├── NotificationService.init()
    └── MultiProvider → DashboardScreen
            ├── WorkoutProvider.loadHistoryFromDb()
            └── WorkoutProvider.loadActiveProgram()

DashboardScreen
    ├── [TRAINING] → WorkoutScreen(isFreeTraining: false)
    │       ├── startWorkout() → SensorService.init() + proximityRepCallback
    │       ├── Rep: Proximiy-Sensor → _onProximityRep() → _countRep()
    │       │         oder Tap → incrementCount() (Debounce 700ms)
    │       ├── [SATZ ABSCHLIESSEN] → recordSetSplit() → Rest-Timer
    │       └── [TRAINING ABSCHLIESSEN / ABBRECHEN]
    │               → saveWorkout() → SessionDetailScreen
    │               → Feedback-Dialog → stepDifficulty()
    │               → [ggf.] Level-Changed-Dialog → Dashboard
    │
    ├── [PRACTICE] → WorkoutScreen(isFreeTraining: true)
    │       └── (gleich, ohne Satzstruktur, ohne Post-Training-Detail)
    │
    ├── [RECORD] → RecordScreen
    │       ├── Swipe / ◄ ► → Monat wechseln
    │       └── Tap Balken → SessionDetailScreen (historisch)
    │
    └── [⚙] → SettingsScreen
            ├── Backup-Export → BackupService.exportBackup()
            ├── Backup-Import → BackupService.importBackup()
            ├── .puud-Import  → WorkoutProvider.importFromPuud()
            └── Daten löschen → WorkoutProvider.clearAllData()
```

---

## 6. Datenbankschema

**Schema-Version: 6**

```sql
CREATE TABLE workouts (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    date            TEXT    NOT NULL,        -- ISO-8601
    count           INTEGER NOT NULL,
    duration        INTEGER NOT NULL,        -- Sekunden
    rpm             REAL    NOT NULL,
    isImported      INTEGER NOT NULL DEFAULT 0,
    isVerified      INTEGER NOT NULL DEFAULT 0,
    isFreeTraining  INTEGER NOT NULL DEFAULT 0,
    levelId         TEXT,                    -- z.B. "3-2", NULL bei freiem Training
    difficulty      TEXT                     -- "Easy"/"Normal"/"Hard", NULL bei freiem Training
);

CREATE INDEX IF NOT EXISTS idx_workouts_date ON workouts(date);

CREATE TABLE rep_details (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id    INTEGER NOT NULL,
    rep_index     INTEGER NOT NULL,         -- 0-basiert, innerhalb Session
    set_index     INTEGER NOT NULL DEFAULT 0,
    timestamp_ms  INTEGER NOT NULL,         -- ms seit Sessionstart
    peak_g        REAL    NOT NULL,
    is_near       INTEGER NOT NULL DEFAULT 0,
    proximity_val REAL    NOT NULL DEFAULT 0,
    FOREIGN KEY (workout_id) REFERENCES workouts(id)
);
```

Migrationshistorie: v1 (Gemini-Stand) → v2 (isFreeTraining, levelId, difficulty) → v3 (rep_details) → v4 (proximity_val) → v5 (set_index) → v6 (Index `idx_workouts_date`)

---

## 7. Abhängigkeiten

| Paket                        | Verwendung                                       |
|------------------------------|--------------------------------------------------|
| `provider ^6.0.0`            | State-Management                                 |
| `sqflite`                    | Lokale SQLite-Datenbank                          |
| `shared_preferences`         | Einstellungen, aktives Level                     |
| `sensors_plus`               | Beschleunigungsmesser (userAccelerometer)        |
| `proximity_sensor`           | Näherungssensor (primärer Rep-Trigger)           |
| `audioplayers`               | Pre-loaded WAV-Playback                          |
| `fl_chart`                   | Balkendiagramm im RecordScreen                   |
| `archive`                    | ZIP für .apxbak und .puud                        |
| `crypto`                     | SHA-256 Prüfsummen im Backup                     |
| `csv`                        | CSV-Parsing und -Generierung                     |
| `file_picker ^11.0.2`        | Dateiauswahl (Import) + SAF Save (Export)        |
| `share_plus`                 | System-Share für CSV-Export und Workout-Bilder   |
| `path_provider`              | Temp-Verzeichnis                                 |
| `path`                       | Pfad-Utilities für SQLite                        |
| `flutter_local_notifications`| Tägliche Erinnerungen                            |
| `timezone`                   | Zeitzonensupport für Notifications               |
| `intl`                       | Datumsformatierung (DE/EN)                       |
| `flutter_native_splash`      | Splash Screen                                    |
| `package_info_plus`          | App-Version im About-Screen                      |
| `url_launcher`               | Links im About-Screen                            |

---

## 8. Offene Punkte & bekannte Bugs

### Feature-Lücken

| # | Feature                         | Status | Details                                                                      |
|---|---------------------------------|--------|------------------------------------------------------------------------------|
| F1 | Bewegungsanalyse-Graph         | ✅ | SessionDetailScreen zeigt Sensor-Chart (peakG + proximity über Zeit)         |
| F2 | Practice-Flow mit Empfehlung   | ✅ | Level-Empfehlung nach freiem Training implementiert                          |
| F3 | Wochenübersicht                | 🔄 | Mo–So-Ansicht im Dashboard vorhanden; ggf. Erweiterung (Streak, Vorwoche)   |
| F4 | Share-Feature (Phase 1)        | ✅ | Share-Karte via RepaintBoundary → PNG → share_plus in SessionDetailScreen    |
| F4 | Strava-Integration (Phase 2)   | ⏳ | OAuth2 + Strava API — noch nicht begonnen                                    |

### Bekannte Bugs / Verbesserungsbedarf

| # | Problem                               | Status | Details                                                                   |
|---|---------------------------------------|--------|---------------------------------------------------------------------------|
| B1 | Keine Paginierung der Verlaufsliste  | ✅ | Paginierung (500er Seiten) + SQL-Aggregat-Stats implementiert              |
| B2 | Kein DB-Index auf `date`             | ✅ | Index `idx_workouts_date` in Schema v6 (onCreate + Migration)              |
| B3 | RecordScreen ohne Line-Overlay       | ➖ | Bewusst nicht angegangen (Aufwand > Nutzen)                               |
| B4 | Proximity-Invertierung geräteabhängig| ✅ | Auto-Polarity-Erkennung beim ersten Sensor-Event in `SensorService.init()` |
