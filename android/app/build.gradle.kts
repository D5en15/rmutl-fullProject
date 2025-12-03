// android/app/build.gradle.kts

import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_project" // ✅ ให้ตรงกับ Firebase project name
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = "11" }

    defaultConfig {
        applicationId = "com.example.flutter_project"
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // 🔹 ลองโหลด key.properties ถ้ามี
    val keystoreProperties = Properties()
    val keystoreFile = rootProject.file("key.properties")
    val hasReleaseKeystore = keystoreFile.exists()
    if (hasReleaseKeystore) {
        keystoreProperties.load(FileInputStream(keystoreFile))
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                // ✅ ใช้ key.properties จริง (ถ้ามี)
                storeFile = file(keystoreProperties["storeFile"] ?: "")
                storePassword = keystoreProperties["storePassword"]?.toString()
                keyAlias = keystoreProperties["keyAlias"]?.toString()
                keyPassword = keystoreProperties["keyPassword"]?.toString()
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // ✅ Firebase SDKs
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // ✅ รองรับ multidex
    implementation("androidx.multidex:multidex:2.0.1")
}
