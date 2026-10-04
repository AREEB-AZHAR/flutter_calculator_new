plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.areeb.balance_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.areeb.balance_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Use baseline ProGuard (not -optimize) to skip ~5 extra R8 passes
            // Switch to proguard-android-optimize.txt only for Play Store submissions
            minifyEnabled = false
            shrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

tasks.register("copyTallyApk") {
    doLast {
        val outputDir = file("${project.layout.buildDirectory.get()}/outputs/flutter-apk")
        val releaseApk = file("$outputDir/app-release.apk")
        if (releaseApk.exists()) {
            releaseApk.copyTo(file("$outputDir/tally.apk"), overwrite = true)
            releaseApk.copyTo(file("$outputDir/tally-release.apk"), overwrite = true)
        }
    }
}

tasks.configureEach {
    if (name.contains("lintVital", ignoreCase = true) || name.contains("LintVital", ignoreCase = true)) {
        enabled = false
    }
    if (name == "assembleRelease" || name == "assemble") {
        finalizedBy("copyTallyApk")
    }
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
