@echo off
chcp 65001 > nul
echo ========================================================
echo   در حال آماده‌سازی و بیلد فایل APK اندروید...
echo ========================================================
echo.

if exist "android" (
    echo پاک‌سازی ساختار قبلی برای جلوگیری از تداخل فایل‌های گریدل...
    rmdir /s /q android
)

echo ایجاد ساختار تمیز و سازگار پلتفرم اندروید...
call flutter create . --platforms=android --org com.bazargani --project-name mycrm_mobile
if exist "test" (
    rmdir /s /q test
)

if exist "android_custom\MainActivity.kt" (
    echo تزریق فایل‌منیجر بومی اندروید...
    copy /Y "android_custom\MainActivity.kt" "android\app\src\main\kotlin\com\bazargani\mycrm_mobile\MainActivity.kt"
)

echo تنظیم AndroidX...
if exist "android\gradle.properties" (
    echo android.useAndroidX=true >> android\gradle.properties
    echo android.enableJetifier=true >> android\gradle.properties
)

echo دریافت پکیج‌های فلاتر...
call flutter pub get
if %errorlevel% neq 0 (
    echo [خطا] دریافت پکیج‌های فلاتر با خطا مواجه شد.
    pause
    exit /b %errorlevel%
)

echo.
echo در حال کامپایل و ساخت APK نهایی (Release)...
call flutter build apk --release --android-skip-build-dependency-validation

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo   [موفقیت] فایل APK نهایی با موفقیت ساخته شد:
    echo   build\app\outputs\flutter-apk\app-release.apk
    echo ========================================================
    if exist "build\app\outputs\flutter-apk" (
        explorer build\app\outputs\flutter-apk
    )
) else (
    echo.
    echo [خطا] ساخت فایل APK با خطا مواجه شد.
)

pause
