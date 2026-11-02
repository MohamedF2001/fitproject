// Remove conflicting ANDROID_PREFS_ROOT env variable to satisfy new AGP check
try {
    val processEnvironment = Class.forName("java.lang.ProcessEnvironment")
    listOf("theEnvironment", "theCaseInsensitiveEnvironment").forEach { fieldName ->
        try {
            val field = processEnvironment.getDeclaredField(fieldName)
            field.isAccessible = true
            @Suppress("UNCHECKED_CAST")
            val map = field.get(null) as MutableMap<String, String>
            map.remove("ANDROID_PREFS_ROOT")
        } catch (_: Exception) {}
    }
} catch (_: Exception) {}


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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
