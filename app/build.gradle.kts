import java.util.Properties
import java.security.MessageDigest

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val versionPropertiesFile = rootProject.file("version.properties")
val versionProperties = Properties().apply {
    if (versionPropertiesFile.exists()) {
        versionPropertiesFile.inputStream().use(::load)
    } else {
        setProperty("VERSION_CODE", "1")
        setProperty("VERSION_NAME", "1")
    }
}

val currentVersionCode = versionProperties.getProperty("VERSION_CODE")?.toIntOrNull() ?: 1
val currentVersionName = versionProperties.getProperty("VERSION_NAME")
    ?.trim()
    ?.takeIf { it.isNotEmpty() }
    ?: currentVersionCode.toString()

fun String.replaceRequired(oldValue: String, newValue: String, label: String): String {
    check(contains(oldValue)) { "syncGitHubPagesDocs: Abschnitt nicht gefunden: $label" }
    return replace(oldValue, newValue)
}

fun String.insertAfterRequired(anchor: String, addition: String, label: String): String {
    check(contains(anchor)) { "syncGitHubPagesDocs: Anker nicht gefunden: $label" }
    return replace(anchor, anchor + addition)
}

fun String.sha256Short(length: Int = 12): String {
    val digest = MessageDigest.getInstance("SHA-256")
        .digest(toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it) }
    return digest.take(length)
}

android {
    namespace = "de.parip69.blitzlesen"
    compileSdk = 35

    defaultConfig {
        applicationId = "de.parip69.blitzlesen"
        minSdk = 24
        targetSdk = 35
        versionCode = currentVersionCode
        versionName = currentVersionName

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        buildConfig = true
        viewBinding = true
    }

    applicationVariants.all {
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
            output.outputFileName = "BlitzLesen-v${currentVersionName}.apk"
        }
    }
}

val assetsDir = layout.projectDirectory.dir("src/main/assets")
val docsDir = rootProject.layout.projectDirectory.dir("docs")

