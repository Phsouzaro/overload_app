import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de release: android/key.properties (fora do git) aponta para o .jks,
// que fica no OneDrive. Ver "Assinatura do APK" no README.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

// Sem a chave, o build de release falha em vez de assinar com a chave de
// debug: um APK com outra assinatura não atualiza o app já instalado.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any { it.name.contains("Release") }
    if (buildingRelease) {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                "android/key.properties não encontrado: o APK de release precisa " +
                    "da chave do Overload. Veja \"Assinatura do APK\" no README."
            )
        }
        val storeFile = file(keystoreProperties.getProperty("storeFile") ?: "")
        if (!storeFile.exists()) {
            throw GradleException(
                "Chave não encontrada em '$storeFile'. Confira se o OneDrive " +
                    "terminou de sincronizar e o caminho em android/key.properties."
            )
        }
    }
}

android {
    namespace = "com.overload.overload"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.overload.overload"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
