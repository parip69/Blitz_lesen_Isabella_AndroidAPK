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
