# ApexPush

Liegestützen-Tracking-App für Android, entwickelt mit Flutter.

ApexPush ersetzt die ursprüngliche "Push Ups"-App und erweitert sie um strukturierte Trainingspläne, satzbasiertes Training mit Audio-Feedback und eine detaillierte Sensordatenerfassung.

---

## Implementierte Features

### Training
- **Näherungssensor-Zählung** – Wiederholungen werden registriert, sobald Nase/Brust sich dem Display nähert (vor physischem Berühren). Screen-Tap dient als stiller Fallback mit 700 ms Debounce.
- **Satzbasiertes Training** – 5 Sätze mit Zielvorgaben je nach gewähltem Level; automatischer Pause-Countdown zwischen Sätzen (Easy 30 s / Normal 60 s / Hard 120 s, in Einstellungen anpassbar)
- **Freies Training (Practice)** – Einfacher Tap-Zähler ohne Stufenbindung
- **Audio-Feedback** – Synthetisierte Töne: Klick pro Wiederholung, Countdown 3-2-1 vor Pause-Ende, Ton bei Satzbeginn und Zielerreichung; keine Audio-Assets nötig
- **Levelanpassung** – Nach jeder Session: Zu leicht / Passt / Zu schwer → stepUp / stepDown im 72-stufigen Programm

### Trainingspläne
- **72 Programme** (8 Level × 3 Einheiten × 3 Schwierigkeiten) – vollständig hartcodiert aus der Original-App
- **Level-Picker** – Vollständige 72-Einheiten-Auswahl mit Satzziel-Vorschau pro Chip
- **Schwierigkeits-Navigation** – Easy → Normal → Hard → nächste Einheit Easy (und zurück)

### Daten & Statistik
- **Lokale SQLite-Datenbank** (Schema v5) mit per-Rep-Sensordaten (`rep_details`)
- **Monatsdiagramm (Record)** – Balkendiagramm mit Navigation per Buttons oder Wischen; Tabs: Liegestütze / Kalorien
- **Session-Detailansicht** – Datum, Level, Reps, Dauer, Kalorien (0,5 kcal/Wdh.), Satz-Aufschlüsselung mit Ziel vs. Erreicht
- **Dashboard-Statistiken** – Best Record / Total / Durchschnitt pro Tag

### Import & Backup
- **Original-App-Import (.puud)** – ZIP-Archiv der "Push Ups"-App wird direkt eingelesen (1.100+ Einträge aus 2020–2026 importierbar)
- **Vollständiges Backup (.apxbak)** – ZIP mit Workouts, Rep-Details und Einstellungen; SHA-256-Prüfsummen; Konflikt-Erkennung und Deduplication beim Import; abwärtskompatibel zu Legacy-CSV
- **CSV-Export** – Teilen via System-Share-Dialog (workouts only, ohne rep_details)

### App
- **Einstellungen** – Theme (dunkel/hell/System), Sprache (DE/EN), Lautstärke, Ruhezeiten, Sensor-Schwellwert
- **Benachrichtigungen** – Tägliche Erinnerung zu konfigurierbarer Uhrzeit
- **Splash Screen** & App-Icon

---

## Geplante Features

| Feature                    | Status        |
|----------------------------|---------------|
| Bewegungsanalyse-Graph     | Daten werden erfasst, Graph fehlt noch |
| Practice → Level-Empfehlung| `recommendUnit()` implementiert, UI fehlt |
| Wochenübersicht            | Post-Training-Flow Zwischenschritt     |
| Strava-Integration         | Geplant (§10, REQUIREMENTS.md)         |

Vollständige Anforderungen: [REQUIREMENTS.md](REQUIREMENTS.md)  
Technische Dokumentation: [CODEBASE.md](CODEBASE.md)

---

## Projektstruktur

```
lib/
├── main.dart                        # Einstiegspunkt, Theme, Provider-Setup
├── l10n/app_localizations.dart      # DE/EN Lokalisierung
├── models/
│   ├── workout.dart                 # Workout, ActiveProgram
│   ├── training_data.dart           # 72 Programme, Navigation, Empfehlung
│   └── rep_detail.dart              # Per-Rep-Sensordaten
├── data/
│   ├── database_helper.dart         # SQLite Singleton (Schema v5)
│   ├── sensor_service.dart          # Näherung + Beschleunigung
│   ├── backup_service.dart          # .apxbak Export/Import
│   ├── csv_service.dart             # Legacy CSV-Export
│   └── puud_import_service.dart     # Original-App-Import
├── logic/
│   ├── workout_provider.dart        # Zentrales State-Management
│   ├── settings_provider.dart       # Einstellungen
│   ├── audio_service.dart           # Synthetisierte Töne (Singleton)
│   └── notification_service.dart    # Lokale Benachrichtigungen
└── ui/
    ├── dashboard_screen.dart
    ├── level_picker_screen.dart
    ├── record_screen.dart
    ├── session_detail_screen.dart
    ├── settings_screen.dart
    ├── notification_screen.dart
    ├── about_screen.dart
    ├── workout/workout_screen.dart
    └── widgets/
        ├── workout_stat_card.dart
        └── monthly_combo_chart.dart
```

---

## Datenimport aus der originalen "Push Ups"-App

Das Backup der originalen App (`.puud`-Datei) ist ein ZIP-Archiv:

- `PushUps_Mos.db` – SQLite mit `PushUpsRecord`-Tabelle
- `Preference.data` – App-Einstellungen (wird ignoriert)

```sql
-- Schema der Originaldatenbank
CREATE TABLE PushUpsRecord (
    _id     INTEGER PRIMARY KEY,
    year    INTEGER,
    month   INTEGER,
    day     INTEGER,
    target  INTEGER,  -- Einheit im Trainingsprogramm (0–23 → "1-1" bis "8-3")
    level   INTEGER,  -- Schwierigkeitslevel (0=Custom, 1=Easy, 2=Normal, 3=Hard)
    num     INTEGER,  -- Wiederholungen
    which   INTEGER   -- Typ: 1=frei, 2=Programm-Set, 3=Session-Total
);
```

---

## Entwicklung

```bash
flutter pub get
flutter run
```

**Voraussetzungen:** Flutter SDK ≥ 3.10.4, Dart ≥ 3.10.4  
**Tests:** `flutter test` (14 TrainingData Unit-Tests + 2 Sanity-Checks; kein Gerät nötig)
