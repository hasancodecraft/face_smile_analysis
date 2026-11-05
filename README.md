# Face Detection & Smile Analysis

Ostad Module 31 assignment, built with Flutter and Google ML Kit.

Select a photo from the gallery and tap **Analyze**. The app draws a box around each detected face, shows the total face count and smiling percentage, and displays a separate information card for each face. Use **Upload Another Image** to analyze a different photo.

## Packages

- `google_mlkit_face_detection` — face detection and smile classification
- `image_picker` — gallery selection
- `provider` — `ChangeNotifier` state management, following the class examples

## Run

Use Flutter 3.47 or newer with Dart 3.13.2 or newer. This project was checked with Flutter 3.47.9 and Dart 3.13.7.

```sh
flutter pub get
flutter run
```

Choose an Android device/emulator or an iOS device. Google ML Kit in this project does not run in Chrome or as a Windows desktop app.

- Android: minimum API 24; compile SDK 36. Install the Android SDK through Android Studio if needed.
- iOS: minimum iOS 15.5; building requires macOS, Xcode and CocoaPods. Photo-library usage text is included in `Info.plist`.

