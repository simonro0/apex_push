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
- Jede Einheit hat **3 Schwierigkeitsvarianten**: Easy / Normal / Hard
- Jede Variante besteht aus **5 Sätzen** (Wiederholungszahlen)
- Ab Level 5 ist Satz 5 in Einheiten X-2 und X-3 ein Burnout-Satz (möglichst viele)

Einheiten werden nach dem Schema des Originals benannt: `L-E` (Level-Einheit), z.B. `7-1`, `7-2`, `7-3`, `8-1` …

Gesamtanzahl hartcodierter Einheiten: **8 × 3 × 3 = 72 Programme**  
Darüber hinaus: generativ erweiterbar (§1.5).

### 1.2 Vollständige Satzmatrix (Level 1–8)

*(Werte aus Original-App-Screenshots: Satz1-Satz2-Satz3-Satz4-Satz5)*

#### Level 1
| Einheit | Easy        | Normal      | Hard           |
|---------|-------------|-------------|----------------|
| 1-1     | 2-2-2-2-3   | 6-6-5-4-5   | 9-9-8-6-7      |
| 1-2     | 4-3-2-2-4   | 8-8-6-5-7   | 11-11-9-9-10   |
| 1-3     | 5-4-4-3-5   | 9-8-8-5-9   | 14-12-10-10-14 |

#### Level 2
| Einheit | Easy        | Normal      | Hard           |
|---------|-------------|-------------|----------------|
| 2-1     | 4-5-4-4-5   | 8-7-5-4-6   | 11-11-8-6-9    |
| 2-2     | 6-5-3-4-6   | 10-8-6-7-9  | 12-12-10-10-12 |
| 2-3     | 5-6-4-5-6   | 9-9-7-7-9   | 14-14-11-11-10 |

#### Level 3
| Einheit | Easy           | Normal         | Hard           |
|---------|----------------|----------------|----------------|
| 3-1     | 9-8-10-8-10    | 14-10-9-11-8   | 16-14-12-11-13 |
| 3-2     | 13-10-11-11-10 | 15-15-13-13-10 | 18-15-14-13-17 |
| 3-3     | 15-11-14-10-11 | 20-14-14-12-18 | 21-15-16-14-20 |

#### Level 4
| Einheit | Easy           | Normal         | Hard           |
|---------|----------------|----------------|----------------|
| 4-1     | 14-11-11-9-13  | 14-12-14-12-15 | 20-16-18-15-22 |
| 4-2     | 14-12-12-10-13 | 20-12-14-13-16 | 22-18-17-16-23 |
| 4-3     | 18-11-13-12-13 | 20-17-14-15-19 | 25-19-18-18-24 |

#### Level 5
| Einheit | Easy           | Normal         | Hard           |
|---------|----------------|----------------|----------------|
| 5-1     | 21-18-14-13-19 | 22-21-16-20-22 | 26-22-18-21-25 |
| 5-2     | 18-11-13-12-13 | 13-12-10-8-28  | 15-14-12-10-32 |
| 5-3     | 14-11-11-9-13  | 10-10-8-7-28   | 14-12-10-8-33  |

#### Level 6
| Einheit | Easy           | Normal         | Hard           |
|---------|----------------|----------------|----------------|
| 6-1     | 25-21-20-18-25 | 29-25-21-20-30 | 34-26-24-21-32 |
| 6-2     | 13-12-10-8-28  | 15-14-12-10-33 | 16-14-11-10-36 |
| 6-3     | 10-10-8-7-28   | 14-12-10-8-33  | 14-12-10-8-36  |

#### Level 7
| Einheit | Easy           | Normal         | Hard           |
|---------|----------------|----------------|----------------|
| 7-1     | 30-21-26-18-25 | 34-25-21-25-35 | 41-26-33-25-35 |
| 7-2     | 25-14-10-8-23  | 13-14-11-10-33 | 20-18-11-10-28 |
| 7-3     | 19-12-10-8-28  | 14-12-10-8-30  | 14-12-10-18-36 |

