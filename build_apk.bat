@echo off
chcp 65001 > nul
echo ========================================================
echo   در حال دریافت پکیج‌ها و بیلد فایل APK اندروید...
echo ========================================================
echo.

flutter pub get
if %errorlevel% neq 0 (
    echo [خطا] دریافت پکیج‌های فلاتر با خطا مواجه شد. لطفاً از نصب بودن Flutter اطمینان حاصل فرمایید.
    pause
    exit /b %errorlevel%
)

echo.
echo در حال کامپایل و ساخت APK نهایی (Release)...
flutter build apk --release

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo   [موفقیت] فایل APK نهایی با موفقیت ساخته شد:
    echo   build\app\outputs\flutter-apk\app-release.apk
    echo ========================================================
    explorer build\app\outputs\flutter-apk
) else (
    echo.
    echo [خطا] ساخت فایل APK با خطا مواجه شد.
)

pause
