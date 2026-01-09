# Nainkart (User App)

Nainkart is a Flutter-based mobile application for end users of the Nainkart marketplace. This repository contains the Flutter client app (user-facing), integrating products, orders, consultations, wallet utilities and Firebase services.

**Status:** Active development (main branch)

**Core technologies:** Flutter, Dart, Firebase (Auth, Firestore, Messaging), Android/iOS build targets

--

**Quick Overview**

- A mobile client for browsing products, placing orders, viewing order history, and consulting experts.
- Integrates with Firebase for authentication and backend services.
- Includes in-app features like wallet utilities and consultation history.

**Key directories**

- `lib/` — main Dart source files and app UI.
- `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` — platform folders and native build configs.
- `assets/` — app icons and images.
- `test/` — widget and unit tests.

**Notable packages (examples)**

- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`
- Media & utilities: `camera`, `audioplayers`, `webview_flutter`, `permission_handler`
- Realtime/RTC: `agora_rtc_engine`

--

**Prerequisites**

- Install Flutter SDK (stable channel). See https://flutter.dev/docs/get-started/install
- Java (JDK) and Android SDK for Android builds.
- Xcode for macOS/iOS builds (on macOS).
- Configure Firebase project and download `google-services.json` for Android and `GoogleService-Info.plist` for iOS.

**Local setup**

1. Clone the repo and go to the project folder:

```powershell
cd c:\flutter_apps\nainkart_user
```

2. Get dependencies:

```powershell
flutter pub get
```

3. Add platform Firebase config files:

- Android: place `google-services.json` into `android/app/` (example already present in repo: `android/app/google-services.json`).
- iOS: add `GoogleService-Info.plist` into `ios/Runner/`.

4. (Optional) Add any API keys or sensitive values to `android/key.properties` or platform-specific config. Do NOT commit secrets.

**Run on a device or emulator**

```powershell
flutter run -d <device-id>
```

To list available devices:

```powershell
flutter devices
```

**Build release APK (Android)**

```powershell
flutter build apk --release
```

**Common notes**

- The repository uses Firebase for auth and Firestore; ensure correct Firebase project and rules.
- Some features (RTC, payments) may require extra provider credentials or native SDK setup — check platform folders for provider-specific instructions.
- If you see platform-specific build errors, run `flutter doctor` and follow the suggested fixes.

**Contributing**

- Open issues for bugs or feature requests.
- Create feature branches and submit PRs against `main`.

**Troubleshooting**

- Run `flutter clean` then `flutter pub get` to refresh dependencies.
- Check `android/gradle.properties` and `local.properties` for correct Android SDK paths on your machine.

**License**

This project does not include a license file. Add a `LICENSE` if you wish to make the terms explicit.

--

If you'd like, I can also:

- Add an explicit `Contributing` section with code style and PR checklist.
- Create a `LICENSE` file (choose one).
- Add CI workflow to run `flutter analyze` and tests.

Tell me which of these you want next.
