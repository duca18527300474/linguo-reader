// Root build.gradle.kts — Kotlin DSL
// All plugin versions are declared in settings.gradle.kts (pluginManagement block)
// No buildscript {} block needed here.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = "../build"

subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