#### Level 8
| Einheit | Easy           | Normal         | Hard           |
|---------|----------------|----------------|----------------|
| 8-1     | 36-28-25-24-33 | 46-36-32-34-46 | 52-41-38-36-52 |
| 8-2     | 18-16-13-11-38 | 21-18-18-14-46 | 26-21-21-18-52 |
| 8-3     | 24-21-19-18-46 | 27-24-24-20-54 | 31-27-27-24-60 |

### 1.3 Generative Erweiterung ab Level 9

Die Datenwerte wurden in der Original-App handgepflegt, folgen aber zwei erkennbaren strukturellen Typen:

**Typ A – „Distributed"** (alle X-1-Einheiten, X-2/X-3 bis Level 4)  
Wiederholungen gleichmäßig auf 5 Sätze verteilt, Satz 1 und 5 leicht erhöht.

**Typ B – „Burnout"** (X-2/X-3 ab Level 5, Normal/Hard)  
Sätze 1–4 moderat (8–21 Reps), Satz 5 als Burnout-Satz mit deutlich mehr Wiederholungen.

**Extrapolationsformeln für Level N ≥ 9:**

*Gesamtvolumen X-1 (Normal):*
```
total = round(23.6 × N − 14)
Satz 1 ≈ total × 0.24
Satz 2 ≈ total × 0.19
Satz 3 ≈ total × 0.17
Satz 4 ≈ total × 0.18
Satz 5 ≈ total × 0.24   (→ round)
```

*Burnout-Satz X-2/X-3 (Normal):*
```
Satz 5 = round(28 + (N − 5) × 6.5)
Sätze 1–4: ~[15, 13, 11, 9] + 1 pro Level-Stufe ab Level 6
```

*Schwierigkeitsskalierung (stabil ab Level 4):*
```
Normal = Easy × 1.21
Hard   = Easy × 1.43
```

**Besonderheit Level 8:** Stellt einen bewussten Schwierigkeitssprung dar (~2–3× normale Steigerung gegenüber Level 7). Zukünftige Meilenstein-Level (z.B. 12, 16 …) können analog als Intensitätsspitzen modelliert werden.

### 1.5 Ruhezeiten zwischen Sätzen

Die Ruhezeit richtet sich nach der **Schwierigkeitsvariante** des gewählten Programms – nicht nach dem Level:

| Variante | Ruhezeit |
|----------|----------|
| Easy     | 30 Sekunden |
| Normal   | 60 Sekunden |
| Hard     | 120 Sekunden |

Die Ruhezeit gilt einheitlich zwischen allen Sätzen einer Session. Der Nutzer kann die Pause im Einstellungsscreen überschreiben (§8.2).

### 1.6 Einstieg & Level-Empfehlung

Zwei Wege zum Einstieg:

1. **Direkte Auswahl** aus der Levelübersicht (Tabelle wie in Original-App)
2. **Einschätzung** via freier Übungsrunde (Practice) → automatische Empfehlung

**Empfehlungslogik nach freier Runde:**

Kriterium: Wähle das Level, bei dem die **maximale Einzelsatz-Wiederholungszahl** nur minimal größer ist als das Ergebnis der freien Runde.

```
Ergebnis freie Runde = N Wiederholungen

Empfehlung = erstes Level (aufsteigend), bei dem
             max(Satz 1..5) > N AND max(Satz 1..5) − N ist minimal
```

Beispiel: Freie Runde = 18 Reps  
→ Level 4-1 Easy hat max. Satz = 14 (zu klein), Level 4-3 Easy max = 18 (knapp), Level 5-1 Easy max = 21 (minimal größer) → **Empfehlung: Level 5-1 Easy**

Die Empfehlung wird dem Nutzer angezeigt; er kann sie übernehmen oder manuell anpassen.

