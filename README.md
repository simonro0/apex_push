# ApexPush

Liegestützen-Tracking-App für Android/iOS, entwickelt mit Flutter.

ApexPush ersetzt die ursprüngliche "Push Ups"-App und erweitert sie um strukturierte Trainingspläne, Sensordatenanalyse und einen detaillierten Bewegungsgraph.

---

## Features (aktueller Stand)

- **Trainingserfassung** – Tippe mit Nase oder Brust auf das Display, jede Berührung zählt als Wiederholung
- **Sensor-Verifikation** – Näherungssensor + Beschleunigungsmesser prüfen, ob die Bewegung echt ist (Anti-Cheat)
- **Adaptives Tagesziel** – Nach jeder Session bewertest du die Schwierigkeit; die App passt das Ziel automatisch an (−10 % / +5 % / +20 %)
- **Lokale Datenhaltung** – Workouts werden in SQLite gespeichert, das Tagesziel in SharedPreferences
- **CSV-Export / -Import** – Daten können als CSV-Datei geteilt oder importiert werden

---

## Geplante Features

Siehe [REQUIREMENTS.md](REQUIREMENTS.md) für die vollständige Anforderungsliste und [CODEBASE.md](CODEBASE.md) für den technischen Stand.

---

## Projektstruktur

```
lib/
├── main.dart                  # Einstiegspunkt
├── models/workout.dart        # Datenmodelle
├── data/
│   ├── database_helper.dart   # SQLite-Wrapper
│   ├── sensor_service.dart    # Sensoren (Näherung + Beschleunigung)
│   └── csv_service.dart       # CSV-Import/-Export
├── logic/
│   ├── workout_provider.dart  # State-Management (Provider)
│   └── progression_engine.dart# Schwierigkeitsalgorithmus
└── ui/
    ├── dashboard_screen.dart  # Startbildschirm
    ├── workout/workout_screen.dart
    └── widgets/workout_stat_card.dart
```

---

## Datenimport aus der originalen "Push Ups"-App

Das Backup der originalen App (`.puud`-Datei) ist ein ZIP-Archiv und enthält:

- `PushUps_Mos.db` – SQLite-Datenbank mit 1.104 Trainingseinträgen (2020–2026)
- `Preference.data` – binäre App-Einstellungen

### Datenbankschema der Originaldaten

```sql
CREATE TABLE PushUpsRecord (
    _id     INTEGER PRIMARY KEY,
    year    INTEGER,
    month   INTEGER,
    day     INTEGER,
    target  INTEGER,  -- Woche/Stufe im Trainingsprogramm (0–23)
    level   INTEGER,  -- Schwierigkeitslevel (0=Custom, 1=Beginner, 2=Advanced)
    num     INTEGER,  -- Anzahl Wiederholungen
    which   INTEGER   -- Typ: 1=freie Einheit, 2=Programm-Set, 3=Session-Total
);
```

ApexPush kann diese Datei direkt einlesen (ZIP entpacken → SQLite öffnen → Daten migrieren).

---

## Entwicklung

```bash
flutter pub get
flutter run
```

Voraussetzungen: Flutter SDK ≥ 3.10, Dart ≥ 3.0
