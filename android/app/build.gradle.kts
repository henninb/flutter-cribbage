import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.brianhenning.cribbage"
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
        applicationId = "com.brianhenning.cribbage"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Always use the keystore from home directory
            storeFile = file("${System.getProperty("user.home")}/.android/keystores/cribbage-release-key.jks")

            // Read passwords from environment variables (required)
            storePassword = System.getenv("CRIBBAGE_KEYSTORE_PASSWORD")
                ?: throw GradleException("CRIBBAGE_KEYSTORE_PASSWORD environment variable not set")
            keyPassword = System.getenv("CRIBBAGE_KEY_PASSWORD")
                ?: throw GradleException("CRIBBAGE_KEY_PASSWORD environment variable not set")

            // Key alias from properties file or default
            keyAlias = keystoreProperties.getProperty("keyAlias")?.takeIf { it.isNotEmpty() }
                ?: "cribbage-release"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Enable ProGuard/R8 for release builds
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
