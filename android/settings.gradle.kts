pluginManagement {
    val flutterSdkPath: String = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdk = properties.getProperty("flutter.sdk")
        require(flutterSdk != null) { "flutter.sdk not set in local.properties" }
        flutterSdk
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")