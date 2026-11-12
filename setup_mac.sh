#!/bin/bash
# Style By Reea app setup for macOS (Android + iOS)
set -e
flutter create --org com.stylebyreea --project-name stylebyreea --platforms android,ios .
flutter pub get
if command -v pwsh >/dev/null; then pwsh tool/patch_android.ps1; else
  M=android/app/src/main/AndroidManifest.xml
  grep -q "android.permission.INTERNET" $M || perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.INTERNET"/>#' $M
  sed -i '' 's/android:label="[^"]*"/android:label="Style By Reea"/' $M
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Style By Reea" ios/Runner/Info.plist || true
fi
dart run flutter_launcher_icons
flutter build apk --release
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "iPhone: open ios/Runner.xcworkspace in Xcode, choose your team, then Product > Archive"
