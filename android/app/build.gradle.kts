plugins {
    id("com.android.application")

    id("kotlin-android")

    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.example.offline_network_app"

    compileSdk = 35

    ndkVersion = "27.0.12077973"

    compileOptions {

        sourceCompatibility =
            JavaVersion.VERSION_11

        targetCompatibility =
            JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {

        jvmTarget = "11"
    }

    defaultConfig {

        applicationId =
            "com.example.offline_network_app"

        minSdk = 24

        targetSdk = 35

        versionCode =
            flutter.versionCode

        versionName =
            flutter.versionName
    }

    buildTypes {

        release {

            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

flutter {

    source = "../.."
}

dependencies {

    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.0.4"
    )
}