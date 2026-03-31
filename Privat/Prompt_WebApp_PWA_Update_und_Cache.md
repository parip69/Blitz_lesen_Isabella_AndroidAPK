# Prompt fuer Web-App-, PWA- und Cache-Updates

Diese Vorlage ist fuer spaetere Aenderungen an der Web-App gedacht, wenn Browser, PWA, GitHub Pages, Vollbildmodus, Manifest oder Installations-Icons angepasst werden sollen.

## Prompt

```text
Ich moechte in diesem Projekt die Web-App/PWA sauber aktualisieren.

Bitte fuehre die Aenderungen direkt im Projekt aus und beachte zwingend diese Regeln:

1. Die editierbare Quelle liegt in `app/src/main/assets/`.
2. `docs/` ist nur die synchronisierte Auslieferung fuer GitHub Pages und installierte PWAs.
3. Bearbeite nicht nur `docs/`, wenn die eigentliche Quelle in `app/src/main/assets/` liegt.
4. Wenn sich eine gecachte Web-Datei aendert, muss auch `sw.js` bzw. die Web-Cache-Version mitziehen.
5. Bei Installations-Icons immer dieses Paket mitpruefen:
   - `app/src/main/assets/icons/icon-192.png`
   - `app/src/main/assets/icons/icon-512.png`
   - `app/src/main/assets/icons/apple-touch-icon.png`
6. Fuer iPhone/Safari muss `apple-touch-icon.png` in `180x180` vorhanden sein und in `index.html` passend verlinkt werden.
7. Bei Web-Fullscreen-/PWA-Aenderungen pruefe gemeinsam:
   - `app/src/main/assets/index.html`
   - `app/src/main/assets/manifest.webmanifest`
   - `app/src/main/assets/sw.js`
8. Fuehre nach den Aenderungen mindestens `.\sync_web_assets.bat` aus. Wenn auch die APK geprueft werden soll, zusaetzlich `.\gradlew.bat assembleDebug`.
9. Pruefe danach, dass der neue Stand auch in `docs/` angekommen ist.
10. Nenne am Ende die geaenderten Dateien, das Build-Ergebnis und ob die Web-App bei Icon-Aenderungen auf iPhone oder manchen Android-Launchern neu installiert werden sollte.
```

## Merksatz

- `app/src/main/assets/` ist die Quelle.
- `docs/` ist die Auslieferung.
- `sw.js` entscheidet, ob die PWA das Update wirklich zieht.
