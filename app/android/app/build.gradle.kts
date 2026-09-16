import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is configured through android/key.properties (never committed,
// see .gitignore). Without it, release builds fall back to the debug key so that
// anyone can still build the app from source.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
} else {
    logger.warn("android/key.properties not found: release builds will be signed with the debug key.")
}

android {
    // Historical namespace: the launcher activity has always been
    // com.example.app.MainActivity, so keep it to preserve users' shortcuts.
    namespace = "com.example.app"
    // Compile against the newest installed platform, Android 17 QPR2 (API 37.2).
    // Minor SDK versions need this spec form instead of a bare `compileSdk = 37`.
    compileSdk {
        version = release(37) {
            minorApiLevel = 2
        }
    }
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.nacosiren.blog.mogiciansmanual"
        // Flutter's own floor (24 for Flutter 3.47); every plugin used here accepts it.
        minSdk = flutter.minSdkVersion
        // Google Play requires targetSdk 36 (Android 16) or higher from 2026-08-31;
        // targeting 37 (Android 17) keeps the app a full release ahead of that.
        targetSdk = 37
        // Taken from the `version:` line in pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKeystore) "release" else "debug")
        }
    }

    // No configuration splits: Google Play then installs a single, complete
    // base.apk on every device instead of base + config.<abi>/<density>/<lang>
    // pieces. That file is what the in-app "分享安装包" hands to other phones;
    // a lone base.apk out of a split install is refused by Android 10+ (and
    // would crash on older phones, since the native libraries live in the ABI
    // split). The price is that every download carries all ABIs, about 15 MB
    // per extra ABI here.
    bundle {
        abi { enableSplit = false }
        density { enableSplit = false }
        language { enableSplit = false }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
