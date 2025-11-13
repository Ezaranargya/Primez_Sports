import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// =======================================
// PROPERTIES & FLUTTER SDK DETECTION
// =======================================
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

// =======================================
// ANDROID CONFIGURATION
// =======================================
android {
    namespace = "com.example.my_app"
    compileSdk = 36
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }
    
    defaultConfig {
        applicationId = "com.example.my_app"
        
        // minSdk 23 untuk kompatibilitas Firebase Auth 23.2.1+
        minSdk = 23
        
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        multiDexEnabled = true
    }
    
    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    buildFeatures {
        buildConfig = true
    }
}

// =======================================
// FLUTTER SOURCE PATH
// =======================================
flutter {
    source = "../.."
}

// =======================================
// DEPENDENCIES
// =======================================
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-auth")
    implementation("androidx.multidex:multidex:2.0.1")
}

// =======================================
// CUSTOM APK OUTPUT LOCATION
// =======================================
afterEvaluate {
    tasks.named("assembleDebug") {
        doLast {
            copy {
                from(layout.buildDirectory.dir("outputs/apk/debug"))
                into(rootProject.projectDir.resolve("../build/app/outputs/flutter-apk"))
                include("*.apk")
            }
        }
    }
    
    tasks.named("assembleRelease") {
        doLast {
            copy {
                from(layout.buildDirectory.dir("outputs/apk/release"))
                into(rootProject.projectDir.resolve("../build/app/outputs/flutter-apk"))
                include("*.apk")
            }
        }
    }
}