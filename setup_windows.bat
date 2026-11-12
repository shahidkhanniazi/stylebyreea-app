@echo off
echo ==== Style By Reea app setup ====
where flutter >nul 2>nul || (echo Flutter not found. Install Flutter first: https://docs.flutter.dev/get-started/install/windows & pause & exit /b 1)
call flutter create --org com.stylebyreea --project-name stylebyreea --platforms android,ios .
call flutter pub get
powershell -ExecutionPolicy Bypass -File tool\patch_android.ps1
call dart run flutter_launcher_icons
echo.
echo Building release APK...
call flutter build apk --release
echo.
echo Done! APK: build\app\outputs\flutter-apk\app-release.apk
pause
