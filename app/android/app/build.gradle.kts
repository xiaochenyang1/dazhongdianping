import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val defaultApplicationId = "com.example.dazhongdianping_app"
val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")

if (releasePropertiesFile.exists()) {
    releasePropertiesFile.inputStream().use { releaseProperties.load(it) }
}

fun releaseSetting(name: String): String? =
    (providers.gradleProperty(name).orNull
        ?: providers.environmentVariable(name).orNull
        ?: releaseProperties.getProperty(name))
        ?.trim()
        ?.takeIf { it.isNotEmpty() }

val configuredApplicationId = releaseSetting("DZDP_ANDROID_APPLICATION_ID") ?: defaultApplicationId
val releaseKeystorePath = releaseSetting("DZDP_ANDROID_KEYSTORE_PATH")
val releaseKeyAlias = releaseSetting("DZDP_ANDROID_KEY_ALIAS")
val releaseStorePassword = releaseSetting("DZDP_ANDROID_STORE_PASSWORD")
val releaseKeyPassword = releaseSetting("DZDP_ANDROID_KEY_PASSWORD")
val releaseKeystoreFile = releaseKeystorePath?.let(rootProject::file)
val releaseConfigurationErrors = mutableListOf<String>()

if (configuredApplicationId.startsWith("com.example")) {
    releaseConfigurationErrors += "DZDP_ANDROID_APPLICATION_ID must use the production application ID"
}
if (releaseKeystorePath == null) {
    releaseConfigurationErrors += "DZDP_ANDROID_KEYSTORE_PATH is required"
} else if (releaseKeystoreFile?.isFile != true) {
    releaseConfigurationErrors += "DZDP_ANDROID_KEYSTORE_PATH does not point to a file: $releaseKeystorePath"
}
if (releaseKeyAlias == null) {
    releaseConfigurationErrors += "DZDP_ANDROID_KEY_ALIAS is required"
}
if (releaseStorePassword == null) {
    releaseConfigurationErrors += "DZDP_ANDROID_STORE_PASSWORD is required"
}
if (releaseKeyPassword == null) {
    releaseConfigurationErrors += "DZDP_ANDROID_KEY_PASSWORD is required"
}

gradle.taskGraph.whenReady {
    val includesReleaseTasks = allTasks.any { task ->
        task.name.contains("release", ignoreCase = true)
    }

    if (includesReleaseTasks && releaseConfigurationErrors.isNotEmpty()) {
        throw GradleException(
            "Android release configuration is incomplete:\n" +
                releaseConfigurationErrors.joinToString(separator = "\n") { " - $it" } +
                "\nConfigure Gradle properties, environment variables, or android/key.properties.",
        )
    }
}

android {
    namespace = "com.example.dazhongdianping_app"
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
        applicationId = configuredApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (
            releaseKeystoreFile != null &&
            releaseKeyAlias != null &&
            releaseStorePassword != null &&
            releaseKeyPassword != null
        ) {
            create("release") {
                storeFile = releaseKeystoreFile
                keyAlias = releaseKeyAlias
                storePassword = releaseStorePassword
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfigs.findByName("release")?.let { signingConfig = it }
        }
    }
}

flutter {
    source = "../.."
}
