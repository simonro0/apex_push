# ApexPush – Anforderungen

> Erstellt: 2026-05-13  
> Basis: Gespräch mit Simon Roder

---

## Inhaltsverzeichnis

1. [Datenmigration / Import](#1-datenmigration--import)
2. [Strukturierte Trainingspläne](#2-strukturierte-trainingspläne)
3. [Bewegungsanalyse & Datensatz](#3-bewegungsanalyse--datensatz)
4. [Live-Workout-Feedback](#4-live-workout-feedback)
5. [Prioritäten-Übersicht](#5-prioritäten-übersicht)
6. [Offene Fragen](#6-offene-fragen)

---

## 1. Datenmigration / Import

### 1.1 Import aus `.puud`-Backup (Priorität: HOCH)

Die bisherige "Push Ups"-App speichert ein Backup als `.puud`-Datei – ein ZIP-Archiv mit einer SQLite-Datenbank `PushUps_Mos.db`.

**Vorhandene Daten:**
- 1.104 Trainingseinträge von Oktober 2020 bis Mai 2026
- Schema: `year, month, day, target, level, num, which`

**Mapping auf ApexPush-Modell:**

| Originalfeld | Bedeutung | ApexPush-Ziel |
|---|---|---|
| `year / month / day` | Datum | `Workout.date` |
| `num` | Wiederholungen der Session | `Workout.count` |
| `which = 1` | Freie Trainingseinheit | Hauptimport-Quelle |
| `which = 3` | Session-Total / Programmabschluss | Alternativ importierbar |
| `level` | Schwierigkeitslevel (0/1/2) | Metadaten-Feld (optional) |
| `target` | Programm-Woche (0–23) | Metadaten-Feld (optional) |

**Umsetzung:**
- Datei-Picker für `.puud`-Dateien öffnen
- ZIP-Eintrag `PushUps_Mos.db` in temporäres Verzeichnis extrahieren
- SQLite-Abfrage auf `PushUpsRecord` ausführen
- Daten als `Workout(isImported: true)` in lokale DB schreiben

**Alternativen (nachrangig):**
- CSV-Import mit eigenem Format → bereits teilweise implementiert
- Screenshot-Interpretation (OCR) → sehr aufwändig, nur als letzter Ausweg

### 1.2 CSV-Export / -Import (Priorität: MITTEL)

- Export und Import im einheitlichen ApexPush-CSV-Format sollen weiterhin funktionieren
- Bestehende Implementierung in `csv_service.dart` ist Basis, benötigt aber Fehlerbehandlung und Validierung

---

## 2. Strukturierte Trainingspläne

### 2.1 Satzbasierte Workouts mit Erholungszeiten (Priorität: HOCH)

Die originale App strukturierte Workouts in **5 Sätze** mit festgelegten Wiederholungszahlen und **abnehmenden Erholungszeiten** zwischen den Sätzen.

**Anforderungen:**
- Trainingspläne bestehen aus **N Sätzen** (Standard: 5)
- Jeder Satz hat eine definierte **Ziel-Wiederholungszahl**
- Zwischen den Sätzen wird ein **Countdown** angezeigt (Erholungszeit)
- Die Erholungszeiten nehmen mit steigendem Level **schrittweise ab**
- Die Gesamtwiederholungen und Satz-Wiederholungen steigen über die Levels **kontinuierlich an**

**Datenmodell (Erweiterung):**

```dart
class TrainingLevel {
  int id;
  String name;              // z.B. "Stufe 3 – Fortgeschrittene"
  List<TrainingSet> sets;   // 5 Sätze mit je Zielreps + Erholungszeit
}

class TrainingSet {
  int targetReps;
  Duration restDuration;    // Pause nach diesem Satz
}
```

**Beispiel-Stufenstruktur (angelehnt an Originale):**

| Stufe | Satz 1 | Satz 2 | Satz 3 | Satz 4 | Satz 5 | Pausen |
|-------|--------|--------|--------|--------|--------|--------|
| 1     | 10     | 12     | 8      | 8      | max    | 90s    |
| 2     | 12     | 16     | 12     | 10     | max    | 75s    |
| 3     | 15     | 20     | 15     | 12     | max    | 60s    |
| ...   | ...    | ...    | ...    | ...    | ...    | ...    |

> Die genauen Stufenwerte müssen aus dem Original-Programm rekonstruiert oder neu definiert werden.

### 2.2 Stufenauswahl beim Einstieg (Priorität: HOCH)

- Beim ersten Start (oder auf Wunsch) kann der Nutzer eine **Einstiegsstufe** wählen
- Optional: **Einschätzungstest** (max. Wiederholungen in einem Satz → empfohlene Stufe)

---

## 3. Bewegungsanalyse & Datensatz

### 3.1 Erweiterte Sensordaten pro Wiederholung (Priorität: MITTEL)

Neben der reinen Zählung sollen pro Wiederholung zusätzliche Messwerte erfasst werden, um **Bewegungsqualität** sichtbar zu machen.

**Zu erfassende Werte:**

| Messgröße | Quelle | Zweck |
|---|---|---|
| Zeitstempel der Wiederholung | Systemzeit | Gleichmäßigkeit, Rhythmus |
| Zeit seit letzter Wiederholung (Intervall) | Berechnung | Erkennung von Tempoabfall |
| Maximale Beschleunigung des Aufwärtsstoßes | Accelerometer | Krafteinsatz |
| Minimale Beschleunigung (unterste Position) | Accelerometer | Bewegungstiefe |
| Standardabweichung der Beschleunigung | Berechnung | Gleichmäßigkeit / Ruckigkeit |

**Ziel:** Ein Graph, der nach der Session zeigt:
- Gleichmäßigkeit der Bewegungsintervalle (zeigt Ermüdung)
- Ob der Nutzer unbewusst kleinere Bewegungen macht (flachere Amplitude)
- Ob ruckartige Bewegungen eingesetzt werden (hohe Standardabweichung)

**Datenbankänderung:** Neue Tabelle `rep_details` oder JSON-Blob im `workouts`-Eintrag.

```sql
CREATE TABLE rep_details (
    id              INTEGER PRIMARY KEY,
    workout_id      INTEGER REFERENCES workouts(_id),
    rep_index       INTEGER,
    timestamp_ms    INTEGER,
    interval_ms     INTEGER,
    peak_accel      REAL,
    min_accel       REAL,
    accel_stddev    REAL,
    is_verified     INTEGER
);
```

### 3.2 Analyse-Bildschirm (Priorität: NIEDRIG – nach Datenbasis)

- Graph: Intervalle über Wiederholungen (Linienchart)
- Graph: Beschleunigungsamplitude über Wiederholungen
- Warnung bei deutlichem Qualitätsabfall im Verlauf der Session

---

## 4. Live-Workout-Feedback

### 4.1 Ton pro Wiederholung (Priorität: MITTEL)

- Jede erfolgreich verifizierte Wiederholung → kurzer **Bestätigungston**
- Nicht verifizierte Wiederholung → optionales abweichendes Signal (oder kein Ton)

### 4.2 Countdown-Töne bei letzten 6 Wiederholungen (Priorität: MITTEL)

- Wenn noch **6 Wiederholungen** bis zum Satzziel verbleiben: ein Ton pro Wiederholung
- Die Töne steigen in der **Tonhöhe** an (6 unterschiedliche Frequenzen / Noten, aufsteigend)
- Letzte Wiederholung erhält den höchsten Ton

### 4.3 Pause-Countdown zwischen Sätzen (Priorität: HOCH)

- Nach Abschluss eines Satzes: Vollbild-Countdown mit der definierten Erholungszeit
- Visuelle Anzeige (Kreisfortschritt oder große Zahl)
- Ton bei 3, 2, 1 vor Restart
- Nutzer kann Pause verkürzen oder überspringen

---

## 5. Prioritäten-Übersicht

| # | Feature | Priorität | Abhängigkeiten |
|---|---------|-----------|----------------|
| 1 | `.puud`-Import (Datenmigration) | **HOCH** | – |
| 2 | Satzbasierte Trainingspläne + Pausen-Countdown | **HOCH** | – |
| 3 | Einstiegsstufen-Auswahl | **HOCH** | #2 |
| 4 | Ton pro Wiederholung | **MITTEL** | – |
| 5 | Countdown-Töne letzte 6 Wdh. | **MITTEL** | #4 |
| 6 | Erweiterte Sensordaten pro Rep | **MITTEL** | – |
| 7 | Analyse-Graph | **NIEDRIG** | #6 |
| 8 | CSV-Import/-Export (Fehlerbehebung) | **MITTEL** | – |

---

## 6. Offene Fragen

1. **Stufenstruktur**: Welche genauen Wiederholungszahlen und Pausenzeiten soll das Stufensystem haben? Sollen die Originalwerte der "Push Ups"-App nachgebaut werden, oder ein neues System definiert werden?

2. **Analyse-Graph**: Soll der Graph direkt nach der Session erscheinen oder nur im Dashboard beim Aufruf einer historischen Session?

3. **Ton-Implementierung**: Soll `audioplayers` oder Flutter-eigene `SystemSound` für die Töne verwendet werden? (Systemtöne sind begrenzt; `audioplayers` erlaubt eigene Sounddateien mit definierten Frequenzen)

4. **`.puud`-Mapping**: Welche `which`-Werte sollen importiert werden?
   - `which=1` (freie Einzeleinheit, Ø 20 Reps) → 455 Einträge
   - `which=3` (Session-Total, Ø 107 Reps für Custom-Level) → 450 Einträge
   - Oder beide, mit unterschiedlicher Kennzeichnung?

5. **Datenbankschema-Migration**: Wie soll mit bestehenden ApexPush-Daten bei einem Schema-Update umgegangen werden?