val syncGitHubPagesDocsFiles = {
    val docsDirFile = docsDir.asFile
    val docsIconsDir = docsDir.dir("icons").asFile
    docsDirFile.mkdirs()
    docsIconsDir.mkdirs()

    val sourceHtml = assetsDir.file("index.html").asFile.readText(Charsets.UTF_8)
    val sourceManifest = assetsDir.file("manifest.webmanifest").asFile.readText(Charsets.UTF_8)
    val sourceSw = assetsDir.file("sw.js").asFile.readText(Charsets.UTF_8)
    val newline = if (sourceHtml.contains("\r\n")) "\r\n" else "\n"
    fun lines(vararg values: String): String = values.joinToString(newline)
    val cacheVersion = listOf(currentVersionName, sourceHtml, sourceManifest, sourceSw)
        .joinToString("\n---\n")
        .sha256Short()

    var docsHtml = sourceHtml
    docsHtml = docsHtml.replaceRequired(
        """    <meta name="viewport" content="width=device-width, initial-scale=1" />""",
        lines(
            "    <meta",
            "      name=\"viewport\"",
            "      content=\"width=device-width, initial-scale=1, viewport-fit=cover\"",
            "    />",
            "    <meta name=\"theme-color\" content=\"#152235\" />",
            "    <meta name=\"application-name\" content=\"Blitz lesen\" />",
            "    <meta name=\"mobile-web-app-capable\" content=\"yes\" />",
            "    <meta name=\"apple-mobile-web-app-capable\" content=\"yes\" />",
            "    <meta",
            "      name=\"apple-mobile-web-app-status-bar-style\"",
            "      content=\"black-translucent\"",
            "    />",
            "    <meta name=\"apple-mobile-web-app-title\" content=\"Blitz lesen\" />",
            "    <link rel=\"manifest\" href=\"./manifest.webmanifest\" />",
            "    <link rel=\"apple-touch-icon\" href=\"./icons/apple-touch-icon.png\" />",
            "    <link rel=\"icon\" type=\"image/png\" sizes=\"192x192\" href=\"./icons/icon-192.png\" />"
        ),
        "Meta-Tags fuer GitHub Pages"
    )
    docsHtml = docsHtml.replaceRequired(
        lines(
            "      </section>",
            "    </div>",
            "",
            "    <!-- Vollbild Overlay -->"
        ),
        lines(
            "      </section>",
            "",
            "      <section class=\"card compact\" id=\"installHintCard\" hidden>",
            "        <div class=\"hint\" id=\"installHintText\"></div>",
            "      </section>",
            "    </div>",
            "",
            "    <!-- Vollbild Overlay -->"
        ),
        "Install-Hinweis"
    )
    docsHtml = docsHtml.insertAfterRequired(
        "          const exportHtmlNote = $(\"#exportHtmlNote\");",
        lines(
            "",
            "          const installHintCard = $(\"#installHintCard\");",
            "          const installHintText = $(\"#installHintText\");"
        ),
        "Install-Hinweis Variablen"
    )
    docsHtml = docsHtml.replaceRequired(
        lines(
            "          function supportsBundledIndexHtmlExport() {",
            "            const androidBridge = getAndroidBridge();",
            "            const hasNativeAndroidExport = Boolean(",
            "              document.documentElement.getAttribute(\"data-native-app\") ===",
            "                \"android\" &&",
            "              androidBridge &&",
            "              typeof androidBridge.getBundledIndexHtml === \"function\" &&",
            "              typeof androidBridge.saveTextFile === \"function\",",
            "            );",
            "            const hasBrowserFallback = Boolean(",
            "              typeof window.fetch === \"function\" &&",
            "              typeof Blob !== \"undefined\" &&",
            "              typeof URL !== \"undefined\" &&",
            "              typeof URL.createObjectURL === \"function\",",
            "            );",
            "            return hasNativeAndroidExport || hasBrowserFallback;",
            "          }",
            "",
            "          function updateBundledIndexHtmlExportVisibility() {",
            "            if (!exportHtmlBtn) return;",
            "            const supported = supportsBundledIndexHtmlExport();",
            "            if (settingsActions) settingsActions.hidden = false;",
            "            exportHtmlBtn.hidden = false;",
            "            exportHtmlBtn.disabled =",
            "              !supported || exportHtmlBtn.classList.contains(\"is-busy\");",
            "            exportHtmlBtn.setAttribute(\"aria-hidden\", \"false\");",
            "            exportHtmlBtn.setAttribute(\"aria-disabled\", String(!supported));",
            "            if (exportHtmlNote) {",
            "              exportHtmlNote.textContent = supported",
            "                ? \"Speichert die originale HTML-Datei mit deinen aktuellen lokalen Einstellungen.\"",
            "                : \"HTML-Export ist in dieser Umgebung gerade nicht verfuegbar.\";",
            "            }",
            "          }",
            "",
            "          window.__updateHtmlExportButton =",
            "            updateBundledIndexHtmlExportVisibility;"
        ),
        lines(
            "          function supportsBundledIndexHtmlExport() {",
            "            const androidBridge = getAndroidBridge();",
            "            return Boolean(",
            "              document.documentElement.getAttribute(\"data-native-app\") ===",
            "                \"android\" &&",
            "              androidBridge &&",
            "              typeof androidBridge.getBundledIndexHtml === \"function\" &&",
            "              typeof androidBridge.saveTextFile === \"function\",",
            "            );",
            "          }",
            "",
            "          function updateBundledIndexHtmlExportVisibility() {",
            "            if (!exportHtmlBtn) return;",
            "            const supported = supportsBundledIndexHtmlExport();",
            "            if (settingsActions) settingsActions.hidden = !supported;",
            "            exportHtmlBtn.hidden = !supported;",
            "            exportHtmlBtn.disabled =",
            "              !supported || exportHtmlBtn.classList.contains(\"is-busy\");",
            "            exportHtmlBtn.setAttribute(\"aria-hidden\", String(!supported));",
            "            exportHtmlBtn.setAttribute(\"aria-disabled\", String(!supported));",
            "            if (exportHtmlNote) {",
            "              exportHtmlNote.hidden = !supported;",
            "              exportHtmlNote.textContent =",
            "                \"Speichert die originale HTML-Datei mit deinen aktuellen lokalen Einstellungen.\";",
            "            }",
            "          }",
            "",
            "          window.__updateHtmlExportButton =",
            "            updateBundledIndexHtmlExportVisibility;",
            "",
            "          function isStandaloneWebApp() {",
            "            const standaloneDisplay =",
            "              typeof window.matchMedia === \"function\" &&",
            "              window.matchMedia(\"(display-mode: standalone)\").matches;",
            "            return Boolean(standaloneDisplay || window.navigator.standalone);",
            "          }",
            "",
            "          function getInstallHintMessage() {",
            "            const ua = String(window.navigator.userAgent || \"\");",
            "            const isIOS = /iPad|iPhone|iPod/i.test(ua);",
            "            const isAndroid = /Android/i.test(ua);",
            "",
            "            if (isStandaloneWebApp()) return \"\";",
            "            if (isIOS) {",
            "              return \"Tipp: In Safari oeffnen und dann Teilen -> Zum Home-Bildschirm nutzen.\";",
            "            }",
            "            if (isAndroid) {",
            "              return \"Tipp: Im normalen Browser oeffnen und ueber das Menue Zum Startbildschirm oder App installieren nutzen.\";",
            "            }",
            "            return \"\";",
            "          }",
            "",
            "          function updateInstallHintVisibility() {",
            "            if (!installHintCard || !installHintText) return;",
            "            const message = getInstallHintMessage();",
            "            installHintCard.hidden = !message;",
            "            installHintText.textContent = message;",
            "          }",
            "",
            "          async function registerBrowserServiceWorker() {",
            "            const isTrustedLocalhost = [\"localhost\", \"127.0.0.1\", \"::1\"].includes(",
            "              window.location.hostname,",
            "            );",
            "            if (!(\"serviceWorker\" in navigator)) return;",
            "            if (!(window.isSecureContext || isTrustedLocalhost)) return;",
            "            try {",
            "              await navigator.serviceWorker.register(\"./sw.js?v=$cacheVersion\");",
            "            } catch (e) {",
            "              console.warn(\"Service Worker konnte nicht registriert werden:\", e);",
            "            }",
            "          }",
            "",
            "          window.addEventListener(\"appinstalled\", updateInstallHintVisibility);"
        ),
        "Browser-Export und PWA-Hinweise"
    )
    docsHtml = docsHtml.replaceRequired(
        lines(
            "          })();",
            "          updateOverlayLayout();",
            "          updateBundledIndexHtmlExportVisibility();",
            "          if (!loaded) {"
        ),
        lines(
            "          })();",
            "          updateOverlayLayout();",
            "          updateBundledIndexHtmlExportVisibility();",
            "          updateInstallHintVisibility();",
            "          registerBrowserServiceWorker();",
            "          if (!loaded) {"
        ),
        "Initialisierung fuer Pages-Version"
    )

    docsDir.file("index.html").asFile.writeText(docsHtml, Charsets.UTF_8)

    project.copy {
        from(assetsDir.file("manifest.webmanifest").asFile)
        into(docsDirFile)
    }
    project.copy {
        from(assetsDir.dir("icons").asFile)
        into(docsIconsDir)
    }

    val docsSw = lines(
        "const CACHE_NAME = 'blitz-lesen-docs-$cacheVersion';",
        "const CACHE_PREFIX = 'blitz-lesen-docs-';",
        "const PRECACHE_URLS = [",
        "  './',",
        "  './index.html',",
        "  './manifest.webmanifest',",
        "  './icons/icon-192.png',",
        "  './icons/icon-512.png',",
        "  './icons/apple-touch-icon.png'",
        "];",
        "",
        "function putInCache(request, response) {",
        "  if (!response || response.status !== 200 || response.type === 'opaque') return response;",
        "  const copy = response.clone();",
        "  caches.open(CACHE_NAME).then(cache => cache.put(request, copy)).catch(() => {});",
        "  return response;",
        "}",
        "",
        "function networkFirst(request) {",
        "  return fetch(request)",
        "    .then(response => putInCache(request, response))",
        "    .catch(() => caches.match(request));",
        "}",
        "",
        "function cacheFirst(request) {",
        "  return caches.match(request).then(cached => {",
        "    if (cached) return cached;",
        "    return fetch(request).then(response => putInCache(request, response));",
        "  });",
        "}",
        "",
        "function isNavigationRequest(request) {",
        "  return request.mode === 'navigate';",
        "}",
        "",
        "function isNetworkFirstRequest(request, url) {",
        "  return isNavigationRequest(request) ||",
        "    url.pathname.endsWith('/index.html') ||",
        "    url.pathname.endsWith('/manifest.webmanifest');",
        "}",
        "",
        "self.addEventListener('install', event => {",
        "  event.waitUntil(",
        "    caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE_URLS)).then(() => self.skipWaiting())",
        "  );",
        "});",
        "",
        "self.addEventListener('activate', event => {",
        "  event.waitUntil(",
        "    caches.keys().then(keys => Promise.all(",
        "      keys",
        "        .filter(key => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)",
        "        .map(key => caches.delete(key))",
        "    )).then(() => self.clients.claim())",
        "  );",
        "});",
        "",
        "self.addEventListener('fetch', event => {",
        "  const request = event.request;",
        "  if (request.method !== 'GET') return;",
        "",
        "  const url = new URL(request.url);",
        "",
        "  if (url.origin !== self.location.origin) {",
        "    event.respondWith(networkFirst(request));",
        "    return;",
        "  }",
        "",
        "  if (isNetworkFirstRequest(request, url)) {",
        "    event.respondWith(networkFirst(request));",
        "    return;",
        "  }",
        "",
        "  event.respondWith(cacheFirst(request));",
        "});"
    )
    docsDir.file("sw.js").asFile.writeText(docsSw, Charsets.UTF_8)

    docsDir.file(".nojekyll").asFile.writeText("", Charsets.UTF_8)
    docsDir.file("README-GitHub-Pages.txt").asFile.writeText(
        lines(
            "GitHub Pages aktivieren:",
            "1. GitHub -> Settings -> Pages",
            "2. Source: Deploy from a branch",
            "3. Branch: main",
            "4. Folder: /docs"
        ),
        Charsets.UTF_8
    )
}

