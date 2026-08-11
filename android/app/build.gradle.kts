import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

plugins {
    id("com.android.application")

    // Flutter Gradle Plugin después del plugin Android.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.reimii.rol"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.reimii.rol"

        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias =
                    keystoreProperties["keyAlias"]?.toString()

                keyPassword =
                    keystoreProperties["keyPassword"]?.toString()

                storeFile =
                    keystoreProperties["storeFile"]
                        ?.toString()
                        ?.let { file(it) }

                storePassword =
                    keystoreProperties["storePassword"]?.toString()
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}