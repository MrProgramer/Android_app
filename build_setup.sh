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
echo "android.useAndroidX=true" >> android/gradle.properties
echo "android.enableJetifier=true" >> android/gradle.properties
echo "Enabled AndroidX and Jetifier in android/gradle.properties"

# 2. Ensure compileSdk is at least 36 in app/build.gradle.kts
if [ -f "android/app/build.gradle.kts" ]; then
  sed -i 's/compileSdk = flutter.compileSdkVersion/compileSdk = 36/g' android/app/build.gradle.kts
  echo "Set compileSdk = 36 in android/app/build.gradle.kts"
fi

echo "=== Preparation finished successfully ==="
