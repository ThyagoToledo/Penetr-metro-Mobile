allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Força compileSdk 36 nos módulos de plugin. Vários plugins compilam contra
    // um SDK antigo (ex.: flutter_native_splash/android-31), incompatível com
    // androidx.window:core:1.0.0 que exige compilar contra 33+. Registrado aqui
    // (antes do evaluationDependsOn) para não falhar com "already evaluated".
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            androidExt.compileSdkVersion(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
