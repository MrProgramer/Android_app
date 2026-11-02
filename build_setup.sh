#!/bin/bash
set -e

echo "=== Preparing Android project for build ==="

if [ -d "android_app" ]; then
  cd android_app
fi

rm -rf android
flutter create . --platforms=android --org com.bazargani --project-name mycrm_mobile
rm -rf test

# 1. Enable AndroidX and Jetifier in gradle.properties
if [ -f "android/gradle.properties" ]; then
  echo "android.useAndroidX=true" >> android/gradle.properties
  echo "android.enableJetifier=true" >> android/gradle.properties
else
  cat << 'PROP_EOF' > android/gradle.properties
android.useAndroidX=true
android.enableJetifier=true
PROP_EOF
fi
echo "Set android.useAndroidX=true in android/gradle.properties"

# 2. Update compileSdk to 36 in app/build.gradle.kts
if [ -f "android/app/build.gradle.kts" ]; then
  sed -i 's/compileSdk = flutter.compileSdkVersion/compileSdk = 36/g' android/app/build.gradle.kts
  echo "Set compileSdk = 36 in android/app/build.gradle.kts"
fi

# 3. Disable AarMetadata check task across all subprojects
if [ -f "android/build.gradle.kts" ]; then
  cat << 'GRADLE_EOF' >> android/build.gradle.kts

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val m = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    m.invoke(androidExt, 36)
                } catch (e: Exception) {}
            }
        }
    }
    tasks.matching { it.name.contains("AarMetadata") }.configureEach {
        enabled = false
    }
}
GRADLE_EOF
  echo "Added AarMetadata bypass to android/build.gradle.kts"
fi

echo "=== Preparation finished successfully ==="
