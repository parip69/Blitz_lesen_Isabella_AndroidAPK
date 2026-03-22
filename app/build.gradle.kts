import java.nio.charset.StandardCharsets
import java.util.Properties

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
    }
}
val currentVersion = versionProperties.getProperty("VERSION_CODE")?.toIntOrNull() ?: 1
val backupDirectory = rootProject.file("Privat")
var buildArtifactsFinalized = false

fun backupVersionedArtifacts(version: Int) {
    backupDirectory.mkdirs()

    val sourceHtml = rootProject.file("app/src/main/assets/index.html")
    if (sourceHtml.exists()) {
        val versionedHtml = sourceHtml.readText(StandardCharsets.UTF_8)
            .replace("""<span id="appVersion">-</span>""", """<span id="appVersion">$version</span>""")
        rootProject.file("Privat/Blitzlesen_v$version.html")
            .writeText(versionedHtml, StandardCharsets.UTF_8)
    }

    val apkOutputDirectory = rootProject.file("app/build/outputs/apk")
    if (apkOutputDirectory.exists()) {
        apkOutputDirectory.walkTopDown()
            .filter { file ->
                file.isFile &&
                    file.extension.equals("apk", ignoreCase = true) &&
                    file.name.contains("-v$version")
            }
            .forEach { apkFile ->
                apkFile.copyTo(rootProject.file("Privat/${apkFile.name}"), overwrite = true)
            }
    }
}

fun finalizeVersionedBuild(version: Int) {
    if (buildArtifactsFinalized) return

    buildArtifactsFinalized = true
    backupVersionedArtifacts(version)
    versionProperties.setProperty("VERSION_CODE", (version + 1).toString())
    versionPropertiesFile.writer().use { writer ->
        versionProperties.store(writer, "Naechste Build-Version")
    }
}

android {
    namespace = "de.parip69.blitzlesen"
    compileSdk = 35

    defaultConfig {
        applicationId = "de.parip69.blitzlesen"
        minSdk = 24
        targetSdk = 35
        versionCode = currentVersion
        versionName = currentVersion.toString()

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
            output.outputFileName = "BlitzLesen-v${versionName}.apk"
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.activity:activity-ktx:1.10.0")
    implementation("androidx.swiperefreshlayout:swiperefreshlayout:1.1.0")
}

tasks.configureEach {
    if (name.matches(Regex("assemble[A-Z].+")) || name.matches(Regex("bundle[A-Z].+"))) {
        doLast {
            finalizeVersionedBuild(currentVersion)
        }
    }
}
