# ApexPush – Codebase-Dokumentation

> Erstellt: 2026-05-13  
> Basis: Erster Stand nach Gemini-generiertem Code

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
6. [Abhängigkeiten](#6-abhängigkeiten)
7. [Bekannte Mängel und offene Punkte](#7-bekannte-mängel-und-offene-punkte)
8. [Nicht umgesetzte Teile](#8-nicht-umgesetzte-teile)

---

## 1. Projektbeschreibung

**ApexPush** ist eine Flutter-App zur Liegestützen-Verfolgung mit adaptiver Schwierigkeitsanpassung.

Das Kernkonzept:

- Der Nutzer tippt während der Übung mit Nase oder Brust auf das Display, um jede Wiederholung zu zählen.
- Sensoren (Näherungssensor + Beschleunigungsmesser) verifizieren, ob die Bewegung „echt" war (Anti-Cheat).
- Nach jeder Session bewertet der Nutzer die Schwierigkeit (zu leicht / genau richtig / zu schwer).
- Die App passt das Tagesziel automatisch an.
- Historische Daten werden lokal per SQLite gespeichert und können als CSV exportiert/importiert werden.

---

## 2. Verzeichnisstruktur

```
apex_push/
├── lib/
│   ├── main.dart                          # Einstiegspunkt, Theme, Provider-Setup
│   ├── models/
│   │   └── workout.dart                   # Datenmodelle: Workout, TrainingPlan
│   ├── data/
│   │   ├── database_helper.dart           # SQLite-Wrapper (Singleton)
│   │   ├── sensor_service.dart            # Näherung + Beschleunigung
│   │   └── csv_service.dart               # CSV-Export und -Import
│   ├── logic/
│   │   ├── workout_provider.dart          # Zentrales State-Management (ChangeNotifier)
│   │   └── progression_engine.dart        # Algorithmus für Zielanpassung
│   └── ui/
│       ├── dashboard_screen.dart          # Startbildschirm (Ziel + Verlauf)
│       ├── widgets/
│       │   └── workout_stat_card.dart     # ListTile-Karte für einen Workout-Eintrag
│       ├── workout/
│       │   └── workout_screen.dart        # Live-Trainingsbildschirm
│       └── plan_configurator/
│           └── adjust_dialog.dart         # Dialog für Zielanpassung (aktuell ungenutzt)
├── test/
│   └── widget_test.dart                   # Platzhalter-Test (nicht app-relevant)
├── pubspec.yaml
└── README.md
```

---

## 3. Architekturüberblick

Die App folgt einem einfachen Schichtenmodell:

```
┌─────────────────────────────────────┐
│              UI-Schicht             │  dashboard_screen, workout_screen, widgets
├─────────────────────────────────────┤
│           Logic-Schicht             │  workout_provider (Provider), progression_engine
├─────────────────────────────────────┤
│            Data-Schicht             │  database_helper (SQLite), sensor_service, csv_service
├─────────────────────────────────────┤
│            Modell-Schicht           │  Workout, TrainingPlan
└─────────────────────────────────────┘
```

**State-Management:** Flutter Provider (`ChangeNotifier`). Der `WorkoutProvider` hält den gesamten App-Zustand und wird über `ChangeNotifierProvider` in `main.dart` bereitgestellt.

---

## 4. Schichten im Detail

### 4.1 Models

**`Workout`** (`lib/models/workout.dart`)

| Feld             | Typ      | Beschreibung                              |
|------------------|----------|-------------------------------------------|
| `id`             | `int?`   | Datenbankprimärschlüssel                  |
| `date`           | `DateTime` | Zeitstempel der Session                 |
| `count`          | `int`    | Anzahl gezählter Wiederholungen           |
| `durationSeconds`| `int`    | Dauer der Session in Sekunden             |
| `avgRpm`         | `double` | Wiederholungen pro Minute                 |
| `isImported`     | `bool`   | Kennzeichnung als CSV-Import              |
| `isVerified`     | `bool`   | Mindestens eine Wdh. sensorverifiziert    |

Methoden: `toMap()` (DB-Serialisierung), `fromCsv()` (Factory-Konstruktor).

**`TrainingPlan`** (`lib/models/workout.dart`)

| Feld                   | Typ      | Beschreibung                        |
|------------------------|----------|-------------------------------------|
| `dailyTarget`          | `int`    | Tagesziel (Wiederholungen)          |
| `difficultyMultiplier` | `double` | **Definiert, aber nirgends genutzt** |

---

### 4.2 Data

**`DatabaseHelper`** (`lib/data/database_helper.dart`)

- Singleton-Pattern, SQLite via `sqflite`
- Tabelle `workouts` mit 7 Spalten
- Operationen: `createWorkout()`, `readAllWorkouts()` (absteigend nach Datum), `close()`
- Schema-Version 1, kein Migrationspfad definiert

**`SensorService`** (`lib/data/sensor_service.dart`)

Kombiniert zwei Sensoren zur Rep-Verifikation:

```
Näherungssensor (_isNear = true)
        +
Beschleunigungsmesser (|a| > 12,0 m/s²)
        =
verifyPushUp() → true
```

- Schwellenwert 12,0 m/s² ist hardcoded
- Sensor-Subscriptions werden als `StreamSubscription` verwaltet
- `dispose()` existiert, muss aber vom Provider aufgerufen werden

**`CsvService`** (`lib/data/csv_service.dart`)

- Export: Workout-Liste → CSV-Datei → `share_plus`-Dialog
- Import: `file_picker` → CSV-Parser → `List<Workout>`
- Spalten: `date, count, duration_seconds, avg_rpm, is_verified`

---

### 4.3 Logic

**`ProgressionEngine`** (`lib/logic/progression_engine.dart`)

| Nutzerfeedback | Formel              | Effekt   |
|----------------|---------------------|----------|
| "Too Hard"     | `target × 0.90`     | −10 %    |
| "Just Right"   | `target × 1.05`     | +5 %     |
| "Too Easy"     | `target × 1.20`     | +20 %    |

Ergebnis wird auf `int` gerundet.

**`WorkoutProvider`** (`lib/logic/workout_provider.dart`)

Zentraler ChangeNotifier. Hält:

| Zustand               | Typ            | Beschreibung                         |
|-----------------------|----------------|--------------------------------------|
| `_currentSessionCount`| `int`          | Zähler der aktuellen Session         |
| `_startTime`          | `DateTime?`    | Startzeitpunkt                       |
| `_lastRepVerified`    | `bool`         | Sensor-Ergebnis der letzten Wdh.     |
| `_history`            | `List<Workout>`| Geladene Workout-Historie            |
| `_currentPlan`        | `TrainingPlan` | Aktives Tagesziel                    |

Schlüsselmethoden:

| Methode                    | Beschreibung                                      |
|----------------------------|---------------------------------------------------|
| `startWorkout()`           | Sensoren initialisieren, Timer starten            |
| `incrementCount()`         | Zähler erhöhen + Verifikation prüfen              |
| `saveWorkout()`            | In SQLite persistieren, RPM berechnen             |
| `adjustDifficulty(String)` | Progression Engine aufrufen, Plan aktualisieren   |
| `updatePlanManual(int)`    | Direktes Überschreiben des Ziels                  |
| `saveNewPlan(int)`         | Ziel in SharedPreferences speichern               |
| `saveMultipleWorkouts()`   | Batch-Import aus CSV                              |
| `loadHistoryFromDb()`      | Historie beim App-Start laden                     |
| `loadPlan()`               | Tagesziel aus SharedPreferences laden             |

---

### 4.4 UI

**`DashboardScreen`** (`lib/ui/dashboard_screen.dart`)

- Zeigt das aktuelle Tagesziel (48 pt, prominent)
- `ListView` der bisherigen Workouts via `WorkoutStatCard`
- Icons für CSV-Export (Upload) und CSV-Import (Download)
- FAB „START TRAINING" → navigiert zu `WorkoutScreen`
- Lädt Verlauf und Plan in `initState` via `addPostFrameCallback`

**`WorkoutScreen`** (`lib/ui/workout/workout_screen.dart`)

- Schwarzer Vollbild-Hintergrund
- Riesiger Zähler (180 pt) – Tap zählt Wiederholung
- Hinweis: „TAP WITH NOSE / CHEST"
- „FINISH SESSION"-Button → Feedback-Dialog
- Post-Workout-Flow:
  1. Workout speichern
  2. Schwierigkeitsfeedback einholen (Tough / Perfect / Easy)
  3. Neue Zielanpassung anzeigen (alt → neu)
  4. Bestätigen oder zurücksetzen

**`WorkoutStatCard`** (`lib/ui/widgets/workout_stat_card.dart`)

- `ListTile` mit Icon (importiert vs. lokal), Rep-Anzahl, Datum/RPM, Verifikationsstatus

**`AdjustDialog`** (`lib/ui/plan_configurator/adjust_dialog.dart`)

- Zeigt altes → neues Ziel und bietet Accept/Decline
- **Nicht importiert/eingebunden** – tote Code-Datei

---

## 5. App-Flow

```
App-Start
    │
    ▼
DashboardScreen
    ├── loadHistoryFromDb()
    ├── loadPlan()
    │
    ├── [FAB] START TRAINING
    │       │
    │       ▼
    │   WorkoutScreen
    │       ├── startWorkout() → Sensoren starten
    │       ├── [Tap] incrementCount() → Zähler + Verifikation
    │       └── [FINISH] saveWorkout()
    │               │
    │               ▼
    │           Feedback-Dialog
    │               │
    │               ▼
    │           adjustDifficulty()
    │               │
    │               ▼
    │           Anpassungsvorschau
    │               ├── [Accept] saveNewPlan()
    │               └── [Decline] Plan bleibt
    │
    ├── [Upload-Icon] exportToCsv()
    └── [Download-Icon] importFromCsv() → saveMultipleWorkouts()
```

---

## 6. Abhängigkeiten

| Paket             | Version  | Verwendung                        |
|-------------------|----------|-----------------------------------|
| `provider`        | ^6.0.0   | State-Management                  |
| `sqflite`         | aktuell  | Lokale SQLite-Datenbank           |
| `shared_preferences` | aktuell | Tagesziel persistieren          |
| `sensors_plus`    | aktuell  | Beschleunigungsmesser             |
| `proximity_sensor`| aktuell  | Näherungssensor                   |
| `csv`             | aktuell  | CSV-Parsing                       |
| `file_picker`     | aktuell  | Dateiauswahl für Import           |
| `path_provider`   | aktuell  | Temp-Verzeichnis für Export       |
| `share_plus`      | aktuell  | System-Share-Dialog               |

---

## 7. Bekannte Mängel und offene Punkte

### Kritisch

| # | Problem | Datei | Beschreibung |
|---|---------|-------|--------------|
| K1 | `_startTime` ohne Null-Check | `workout_provider.dart` | `saveWorkout()` greift auf `_startTime` zu, ohne vorher auf `null` zu prüfen → potentieller Crash |
| K2 | Sensor-Dispose fehlt | `workout_provider.dart` | `SensorService.dispose()` wird im Provider-`dispose()` nicht aufgerufen → Memory Leak |
| K3 | Kein Datenbankmigrationsplan | `database_helper.dart` | Schema-Version 1, keine `onUpgrade`-Logik |

### Bedeutend

| # | Problem | Datei | Beschreibung |
|---|---------|-------|--------------|
| B1 | Toter Code | `adjust_dialog.dart` | Datei existiert, wird aber nirgends importiert oder genutzt |
| B2 | Ungenutzte Modelfelder | `workout.dart` | `TrainingPlan.difficultyMultiplier` definiert aber nie verwendet |
| B3 | Placeholder-Tests | `widget_test.dart` | Test erwartet einen Zähler-Widget, der in der App nicht existiert |
| B4 | Hardcodierter Sensor-Schwellenwert | `sensor_service.dart` | 12,0 m/s² ist nicht kalibrierbar; unterschiedliche Geräte liefern unterschiedliche Werte |
| B5 | Keine Fehlerbehandlung bei CSV-Import | `csv_service.dart` | Ungültige Dateiformate führen zu stillen Fehlern oder Abstürzen |
| B6 | Kein Paginierung der Historie | `database_helper.dart` | Alle Workouts werden bei jedem App-Start geladen |

### Minor

| # | Problem | Datei | Beschreibung |
|---|---------|-------|--------------|
| M1 | Englischsprachige UI | diverse | Alle UI-Texte auf Englisch, keine i18n-Vorbereitung |
| M2 | `_lastRepVerified` initial `true` | `workout_provider.dart` | Sollte `false` oder `null` sein für korrekte Semantik |
| M3 | Kein DB-Index auf `date` | `database_helper.dart` | Queries nach Datum sind langsam bei großen Datenmengen |
| M4 | README veraltet | `README.md` | Standard-Flutter-README, kein App-spezifischer Inhalt |

---

## 8. Nicht umgesetzte Teile

Folgende Konzepte sind im Code angedeutet, aber nicht fertig implementiert:

| Konzept | Stand | Hinweis |
|---------|-------|---------|
| `difficultyMultiplier` | Definiert, nicht genutzt | Gedacht für gewichteten Progressionsalgorithmus |
| Sensor-Kalibrierung | Kein UI vorhanden | Schwellenwert hardcoded |
| Mehrere Trainingspläne | Nur ein Plan möglich | `TrainingPlan` ohne Namensgebung oder Liste |
| Pausieren einer Session | Nicht implementiert | Kein Pause-Button im WorkoutScreen |
| Statistiken/Diagramme | Nicht vorhanden | Dashboard zeigt nur Rohliste |
| Benachrichtigungen | Nicht vorhanden | Keine tägliche Erinnerung |
| Authentifizierung | Nicht vorhanden | Rein lokal, kein Account |
