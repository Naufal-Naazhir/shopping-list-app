plugins {
    id("com.android.application")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    
}

android {
    namespace = "com.example.belanja_praktis"
    // Compile SDK biarkan default dari Flutter, biasanya 34
    compileSdk = flutter.compileSdkVersion 

    // 1. PERBAIKAN NDK: Ganti baris ini
    // ndkVersion = flutter.ndkVersion
    // MENJADI INI (sesuai log error Anda):
    ndkVersion = "27.0.12077973"

    // 2. PERBAIKAN VERSI JAVA: Kembali ke 1.8 agar konsisten
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        
        // 3. PERBAIKAN DESUGARING (Bagian A): Aktifkan
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // 2. PERBAIKAN VERSI JAVA (Kotlin): Kembali ke 1.8
        jvmTarget = "1.8"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.belanja_praktis"
        //MyFlutterAppAndroidKey ID: 6LcifgYsAAAAAGuYryJtyx_37Xd94E__bFFb2T4t
        
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
    // Increase minSdk to satisfy some plugins (e.g. google_mobile_ads requires 23+)
    minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Tambahkan ini jika Anda menggunakan multidex (opsional tapi disarankan)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    // Use a desugar_jdk_libs version compatible with plugins (flutter_local_notifications requires >= 2.1.4)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Enable multidex runtime support for apps with many methods (keeps compatibility)
    implementation("androidx.multidex:multidex:2.0.1")
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))

    // Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
