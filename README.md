# How to Run Premium PDF Reader

## Prerequisites
- **Flutter SDK**: Ensure Flutter is installed and in your PATH. [Install Guide](https://docs.flutter.dev/get-started/install)
- **Editor**: VS Code or Android Studio with Flutter extensions.

## 1. Initial Setup
Open your terminal in this directory and install dependencies:
```bash
flutter pub get
```

## 2. Running on PC (Windows / macOS / Linux)
The app structure supports desktop.
```bash
# For Windows
flutter run -d windows

# For macOS
flutter run -d macos
```
*Note: You may need to enable desktop support first if it's not active:*
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
```

## 3. Running on Android
Requires an Android Emulator or a connected physical device with USB Debugging enabled.
```bash
flutter run -d android
```
**Important**: For the "Library" features to scan real files later, you must add the permission to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```
*(For now, the app runs in "Dummy Mode" so this is optional to just see the UI).*

### Installing permanently (Build APK)
To install the app on your phone so it stays there without the computer connected:
1. Connect your Android phone via USB.
2. Run:
```bash
flutter install
```
Or to build a standalone APK file to share:
```bash
flutter build apk --release
```
The file will be created at: `build/app/outputs/flutter-apk/app-release.apk`. You can copy this file to your phone and install it manually.

## 4. Running on iOS
**Requirement**: You must be on a macOS computer with Xcode installed.
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

## Troubleshooting
- **Missing plugins**: If you see errors about missing plugins, try `flutter clean` then `flutter pub get`.
- **Render errors**: If a specific effect looks weird on Desktop (like glassmorphism), it's usually due to resizing. Drag the window to mobile aspect ratio for the best "Preview" experience.
