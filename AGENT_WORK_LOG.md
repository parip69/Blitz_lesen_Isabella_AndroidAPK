# Agent Work Log

Diese Datei ist der gemeinsame Verlauf fuer Agentenarbeit in diesem Repository.

## Pflicht

- Vor jeder neuen Aufgabe zuerst diese Datei lesen.
- Nach jeder Aenderung einen neuen Eintrag oben ergaenzen.
- Kurz festhalten, was geaendert wurde, warum es geaendert wurde und welche Erkenntnisse wichtig sind.

## Empfohlenes Format

### YYYY-MM-DD HH:MM - Kurztitel
- Ziel:
- Geaenderte Dateien:
- Umsetzung:
- Erkenntnisse / Auswirkungen:
- Offene Punkte:

---

### 2026-04-24 17:09 - Commit-Hinweise fuer Versionspraefix ergaenzt
- Ziel:
  Projektweite KI-Hinweise so erweitern, dass generierte Commit-Nachrichten mit der aktuellen Versionsnummer beginnen.
- Geaenderte Dateien:
  `AGENTS.md`, `.github/copilot-instructions.md`, `AGENT_WORK_LOG.md`
- Umsetzung:
  In `AGENTS.md` eine klare Regel fuer Commit-Nachrichten ergaenzt: aktuelle Version aus `version.properties`, ganz am Anfang, im Format `v<Version> <Kurztext>`. Zusaetzlich eine neue `.github/copilot-instructions.md` angelegt, damit Copilot-faehige Editoren dieselbe Vorgabe ebenfalls projektweit mitbekommen.
- Erkenntnisse / Auswirkungen:
  Android Studio/Gemini kann projektweite `AGENTS.md`-Hinweise nutzen, waehrend Copilot-basierte Editoren dafuer die Datei `.github/copilot-instructions.md` unterstuetzen. Damit ist die Vorgabe fuer beide Wege im Repository sichtbar und teilbar verankert.
- Offene Punkte:
  Falls die eingebaute Commit-Vorschlagsfunktion eines konkreten Editors die Repo-Hinweise nicht auswertet, waere zusaetzlich noch eine lokale IDE-Regel bzw. Prompt-Vorlage im jeweiligen Editor sinnvoll.

---

### 2026-04-24 16:20 - Bestandsaufnahme erweitert und Geschichten-Export ergaenzt
- Ziel:
  Den aktuellen Projektstand gruendlich dokumentieren, die App-Funktionen bis heute einordnen und einen nutzerfreundlichen Export-/Teilen-Weg fuer Geschichten ergaenzen.
- Geaenderte Dateien:
  `AGENT_WORK_LOG.md`, `app/src/main/assets/index.html`, `docs/index.html`
- Umsetzung:
  Neue Bestandsaufnahme auf Basis von aktuellem Code und Git-Historie erstellt. Sichtbare Meilensteine: fruehe Iterationen bis Version 29, Vollbild-Fokus, spaetere Angleichung von Web/PWA/Android-Sync, kontrollierte Versionierung, Geschichten-Import per `.txt`, lokale Geschichten-Bibliothek mit Speichern, danach Handbuch-Ausbau und Agenten-Kontext. Zusaetzlich wurde ein neuer Button `Geschichte exportieren` eingebaut, der auf Android den nativen Teilen-Dialog nutzt, in unterstuetzten Browsern die Web-Share-Funktion und sonst einen `.txt`-Download. `sync_web_assets.ps1` und `gradlew assembleDebug` liefen danach erfolgreich.
- Erkenntnisse / Auswirkungen:
  Der aktuelle App-Stand ist funktional eine lokal arbeitende Lese-/Trainings-App mit Wortmodus, Satzmodus, frei waehlbaren Trennzeichen, dynamischer Lesezeit pro Zeichen, Vollbild-Steuerung, lokaler Geschichten-Bibliothek, HTML-Export mit eingebetteten Daten, PWA-Installationshinweisen und nativer Android-Dateiunterstuetzung. Geschichten koennen jetzt leichter an WhatsApp, Telegram oder andere Ziele weitergegeben werden, ohne den Umweg ueber manuelles Kopieren.
- Offene Punkte:
  Fuer eine veroeffentlichte neue Fassung sollte der Versionsstand kontrolliert weitergezogen werden, damit PWA-Cache und APK-Archiv eindeutig eine neue Ausgabe erhalten.

### 2026-04-24 15:55 - Handbuch und Agenten-Kontext fuer Geschichten erweitert
- Ziel:
  Handbuch beim Klick auf `Isabella Bachner` an den aktuellen Funktionsstand anpassen und einen dauerhaften Verlauf fuer spaetere Agenten einfuehren.
- Geaenderte Dateien:
  `AGENTS.md`, `AGENT_WORK_LOG.md`, `app/src/main/assets/index.html`, `docs/index.html`
- Umsetzung:
  Handbuch um aktuelle Funktionen ergaenzt: Trennzeichenwahl, dynamische Lesezeit pro Zeichen, Zurueck/Pause/Nach-vorne-Steuerung, Geschichten speichern/importieren/auswaehlen/loeschen, eindeutige Namensvergabe, Bibliotheks-Hinweise, HTML-Export mit eingebetteten lokalen Daten, Installations-/Aktualisierungshinweise und Datenschutz-Hinweis zum Export. Zusaetzlich wurde ein dauerhaft versionierbarer Work-Log im Projektwurzelverzeichnis eingefuehrt.
- Erkenntnisse / Auswirkungen:
  Geschichten werden lokal in `localStorage` gespeichert. `Text speichern` erzeugt immer einen neuen Eintrag; bei gleichen Namen werden automatisch Varianten wie `(2)` angelegt. Beim Auswaehlen einer Geschichte wird der Satzmodus aktiviert. Wenn der Text spaeter nicht mehr exakt zur ausgewaehlten Geschichte passt oder in den Wortmodus gewechselt wird, wird die Auswahl bewusst geloest. Der Ordner `.agent/` ist ignoriert, deshalb liegt der persistente Work-Log bewusst im Projektwurzelverzeichnis.
- Offene Punkte:
  Nach Aenderungen an `app/src/main/assets/` immer auch den Sync nach `docs/` ausfuehren, damit Web-Quelle und GitHub-Pages-Stand identisch bleiben.
