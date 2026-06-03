buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Gradle plugin actualizado
        classpath 'com.android.tools.build:gradle:8.2.1'
        // ✅ Google Services para Firebase
        classpath 'com.google.gms:google-services:4.4.2'
        // ✅ Kotlin plugin (asegúrate de tenerlo)
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'

subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}

subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
