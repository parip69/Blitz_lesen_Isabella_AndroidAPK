import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val versionPropertiesFile = rootProject.file("version.properties")
val indexHtmlFile = rootProject.file("app/src/main/assets/index.html")

fun loadVersionProperties(path: File): Properties {
    return Properties().apply {
        if (path.exists()) {
            path.inputStream().use(::load)
        } else {
            setProperty("VERSION_CODE", "1")
            setProperty("VERSION_NAME", "1")
        }
    }
}

fun syncHtmlFooterVersion(content: String, versionName: String, label: String): String {
    val footerPattern = Regex("""(<footer\b[^>]*\bdata-app-version=")[^"]*(")""", RegexOption.IGNORE_CASE)
    check(footerPattern.containsMatchIn(content)) { "$label: data-app-version wurde nicht gefunden." }

    return footerPattern.replace(content) {
        "${it.groupValues[1]}$versionName${it.groupValues[2]}"
    }
}

fun syncHtmlServiceWorkerVersion(content: String, cacheName: String, label: String): String {
    val swPattern = Regex("""(const\s+SW_VERSION\s*=\s*")[^"]*(";)""", RegexOption.IGNORE_CASE)
    check(swPattern.containsMatchIn(content)) { "$label: SW_VERSION wurde nicht gefunden." }

    return swPattern.replace(content) {
        "${it.groupValues[1]}$cacheName${it.groupValues[2]}"
    }
}

fun syncServiceWorkerCacheName(content: String, cacheName: String, label: String): String {
    val cachePattern = Regex("""(const\s+CACHE_NAME\s*=\s*')[^']*(';)""", RegexOption.IGNORE_CASE)
    check(cachePattern.containsMatchIn(content)) { "$label: CACHE_NAME wurde nicht gefunden." }

    return cachePattern.replace(content) {
        "${it.groupValues[1]}$cacheName${it.groupValues[2]}"
    }
}

fun syncIndexHtmlFooterVersion(path: File, versionName: String, cacheName: String) {
    if (!path.exists()) return
    val content = path.readText(Charsets.UTF_8)
    val syncedContent = syncHtmlServiceWorkerVersion(
        syncHtmlFooterVersion(content, versionName, path.path),
        cacheName,
        path.path
    )
    path.writeText(syncedContent, Charsets.UTF_8)
}

fun syncServiceWorkerCacheVersion(path: File, cacheName: String) {
    if (!path.exists()) return
    val content = path.readText(Charsets.UTF_8)
    path.writeText(syncServiceWorkerCacheName(content, cacheName, path.path), Charsets.UTF_8)
}

val versionProperties = loadVersionProperties(versionPropertiesFile)
val currentVersionCode = versionProperties.getProperty("VERSION_CODE")?.toIntOrNull() ?: 1
val currentVersionName = versionProperties.getProperty("VERSION_NAME")
    ?.trim()
    ?.takeIf { it.isNotEmpty() }
    ?: currentVersionCode.toString()
val webCacheVersion = "blitzlesen-isabella-v$currentVersionName"

fun String.replaceRequired(oldValue: String, newValue: String, label: String): String {
    check(contains(oldValue)) { "syncGitHubPagesDocs: Abschnitt nicht gefunden: $label" }
    return replace(oldValue, newValue)
}

fun String.insertAfterRequired(anchor: String, addition: String, label: String): String {
    check(contains(anchor)) { "syncGitHubPagesDocs: Anker nicht gefunden: $label" }
    return replace(anchor, anchor + addition)
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
    val sourceHtmlFile = assetsDir.file("index.html").asFile
    val sourceManifestFile = assetsDir.file("manifest.webmanifest").asFile
    val sourceSwFile = assetsDir.file("sw.js").asFile
    docsDirFile.mkdirs()
    docsIconsDir.mkdirs()

    syncIndexHtmlFooterVersion(sourceHtmlFile, currentVersionName, webCacheVersion)
    syncServiceWorkerCacheVersion(sourceSwFile, webCacheVersion)

    val sourceHtml = sourceHtmlFile.readText(Charsets.UTF_8)
    val newline = if (sourceHtml.contains("\r\n")) "\r\n" else "\n"
    fun lines(vararg values: String): String = values.joinToString(newline)
    docsDir.file("index.html").asFile.writeText(sourceHtml, Charsets.UTF_8)

    project.copy {
        from(sourceManifestFile)
        into(docsDirFile)
    }
    project.copy {
        from(assetsDir.dir("icons").asFile)
        into(docsIconsDir)
    }

    project.copy {
        from(sourceSwFile)
        into(docsDirFile)
    }

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