---

## 2. Navigation & Screens

### 2.1 Dashboard (Hauptscreen)

Layout exakt nach Original-App (Screenshot):

```
┌─────────────────────────────────────────────┐
│  Best Record  │  Total   │  Average    🔔 ⚙️ │
│  303/d        │  50000   │  25/d             │
├─────────────────────────────────────────────┤
│                                             │
│         [Grafik / Logo / Illustration]      │
│                                             │
├─────────────────────────────────────────────┤
│          [      TRAINING      ]             │
│  [ PRACTICE ]          [ RECORD ]           │
└─────────────────────────────────────────────┘
```

**Statistik-Zeile (oben links, 3 Felder):**

| Feld           | Wert            | Berechnung |
|----------------|-----------------|------------|
| Best Record    | z.B. `303/d`    | Höchste Tages-Gesamtwiederholungen in der Historie |
| Total          | z.B. `50000`    | Alle-Zeit-Summe aller Wiederholungen |
| Average        | z.B. `25/d`     | Durchschnitt Wiederholungen pro Trainingstag |

**Icons oben rechts:**
- 🔔 → Benachrichtigungseinstellungen (eigener Screen)
- ⚙️ → App-Einstellungen (eigener Screen)

### 2.2 Navigation

| Button       | Aktion |
|--------------|--------|
| **Training** | Heutiges Training fortsetzen. Falls noch kein Training für heute: Levelauswahl anzeigen oder freie Einschätzungsrunde anbieten |
| **Practice** | Jederzeit freie Übungsrunde starten (ohne Stufenbindung) |
| **Record**   | **Monatsansicht** mit kombiniertem Balken- + Linienchart (siehe §4) |

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

- **Jederzeit abbrechen** möglich → Session wird mit bisher erreichten Reps gespeichert → Rückfrage Levelanpassung
- **Nach letztem Satz: Weitermachen** möglich (Burnout-Bonus-Set ohne Zielvorgabe, bis zur Erschöpfung)
- Nach Abschluss oder Abbruch: immer Rückfrage Levelanpassung (§3.3)

### 3.3 Levelanpassung

**Levelwechsel nur auf expliziten Nutzerwunsch** – kein automatischer Fortschritt.

Auslöser für die Rückfrage:
1. Nutzer bricht Training ab
2. Nutzer macht mehr Wiederholungen als das Satzziel (Burnout-Bonus)

Optionen in der Rückfrage:

| Wahl | Aktion |
|------|--------|
| Beibehalten | Kein Levelwechsel |
| Zu leicht | Nächste Stufe (Easy→Normal→Hard→nächste Woche→nächstes Level) |
| Zu schwer | Vorherige Stufe |

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

### 4.1 Monatsansicht (Record-Tab)

Layout nach Original-App (Screenshot):

```
◄  2023-01  ►       [Pushups]  [Calorie]

  180 ─────────────────────────────────
  160 │
  140 │                  ●
  120 │              ────────────────
  100 │      ●
   80 │  ●──●   ●──────
   60 │●         
   ...│
    0 └────────────────────────────────
       2  4  6  8  10  12  ...  28  30

             [ Home ]
```

- **Navigation**: Monat per `◄` / `►` wechseln
- **Tabs**: Pushups (Standard) | Calorie
- **Diagrammtyp**: kombiniertes Balkendiagramm (Tagessumme als Fläche) + Linienchart (Datenpunkte verbunden)
- **X-Achse**: Tage des Monats (1–31, nur Trainingstage mit Balken)
- **Y-Achse**: Anzahl Wiederholungen (automatisch skaliert)
- **Calorie-Tab**: Kalorienverbrauch je Tag – Formel: `reps × 0,5 kcal` (fixe Näherung, bewusst einfach gehalten). Die Architektur lässt eine spätere Erweiterung um Körpergewicht und Bewegungsgeschwindigkeit zu (beide Faktoren werden für eine reelle Berechnung benötigt).
- **Tap auf Datenpunkt/Balken** → Detailansicht dieser Session
- **„Home"-Button** unten → zurück zum Dashboard

