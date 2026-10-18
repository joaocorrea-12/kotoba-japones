plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}
android {
    namespace = "org.kotoba.android"
    compileSdk = 36
    defaultConfig {
        applicationId = "org.kotoba.android"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
        resourceConfigurations += listOf("pt", "pt-rBR")
    }
    val uploadStore = providers.environmentVariable("KOTOBA_KEYSTORE_PATH").orNull
    if (uploadStore != null) signingConfigs.create("upload") {
        storeFile = file(uploadStore)
        storePassword = providers.environmentVariable("KOTOBA_STORE_PASSWORD").get()
        keyAlias = providers.environmentVariable("KOTOBA_KEY_ALIAS").get()
        keyPassword = providers.environmentVariable("KOTOBA_KEY_PASSWORD").get()
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            if (uploadStore != null) signingConfig = signingConfigs.getByName("upload")
        }
    }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
    sourceSets.getByName("main").assets.srcDir("../../Packages/KotobaCore/Sources/KotobaCore/Resources")
    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.systemProperty("kotoba.words", file("../../Packages/KotobaCore/Sources/KotobaCore/Resources/words.json").absolutePath)
        }
    }
}
dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.04.01"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.0")
    implementation("androidx.core:core-ktx:1.16.0")
    implementation("androidx.work:work-runtime-ktx:2.10.1")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.14.1")
    testImplementation("androidx.test:core:1.6.1")
}
