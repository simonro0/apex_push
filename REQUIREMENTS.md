# ApexPush – Anforderungen

> Erstellt: 2026-05-13  
> Basis: Gespräch mit Simon Roder, Screenshots der Original-App

---

## Inhaltsverzeichnis

1. [Levelstruktur & Trainingspläne](#1-levelstruktur--trainingspläne)
2. [Navigation & Screens](#2-navigation--screens)
3. [Trainingsablauf](#3-trainingsablauf)
4. [Statistik & Graphen](#4-statistik--graphen)
5. [Bewegungsanalyse & Datensatz](#5-bewegungsanalyse--datensatz)
6. [Audio-Feedback](#6-audio-feedback)
7. [Datenmigration / Import](#7-datenmigration--import)
8. [Benachrichtigungen & Einstellungen](#8-benachrichtigungen--einstellungen)
9. [Prioritäten-Übersicht](#9-prioritäten-übersicht)
10. [Offene Fragen](#10-offene-fragen)

---

## 1. Levelstruktur & Trainingspläne

### 1.1 Aufbau

Das Stufensystem ist identisch zur Original-App übernommen:

- **8 Hauptlevel** (1–8), jedes mit **3 Wochen** (1–3)
- Jede Woche hat **3 Schwierigkeitsvarianten**: Easy / Normal / Hard
- Jede Variante besteht aus **5 Sätzen** (Wiederholungszahlen)
- Der 5. Satz ist in höheren Levels i.d.R. der Burnout-Satz (möglichst viele)

Gesamtanzahl Einheiten: **8 × 3 × 3 = 72 Programme**

### 1.2 Vollständige Satzmatrix

*(Werte aus Screenshots: Satz1-Satz2-Satz3-Satz4-Satz5)*

#### Level 1
| Einheit    | Easy        | Normal      | Hard          |
|------------|-------------|-------------|---------------|
| Week 1     | 2-2-2-2-3   | 6-6-5-4-5   | 9-9-8-6-7     |
| Week 2     | 4-3-2-2-4   | 8-8-6-5-7   | 11-11-9-9-10  |
| Week 3     | 5-4-4-3-5   | 9-8-8-5-9   | 14-12-10-10-14|

#### Level 2
| Einheit    | Easy        | Normal      | Hard          |
|------------|-------------|-------------|---------------|
| Week 1     | 4-5-4-4-5   | 8-7-5-4-6   | 11-11-8-6-9   |
| Week 2     | 6-5-3-4-6   | 10-8-6-7-9  | 12-12-10-10-12|
| Week 3     | 5-6-4-5-6   | 9-9-7-7-9   | 14-14-11-11-10|

#### Level 3
| Einheit    | Easy          | Normal        | Hard          |
|------------|---------------|---------------|---------------|
| Week 1     | 9-8-10-8-10   | 14-10-9-11-8  | 16-14-12-11-13|
| Week 2     | 13-10-11-11-10| 15-15-13-13-10| 18-15-14-13-17|
| Week 3     | 15-11-14-10-11| 20-14-14-12-18| 21-15-16-14-20|

#### Level 4
| Einheit    | Easy          | Normal        | Hard          |
|------------|---------------|---------------|---------------|
| Week 1     | 14-11-11-9-13 | 14-12-14-12-15| 20-16-18-15-22|
| Week 2     | 14-12-12-10-13| 20-12-14-13-16| 22-18-17-16-23|
| Week 3     | 18-11-13-12-13| 20-17-14-15-19| 25-19-18-18-24|

#### Level 5
| Einheit    | Easy          | Normal        | Hard          |
|------------|---------------|---------------|---------------|
| Week 1     | 21-18-14-13-19| 22-21-16-20-22| 26-22-18-21-25|
| Week 2     | 18-11-13-12-13| 13-12-10-8-28 | 15-14-12-10-32|
| Week 3     | 14-11-11-9-13 | 10-10-8-7-28  | 14-12-10-8-33 |

#### Level 6
| Einheit    | Easy          | Normal        | Hard          |
|------------|---------------|---------------|---------------|
| Week 1     | 25-21-20-18-25| 29-25-21-20-30| 34-26-24-21-32|
| Week 2     | 13-12-10-8-28 | 15-14-12-10-33| 16-14-11-10-36|
| Week 3     | 10-10-8-7-28  | 14-12-10-8-33 | 14-12-10-8-36 |

#### Level 7
| Einheit    | Easy          | Normal        | Hard          |
|------------|---------------|---------------|---------------|
| Week 1     | 30-21-26-18-25| 34-25-21-25-35| 41-26-33-25-35|
| Week 2     | 25-14-10-8-23 | 13-14-11-10-33| 20-18-11-10-28|
| Week 3     | 19-12-10-8-28 | 14-12-10-8-30 | 14-12-10-18-36|

#### Level 8
| Einheit    | Easy          | Normal        | Hard          |
|------------|---------------|---------------|---------------|
| Week 1     | 36-28-25-24-33| 46-36-32-34-46| 52-41-38-36-52|
| Week 2     | 18-16-13-11-38| 21-18-18-14-46| 26-21-21-18-52|
| Week 3     | 24-21-19-18-46| 27-24-24-20-54| 31-27-27-24-60|

> **Hinweis:** Simon ist aktuell auf **Level 8-3 (Easy)** (markierter Eintrag in den Screenshots).

### 1.3 Ruhezeiten zwischen Sätzen

Die Ruhezeiten sind in den Screenshots nicht sichtbar. Vorgabe: mit realistischen Standardwerten implementieren (z.B. 60s/90s/120s je nach Level-Gruppe). Genaue Werte mit Simon abstimmen.

*Vorschlag:*
- Level 1–2: 60 Sekunden
- Level 3–5: 90 Sekunden
- Level 6–8: 120 Sekunden

### 1.4 Einstieg

Zwei Wege zum Einstieg in ein Level:

1. **Direkte Auswahl** aus der Levelübersicht (Tabelle wie in Original-App)
2. **Einschätzungstest** via freier Übungsrunde (Practice): das Ergebnis wird automatisch einem passenden Level zugeordnet

---

## 2. Navigation & Screens

### 2.1 Dashboard (Hauptscreen)

```
┌─────────────────────────────────────────┐
│  [Statistik-Zusammenfassung top-left]   │  🔔  ⚙️ │
│                                         │
│  [TRAINING]   [PRACTICE]   [RECORD]     │
│                                         │
│  ... Verlaufsliste / Wochenüberblick    │
└─────────────────────────────────────────┘
```

**Statistik-Block (oben links):**
- Aktuelle Woche / Streak
- Gesamtwiederholungen
- Aktuelles Level

**Icons oben rechts:**
- 🔔 → Benachrichtigungseinstellungen
- ⚙️ → App-Einstellungen

### 2.2 Navigation

| Button       | Aktion |
|--------------|--------|
| **Training** | Heutiges Training fortsetzen. Falls noch kein Training für heute: Levelauswahl anzeigen (oder freie Einschätzungsrunde anbieten) |
| **Practice** | Jederzeit freie Übungsrunde starten (ohne Stufenbindung) |
| **Record**   | Wochenansicht mit grafischer Darstellung der Trainingstage |

---

## 3. Trainingsablauf

### 3.1 Satzbasiertes Training

1. Satz-Zielanzeige (z.B. „Satz 2 von 5 – Ziel: 21 Wiederholungen")
2. Nutzer tippt Wiederholungen (Nase/Brust auf Display)
3. Ton pro verifizierter Wiederholung
4. Bei 6 verbleibenden Reps: aufsteigende Countdown-Töne
5. Nach letzter Wiederholung: Satz abgeschlossen
6. **Pause-Countdown** mit definierter Erholungszeit (visuell + Ton bei 3-2-1)
7. Nutzer kann Pause verkürzen oder überspringen
8. Nächster Satz startet

### 3.2 Abbruch & Fortsetzung

- **Jederzeit abbrechen** möglich → Rückfrage: „Level anpassen?"
- **Nach letztem Satz: Weitermachen** möglich (Burnout-Bonus-Set)
- Nach Abschluss oder Abbruch: Rückfrage Levelanpassung

### 3.3 Post-Training-Flow

```
Training beendet
    │
    ▼
Detailansicht der Session (Sätze, Reps, Timing, Graphen)
    │
    ▼
Wochenübersicht (grafisch)
    │
    ▼
Rückfrage: Level anpassen? (Beibehalten / Leichter / Schwerer)
    │
    ▼
Dashboard
```

---

## 4. Statistik & Graphen

### 4.1 Wochenansicht (Record-Tab)

- 7 Tage als Balken- oder Kreisdiagramm
- Je Tag: absolvierte Reps vs. Ziel
- Klick auf einen Tag → Detailansicht dieser Session

### 4.2 Session-Detailansicht

Erreichbar aus:
- Post-Training-Flow (direkt nach Training)
- Record-Tab (historisch)

Inhalt:
- Satzweise Auflistung (Ziel vs. Erreicht)
- Timing pro Satz
- Bewegungsqualitäts-Graph (sofern Sensordaten vorhanden, siehe Abschnitt 5)

---

## 5. Bewegungsanalyse & Datensatz

### 5.1 Zusätzliche Sensordaten pro Wiederholung

| Messgröße | Quelle | Zweck |
|---|---|---|
| Zeitstempel | Systemzeit | Rhythmus, Intervalle |
| Intervall seit letzter Wdh. (ms) | Berechnung | Tempoabfall erkennen |
| Peak-Beschleunigung (aufwärts) | Accelerometer | Krafteinsatz |
| Min-Beschleunigung (unterste Pos.) | Accelerometer | Bewegungstiefe |
| Std.-Abweichung der Beschleunigung | Berechnung | Ruckigkeit / Gleichmäßigkeit |

### 5.2 Datenbankschema (Erweiterung)

```sql
CREATE TABLE rep_details (
    id           INTEGER PRIMARY KEY,
    workout_id   INTEGER REFERENCES workouts(_id),
    set_index    INTEGER,
    rep_index    INTEGER,
    timestamp_ms INTEGER,
    interval_ms  INTEGER,
    peak_accel   REAL,
    min_accel    REAL,
    accel_stddev REAL,
    is_verified  INTEGER
);
```

### 5.3 Analyse-Graph

- X-Achse: Wiederholungsnummer
- Linie 1: Intervall (ms) zwischen Wiederholungen → zeigt Ermüdung
- Linie 2: Peak-Beschleunigungsamplitude → zeigt Bewegungstiefe
- Optionale Warnung bei deutlichem Qualitätsabfall

---

## 6. Audio-Feedback

| Ereignis | Ton |
|---|---|
| Verifizierte Wiederholung | Kurzer Bestätigungston |
| Nicht verifizierte Wiederholung | Kein Ton (oder abweichendes Signal) |
| Wiederholung 6 vor Satzende | Ton 1 (tiefste Note) |
| Wiederholung 5 vor Satzende | Ton 2 |
| ... | ... |
| Letzte Wiederholung im Satz | Ton 6 (höchste Note) |
| Pause-Countdown 3-2-1 | Drei absteigende Töne |
| Satz abgeschlossen | Kurze Melodie / Abschluss-Ton |

**Implementierung:** `audioplayers`-Package, eigene kurze WAV/MP3-Dateien oder synthetisch generierte Töne über `dart:math` + Audio-Plugin.

---

## 7. Datenmigration / Import

### 7.1 Import aus `.puud`-Backup (Priorität: HOCH)

**Dateiformat:** ZIP-Archiv mit `PushUps_Mos.db` (SQLite)

**Schema der Original-Datenbank:**
```sql
CREATE TABLE PushUpsRecord (
    _id    INTEGER PRIMARY KEY,
    year   INTEGER,
    month  INTEGER,
    day    INTEGER,
    target INTEGER,  -- Programm-Schritt (0–23)
    level  INTEGER,  -- Schwierigkeitslevel (0=Custom, 1=Beginner, 2=Advanced)
    num    INTEGER,  -- Anzahl Wiederholungen
    which  INTEGER   -- 1=freie Einheit, 2=Programm-Set, 3=Session-Total
);
```

**Mapping:**
- `which=1`: freie Einheiten (~20 Reps Ø) → als freies Training importieren
- `which=3`: Session-Totals (~107 Reps Ø im Custom-Modus) → als Haupt-Import

**Vorgehensweise:**
1. Datei-Picker für `.puud`-Dateien öffnen
2. ZIP-Eintrag `PushUps_Mos.db` in temporäres Verzeichnis extrahieren
3. SQLite-Abfrage ausführen
4. Als `Workout(isImported: true)` in lokale DB schreiben

### 7.2 CSV-Export / -Import

- Bestehende Implementierung (`csv_service.dart`) beibehalten und robuster machen
- Fehlerbehandlung und Format-Validierung ergänzen

---

## 8. Benachrichtigungen & Einstellungen

### 8.1 Benachrichtigungen (🔔)

- Tägliche Erinnerung zur konfigurierbaren Uhrzeit
- An/Aus, Uhrzeit, Klingelton/Vibration
- (Entspricht `alarm_settings`-Tabelle im Original-Backup)

### 8.2 Einstellungen (⚙️)

- Ruhezeiten zwischen Sätzen anpassen
- Sensor-Schwellenwert kalibrieren
- Theme (Hell/Dunkel)
- Einheit (Metrisch/Imperial falls relevant)
- Datenmigration (Import-Button)

---

## 9. Prioritäten-Übersicht

| # | Feature | Priorität | Abhängigkeiten |
|---|---------|-----------|----------------|
| 1 | `.puud`-Import (Datenmigration) | **HOCH** | – |
| 2 | Levelstruktur als Datenmodell | **HOCH** | – |
| 3 | Satzbasiertes Training + Pausen-Countdown | **HOCH** | #2 |
| 4 | Einstiegsstufen-Auswahl / Level-Picker | **HOCH** | #2 |
| 5 | Dashboard (Training / Practice / Record) | **HOCH** | #3 |
| 6 | Ton pro Wiederholung + Countdown-Töne | **MITTEL** | – |
| 7 | Post-Training-Flow (Detail → Woche → Anpassung) | **MITTEL** | #3, #4 |
| 8 | Wochenansicht (Record) | **MITTEL** | #5 |
| 9 | Erweiterte Sensordaten pro Rep | **MITTEL** | – |
| 10 | Analyse-Graph | **NIEDRIG** | #9 |
| 11 | Benachrichtigungen | **NIEDRIG** | – |
| 12 | CSV-Import/-Export (robuster) | **MITTEL** | – |

---

## 10. Offene Fragen

1. **Ruhezeiten**: Welche genauen Sekunden sollen zwischen den Sätzen je Level-Gruppe gelten? (Vorschlag: 60s/90s/120s)

2. **`.puud`-Import**: Sollen `which=1` (freie Einheiten) und `which=3` (Totals) beide importiert werden, oder nur einer? Sollen sie unterschiedlich gekennzeichnet werden?

3. **Levelfortschritt**: Wechselt die App automatisch zur nächsten Woche/Stufe nach Abschluss, oder muss der Nutzer das manuell bestätigen?

4. **Practice-Einschätzung**: Nach einer freien Runde – welche Logik soll den empfohlenen Einstiegslevel bestimmen? (z.B. max. Reps < X → Level 1 Easy, etc.)

5. **Analyse-Graph**: Direkt nach Training anzeigen oder nur auf Abruf in der Detailansicht?

6. **Statistische Zusammenfassung**: Welche konkreten Kennzahlen sollen im Dashboard-Block oben links stehen? (Woche, Streak, Gesamtreps, aktuelles Level?)