### 4.2 Session-Detailansicht

Erreichbar aus:
- Post-Training-Flow (direkt nach Training, automatisch)
- Record-Tab (historisch, per Tap auf Balken)

Inhalt:
- Datum + Level + Gesamtreps
- Satzweise Auflistung: Satz N → Ziel: X | Erreicht: Y | Zeit: Z s
- Bewegungsqualitäts-Graph (sofern Sensordaten vorhanden, siehe §5)
- Kalorienverbrauch der Session

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

Anzeige in **zwei Kontexten**:
1. **Post-Training-Flow** (direkt nach jeder Session, vor der Monatsübersicht)
2. **Session-Detailansicht** (historisch abrufbar via Record-Tab)

**Diagramm-Aufbau:**
- X-Achse: Wiederholungsnummer (über alle Sätze, mit Satz-Trennlinien)
- Linie 1: Intervall (ms) zwischen Wiederholungen → zeigt Tempoabfall / Ermüdung
- Linie 2: Peak-Beschleunigungsamplitude → zeigt Bewegungstiefe

**Fester Hinweistext** (immer unter dem Graphen):
> „Gleichmäßige, kontrollierte Bewegungen sind effizienter und erfordern weniger Kraftaufwand als ruckartige Wiederholungen."

**Automatischer Ermüdungshinweis** (wenn Intervall-Standardabweichung > Schwellenwert):
> „Dein Tempo wurde gegen Ende deutlich ungleichmäßiger – typisches Zeichen von Ermüdung."

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

**Import-Strategie: Alle Einträge importieren** – der geringe Mehraufwand einer Filterung lohnt sich bei der Datenmenge (1.104 Einträge) nicht.

**Mapping nach Typ:**

| `which` | Typ | ApexPush-Entsprechung |
|---------|-----|----------------------|
| `1`     | Freies Training (~20 Reps Ø) | `Workout(isFreeTraining: true, isImported: true)` |
| `3`     | Session-Total (~107 Reps Ø) | `Workout(isFreeTraining: false, isImported: true)` |

> `which=2` (Programm-Set-Einträge, nur 21 Stück) können ebenfalls als `isFreeTraining: true` importiert werden.

**Vorgehensweise:**
1. Datei-Picker für `.puud`-Dateien öffnen
2. ZIP-Eintrag `PushUps_Mos.db` in temporäres Verzeichnis extrahieren
3. SQLite-Abfrage auf `PushUpsRecord` ausführen (alle Einträge mit `num > 0`)
4. `isImported: true` setzen, Typ nach `which`-Wert unterscheiden
5. Batch-Insert in lokale ApexPush-Datenbank

### 7.2 CSV-Export / -Import

- Bestehende Implementierung (`csv_service.dart`) beibehalten und robuster machen
- Fehlerbehandlung und Format-Validierung ergänzen

---

## 8. Benachrichtigungen & Einstellungen

### 8.1 Benachrichtigungsscreen (🔔)

Eigener Screen, erreichbar über Bell-Icon auf dem Dashboard.  
Entspricht der `alarm_settings`-Tabelle im Original-Backup.

| Einstellung              | Typ       | Standard       |
|--------------------------|-----------|----------------|
| Notification on/off      | Toggle    | off            |
| Notify me every N day(s) | Zahl      | 1              |
| Time                     | Uhrzeit   | 18:00          |
| Ring tone                | Auswahl   | System-Default |
| Vibrate                  | Toggle    | off            |

### 8.2 Einstellungsscreen (⚙️)

Eigener Screen nach Original-App-Struktur (Options-Screenshot):

