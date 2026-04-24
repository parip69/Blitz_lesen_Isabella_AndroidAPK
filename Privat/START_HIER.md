# START HIER

Dieses Projekt soll kuenftig nach einem festen Muster weitergefuehrt werden.

## Das Muster

- `app/src/main/assets/` ist die echte Web-Quelle
- `docs/` ist nur die synchronisierte Auslieferung fuer GitHub Pages und installierte PWAs
- Fullscreen, Manifest, Service Worker und Installations-Icons werden immer gemeinsam gedacht
- `sw.js`/Web-Cache muss bei verteilten Web-Aenderungen mitziehen

## Die Standardwege

Nur Web-/PWA-Aenderungen synchronisieren:

```powershell
.\sync_web_assets.bat
```

Version synchronisieren, APK bauen und Archivdateien erstellen:

```powershell
.\sync_version_and_build.bat
```

## Wichtige Merksaetze

- Nicht nur `docs/` bearbeiten
- Erst `app/src/main/assets/` aendern
- Dann `docs/` synchronisieren
- `apple-touch-icon.png` fuer iPhone immer mitpruefen
- `Privat/` gehoert mit ins Repository, weil dort APK- und HTML-Archivdateien liegen

## Die wichtigsten Begleitdateien

- `Privat/README.md`
- `Privat/Prompt_WebApp_PWA_Update_und_Cache.md`
- `Privat/Vorlage_Android_HTML_APK_Referenz.md`
