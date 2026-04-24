Blitz_lesen_Isabella_AndroidAPK (Version 36)

Dieses Repository enthaelt ein Android-Studio-Projekt fuer einen nativen Wrapper
um die lokale Web-App aus `app/src/main/assets/index.html`.

Build:
1. Android Studio und JDK 17 installieren
2. Android SDK Platform 35 samt Build-Tools bereitstellen
3. Projektordner in Android Studio oeffnen oder `local.properties` mit `sdk.dir=...` anlegen
4. Fuer einen normalen Debug-Build `.\gradlew.bat assembleDebug` ausfuehren
5. Die APK liegt danach unter `app/build/outputs/apk/debug/BlitzLesen-v36.apk`

Versionierter Build mit Archivkopien:
- `.\sync_version_and_build.bat` erhoeht die Version kontrolliert vor dem Build
- danach werden Web-Assets synchronisiert und HTML/APK nach `Privat/` kopiert

Nur Web-/PWA-Assets synchronisieren:
- `.\sync_web_assets.bat`