**Push ups Setting**
| Eintrag               | Funktion |
|-----------------------|----------|
| Notification          | → Benachrichtigungsscreen (wie §8.1) |
| Backup Record         | Daten als `.puud` oder CSV exportieren |
| Restore Record        | Import aus `.puud`-Datei oder CSV |
| Clear All Record      | Alle Trainingsdaten löschen (mit Bestätigung) |

**App Setting** *(ApexPush-eigene Erweiterungen)*
| Eintrag               | Funktion |
|-----------------------|----------|
| Ruhezeiten            | Standardpausen je Level-Gruppe konfigurieren |
| Sensor-Kalibrierung   | Beschleunigungsschwellenwert anpassen |
| Theme                 | Hell / Dunkel |

**About**
| Eintrag               | Funktion |
|-----------------------|----------|
| Version               | App-Version anzeigen |

---

## 9. Prioritäten-Übersicht

| # | Feature | Priorität | Abhängigkeiten |
|---|---------|-----------|----------------|
| 1 | `.puud`-Import (Datenmigration) | **HOCH** | – |
| 2 | Levelstruktur als Datenmodell (8×3×3 Matrix) | **HOCH** | – |
| 3 | Satzbasiertes Training + Pausen-Countdown | **HOCH** | #2 |
| 4 | Einstiegsstufen-Auswahl / Level-Picker | **HOCH** | #2 |
| 5 | Dashboard mit Stats-Zeile + 3 Buttons | **HOCH** | #3 |
| 6 | Ton pro Wiederholung + Countdown-Töne | **MITTEL** | – |
| 7 | Post-Training-Flow (Detail → Monat → Anpassung) | **MITTEL** | #3, #4 |
| 8 | Monatsansicht (Record) mit Bar+Line-Chart | **MITTEL** | #5 |
| 9 | Kalorie-Tab im Record-Screen | **NIEDRIG** | #8 |
| 10 | Erweiterte Sensordaten pro Rep | **MITTEL** | – |
| 11 | Bewegungsqualitäts-Graph | **NIEDRIG** | #10 |
| 12 | Benachrichtigungen (Schedule) | **NIEDRIG** | – |
| 13 | Einstellungsscreen mit Backup/Restore | **MITTEL** | #1 |
| 14 | CSV-Import/-Export (robuster) | **MITTEL** | – |
| 15 | Generative Level 9+ Berechnung | **NIEDRIG** | #2 |

---

## 10. Zukünftige Integrationen (Ausblick)

### 10.1 Strava-Integration

Für eine spätere Version ist eine Anbindung an **Strava** vorgesehen.

Mögliche Umsetzung:
- Nach einem Training: Button „An Strava exportieren"
- Übertragung als **Manual Activity** via [Strava API](https://developers.strava.com/) (`POST /activities`)
- Felder: Name, Typ (`WeightTraining`), Startzeit, Dauer, Beschreibung (Sätze + Reps)
- OAuth2-Flow für Authentifizierung

Voraussetzungen: Strava-API-Key (App-Registrierung), `flutter_appauth`-Package für OAuth2.

> Kein Handlungsbedarf jetzt – Architektur sollte aber so gestaltet werden, dass ein `WorkoutExporter`-Interface erweiterbar ist (CSV heute, Strava später).

---

## 11. Verbleibende offene Punkte

Alle inhaltlichen Fragen sind geklärt. Folgende Punkte bleiben für spätere Iterationen offen:

1. **Kalorie-Erweiterung**: Wenn die Formel später auf Körpergewicht + Bewegungsgeschwindigkeit ausgedehnt werden soll, ist ein Settings-Feld „Körpergewicht (kg)" und die Integration der `accel_stddev`-Daten aus `rep_details` der Weg. Kein Handlungsbedarf jetzt.

2. **Ermüdungs-Schwellenwert** für den automatischen Hinweis im Analyse-Graph: Muss nach ersten Datensammlungen kalibriert werden (Startwert: Intervall-Stddev > 30 % des Mittelwerts).
