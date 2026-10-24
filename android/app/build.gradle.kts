import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing details are never in version control. The first of these
// that applies is used:
//   1. the file named by PARTICLE_LIBRARY_KEY_PROPERTIES (which must exist),
//   2. android/key.properties,
//   3. ~/.android-keys/particle-library/key.properties, which
//      tool/create_android_key.sh writes next to the keystore it creates.
val keyPropertiesOverride = System.getenv("PARTICLE_LIBRARY_KEY_PROPERTIES")
    ?.takeIf { it.isNotBlank() }
    ?.let { File(it) }
val keystorePropertiesFile: File? = keyPropertiesOverride
    ?: listOf(
        rootProject.file("key.properties"),
        File(System.getProperty("user.home"), ".android-keys/particle-library/key.properties"),
    ).firstOrNull { it.isFile }

val keystoreProperties = Properties()
// Why a release build cannot be signed, or null when it can. Without a key
// Android would build an unsigned APK that no device installs, and one signed
// with the wrong key cannot update an installed copy, so release builds stop
// instead of producing either.
val signingProblem: String? = run {
    if (keystorePropertiesFile == null || !keystorePropertiesFile.isFile) {
        return@run "Release signing key not found" +
            (keyPropertiesOverride?.let { " (PARTICLE_LIBRARY_KEY_PROPERTIES=${it.path})" } ?: "") +
            ". Create one with tool/create_android_key.sh, or point " +
            "PARTICLE_LIBRARY_KEY_PROPERTIES at an existing key.properties. " +
            "See docs/development/ANDROID.md."
    }
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
    val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        return@run "${keystorePropertiesFile.path} lacks: ${missing.joinToString(", ")}."
    }
    val storeFile = file(keystoreProperties.getProperty("storeFile"))
    if (!storeFile.isFile) {
        return@run "The keystore named in ${keystorePropertiesFile.path} does not exist: ${storeFile.path}."
    }
    null
}

android {
    namespace = "io.github.fkguo.particlelibrary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.fkguo.particlelibrary"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (signingProblem == null) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

gradle.taskGraph.whenReady {
    val packagesRelease = allTasks.any { task ->
        task.project == project &&
            Regex("^(assemble|bundle|package)\\w*Release\\w*$").matches(task.name)
    }
    if (packagesRelease && signingProblem != null) {
        throw GradleException(signingProblem)
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
