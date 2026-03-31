# Blitz_lesen_Isabella_AndroidAPK

Android-Studio-Projekt fuer einen nativen Android-Wrapper um die lokale Web-App `app/src/main/assets/index.html`.

Dieses Projekt folgt einem festen Muster:

- `app/src/main/assets/` ist die bearbeitbare Web-Quelle
- `docs/` ist die synchronisierte Auslieferung fuer GitHub Pages und installierte PWAs
- `sync_web_assets.ps1` haelt HTML-Version, Service-Worker-Cache und `docs/` zusammen
- `sync_version_and_build.ps1` synchronisiert den Projektstand, baut die APK und erstellt Archivkopien
- iPhone-/Safari-Installation wird ueber `apple-touch-icon.png` mitgedacht

## Wichtige Projektregeln

- Web-Aenderungen nie nur in `docs/` machen
- Quelle bleibt immer `app/src/main/assets/`
- `sw.js` entscheidet mit, ob eine installierte PWA neue Aenderungen wirklich zieht
- Fuer reine Web-/PWA-Aenderungen ist `.\sync_web_assets.bat` der schnelle Sync
- Fuer verteilte Versionen ist `.\sync_version_and_build.bat` der Standardweg

## Wichtige Dateien

- [Privat/START_HIER.md](d:/@Visual%20Studio%20Code/Blitz_lesen_Isabella_AndroidAPK/Privat/START_HIER.md)
- [Privat/README.md](d:/@Visual%20Studio%20Code/Blitz_lesen_Isabella_AndroidAPK/Privat/README.md)
- [Privat/Prompt_WebApp_PWA_Update_und_Cache.md](d:/@Visual%20Studio%20Code/Blitz_lesen_Isabella_AndroidAPK/Privat/Prompt_WebApp_PWA_Update_und_Cache.md)
- [Privat/Vorlage_Android_HTML_APK_Referenz.md](d:/@Visual%20Studio%20Code/Blitz_lesen_Isabella_AndroidAPK/Privat/Vorlage_Android_HTML_APK_Referenz.md)

## Schnellstart

Debug-Build:

```powershell
.\gradlew.bat assembleDebug
```

Nur Web-Assets und `docs/` synchronisieren:

```powershell
.\sync_web_assets.bat
```

Version synchronisieren, APK bauen und archivieren:

```powershell
.\sync_version_and_build.bat
```
