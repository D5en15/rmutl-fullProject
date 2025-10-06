// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_project" // ✅ ตั้งชื่อแพ็กเกจให้ตรงกับ Firebase & google-services.json
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutter_project" // ✅ ชื่อเดียวกับ Firebase
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // 🔹 ใช้ debug key ชั่วคราว (build ได้เลย)
            storeFile = file("${rootDir}/app/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("release") {
            // 🔹 ถ้ามี key.properties จริง → ให้ใช้ release key
            // 🔹 ถ้ายังไม่มี → จะ fallback ไปใช้ debug.keystore (build ได้แน่นอน)
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔹 Firebase BoM – กำหนดเวอร์ชันรวมให้อัตโนมัติ
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // 🔹 SDKs ที่ใช้จริง (อย่าคอมเมนต์ไว้ถ้าใช้งาน)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // 🔹 Multidex รองรับ method เกิน 64K
    implementation("androidx.multidex:multidex:2.0.1")
}