// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.example.flutter_project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    defaultConfig {
        applicationId = "com.example.flutter_project"
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM – จัดการเวอร์ชันให้อัตโนมัติ
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Firebase SDKs ที่ต้องใช้
    implementation("com.google.firebase:firebase-analytics")

    // (ถ้าจะใช้ Auth)
    // implementation("com.google.firebase:firebase-auth")

    // (ถ้าจะใช้ Firestore)
    // implementation("com.google.firebase:firebase-firestore")

    implementation("androidx.multidex:multidex:2.0.1")
}
