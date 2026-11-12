# Adds internet permission, app name and link queries to the Android manifest.
$m = "android/app/src/main/AndroidManifest.xml"
if (!(Test-Path $m)) { Write-Host "Manifest not found - run 'flutter create .' first"; exit 1 }
$x = Get-Content $m -Raw
if ($x -notmatch "android.permission.INTERNET") {
  $x = $x -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
}
$x = $x -replace 'android:label="[^"]*"', 'android:label="Style By Reea"'
if ($x -notmatch "<queries>") {
  $q = @"
    <queries>
        <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
        <intent><action android:name="android.intent.action.SENDTO" /><data android:scheme="mailto" /></intent>
    </queries>
</manifest>
"@
  $x = $x -replace '</manifest>\s*$', $q
}
Set-Content $m $x -Encoding UTF8
# iOS display name
$p = "ios/Runner/Info.plist"
if (Test-Path $p) {
  $i = Get-Content $p -Raw
  $i = $i -replace '(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', '$1Style By Reea$2'
  Set-Content $p $i -Encoding UTF8
}
Write-Host "Android/iOS settings patched."
