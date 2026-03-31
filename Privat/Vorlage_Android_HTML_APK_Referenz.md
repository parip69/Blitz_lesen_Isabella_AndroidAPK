# Referenz fuer die Pflege dieses Projekts

Diese Datei beschreibt den Soll-Zustand fuer die laufende Pflege von `Blitz_lesen_Isabella_AndroidAPK`.

## Pflichtmuster

- `app/src/main/assets/` bleibt die bearbeitbare Web-Quelle
- `docs/` bleibt die synchronisierte Web-/PWA-Auslieferung
- Browser, PWA und APK sollen denselben Web-Stand verwenden
- die sichtbare HTML-Version und die Web-Cache-Version muessen zusammenlaufen

## Pflichtdateien fuer Web/PWA

- `app/src/main/assets/index.html`
- `app/src/main/assets/manifest.webmanifest`
- `app/src/main/assets/sw.js`
- `app/src/main/assets/icons/icon-192.png`
- `app/src/main/assets/icons/icon-512.png`
- `app/src/main/assets/icons/apple-touch-icon.png`

## Pflichtwerkzeuge

- `sync_web_assets.ps1`
- `sync_web_assets.bat`
- `sync_version_and_build.ps1`
- `sync_version_and_build.bat`

## Was bei Aenderungen immer gelten soll

- nie nur `docs/` aendern
- fuer reine Web-Aenderungen `sync_web_assets` verwenden
- fuer verteilte Versionen `sync_version_and_build` verwenden
- nach dem Sync pruefen, dass `docs/` wirklich aktualisiert wurde
- iPhone-/Safari-Installationsicon immer mitpruefen

## Abnahme fuer Web-/PWA-Aenderungen

- `docs/index.html` entspricht dem Stand von `app/src/main/assets/index.html`
- `docs/manifest.webmanifest` ist aktuell
- `docs/sw.js` ist aktuell
- die Icons unter `docs/icons/` sind aktuell
- Fullscreen-/PWA-/Installationsverhalten bleibt konsistent
