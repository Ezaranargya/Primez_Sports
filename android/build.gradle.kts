plugins {
    id("com.android.application") version "8.7.3" apply false
    id("com.android.library") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
}

// =======================
// Repositories untuk seluruh project
// =======================
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

// =======================
// Atur buildDirectory
// =======================
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get().asFile
rootProject.buildDir = newBuildDir

subprojects {
    buildDir = File(newBuildDir, name)
    evaluationDependsOn(":app")
}

// =======================
// Clean Task
// =======================
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
