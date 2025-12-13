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

    // Check if signing credentials are available
    val hasSigningCredentials = System.getenv("CRIBBAGE_KEYSTORE_PASSWORD") != null &&
                                System.getenv("CRIBBAGE_KEY_PASSWORD") != null

    signingConfigs {
        if (hasSigningCredentials) {
            create("release") {
                // Always use the keystore from home directory
                storeFile = file("${System.getProperty("user.home")}/.android/keystores/cribbage-release-key.jks")

                // Read passwords from environment variables
                storePassword = System.getenv("CRIBBAGE_KEYSTORE_PASSWORD")
                keyPassword = System.getenv("CRIBBAGE_KEY_PASSWORD")

                // Key alias from properties file or default
                keyAlias = keystoreProperties.getProperty("keyAlias")?.takeIf { it.isNotEmpty() }
                    ?: "cribbage-release"
            }
        }
    }

    buildTypes {
        release {
            // Only use release signing if credentials are available
            if (hasSigningCredentials) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Enable ProGuard/R8 for release builds
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
