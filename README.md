# Style By Reea — Flutter App (Android + iPhone)

Native shopping app for **stylebyreea.com**. Products, prices, images, sizes and stock come **live from the website** (WooCommerce Store API) — add or edit a product in WordPress and it appears in the app automatically. No API keys are stored in the app.

## Features
- Animated splash, black & gold design matching the website
- Home: auto-sliding hero, announcement marquee, categories, new arrivals, co-ord sets, denim edit, men/women banners
- Shop: all categories with sub-categories, sorting, infinite scroll, pull-to-refresh
- Product: swipe gallery + full-screen zoom, size buttons (unavailable sizes crossed out), size guide, quantity, related products
- Search with live results, trending & recent searches
- Wishlist (saved on phone)
- Bag: quantity +/-, remove, coupons, free-delivery progress bar
- **Native checkout**: contact, address, delivery method, payment method (whatever is enabled in WooCommerce, e.g. Cash on Delivery), order notes, order summary
- Redirect payment gateways (e.g. PayPal) open securely inside the app
- Order success screen, "My orders" with live status refresh
- Help pages (Track order, FAQ, Size guide, Shipping & Returns…), email & WhatsApp

## Build the Android APK (Windows)
1. Install Flutter (3.24 or newer) + Android Studio: https://docs.flutter.dev/get-started/install/windows
2. Extract this folder, e.g. `C:\StyleByReeaApp`
3. Double-click **`setup_windows.bat`**
   (it runs `flutter create`, installs packages, sets app name/permissions, makes the app icon and builds the APK)
4. APK: `build\app\outputs\flutter-apk\app-release.apk` — copy to a phone and install.

Run on a connected phone / emulator: `flutter run`

## iPhone
On a Mac with Xcode: run `./setup_mac.sh`, then open `ios/Runner.xcworkspace` in Xcode, select your Apple Developer team, and use **Product → Archive** to upload to the App Store / TestFlight.

## Play Store release
Create an upload key and set up signing as described at https://docs.flutter.dev/deployment/android, then build `flutter build appbundle --release` and upload the `.aab` file.

## Settings (`lib/config.dart`)
- `siteUrl` — store address
- `whatsapp` — WhatsApp number with country code, digits only (shows "Chat on WhatsApp")
- `email`, `defaultCountry`, size order, home-page categories

## Store requirements
- WooCommerce 8+ (Store API is built in)
- At least one payment method enabled (WooCommerce → Settings → Payments)
- For delivery options: set Shipping zones in WooCommerce → Settings → Shipping