val syncGitHubPagesDocs by tasks.registering {
    group = "distribution"
    description = "Synchronisiert die GitHub-Pages-Dateien in docs/ aus app/src/main/assets."

    inputs.file(assetsDir.file("index.html"))
    inputs.file(assetsDir.file("manifest.webmanifest"))
    inputs.file(assetsDir.file("sw.js"))
    inputs.dir(assetsDir.dir("icons"))
    outputs.dir(docsDir)

    doLast {
        syncGitHubPagesDocsFiles()
    }
}

val syncGitHubPagesDocsAfterBuild by tasks.registering {
    group = "distribution"
    description = "Ueberschreibt docs/ nach dem Build erneut mit dem neuesten Stand aus app/src/main/assets."

    outputs.upToDateWhen { false }

    doLast {
        syncGitHubPagesDocsFiles()
    }
}

tasks.named("preBuild").configure {
    dependsOn(syncGitHubPagesDocs)
}

tasks.matching {
    name == "build" ||
        name == "assemble" ||
        name.startsWith("assemble") ||
        name.startsWith("bundle")
}.configureEach {
    doLast {
        syncGitHubPagesDocsFiles()
        logger.lifecycle("syncGitHubPagesDocsAfterBuild: docs/ wurde nach dem Build aktualisiert.")
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.activity:activity-ktx:1.10.0")
    implementation("androidx.swiperefreshlayout:swiperefreshlayout:1.1.0")
}
