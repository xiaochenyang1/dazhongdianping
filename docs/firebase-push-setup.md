# Firebase Push Notification Setup for DaZhongDianPing App

## Overview
This document describes how to enable real Firebase push notifications in the Flutter app.

## Step 1: Create Firebase Project (One-time)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (name it `dazhongdianping`)
3. Enable the following products:
   - Cloud Messaging
   - Analytics (optional but recommended)

## Step 2: Download Configuration Files

### For Android (Google Services)
- Download `google-services.json` from Firebase Console → Project Settings → General → Your apps → Android app → Download google-services.json

### For iOS
- Download `GoogleService-Info.plist` from Firebase Console → Project Settings → General → Your apps → iOS app → Download GoogleService-Info.plist

## Step 3: Create `firebase_options.dart`

Create the file at `app/lib/firebase_options.dart` with the following content (you can customize the app ID and other values):

```dart
import 'package:firebase_core/firebase_core.dart';

/// Default [FirebaseOptions] for use with Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not supported by Firebase.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: '1:YOUR_PROJECT_ID:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    appId: '1:YOUR_PROJECT_ID:ios:YOUR_IOS_BUNDLE_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
  );
}
```

## Step 4: Environment Variables

Add to your `.env` file (or CI environment):

```
FIREBASE_ANDROID_API_KEY=your-android-api-key
FIREBASE_IOS_API_KEY=your-ios-api-key
```

## Step 5: Native build config (already wired — do not hand-edit)

Both platforms are already prepared in the repo. Do **not** add Firebase SDK
dependencies by hand: the `firebase_core` / `firebase_messaging` pubspec entries
make FlutterFire manage the Gradle and CocoaPods artifacts, and a manual
`com.google.firebase:firebase-messaging` line will drift from the plugin version.

### Android (`app/android/`)

- `settings.gradle.kts` declares `com.google.gms.google-services` (`apply false`).
- `app/build.gradle.kts` applies it **conditionally**:

  ```kotlin
  if (file("google-services.json").isFile) {
      apply(plugin = "com.google.gms.google-services")
  }
  ```

  So the build works with or without the config file present — dropping in
  `google-services.json` is the only action needed.
- `AndroidManifest.xml` declares `android.permission.POST_NOTIFICATIONS`.
  Android 13+ (API 33) silently drops notifications without it. Note this is a
  *runtime* permission: `firebase_messaging`'s `requestPermission()` triggers the
  system prompt, and a denial still degrades to in-app/WebSocket notifications.

### iOS (`app/ios/`)

- `Runner/Runner.entitlements` carries `aps-environment` (`development`) and is
  wired into the Runner target's Debug, Release and Profile configs via
  `CODE_SIGN_ENTITLEMENTS`. Without it APNs never returns a device token.
  **Release builds must flip this to `production`** (or let Xcode-managed
  signing inject it) or production APNs rejects the token.
- `Runner/Info.plist` declares `UIBackgroundModes: remote-notification` so
  background/silent pushes can wake the app.
- After dropping `GoogleService-Info.plist` into `ios/Runner/`, add it to the
  Runner target in Xcode (drag into the project, tick Runner) — an unreferenced
  file on disk is not read at runtime. Then:

  ```bash
  cd ios && pod install
  ```

- Push requires the Push Notifications capability on the App ID in the Apple
  Developer portal, and a real device: the iOS Simulator cannot register for
  remote notifications.

## Step 6: Runtime init path (already wired)

`app/lib/core/push_service.dart` already prefers `DefaultFirebaseOptions.currentPlatform` and degrades safely when console config is missing:

1. Gate: `ThirdPartyConfig.pushEnabled` (from `FIREBASE_CONFIGURED=true`). When false → `NoOpPushTokenService` (no crash).
2. When enabled, `_FirebasePushTokenService._ensureInitialized()`:
   - no-op if `Firebase.apps` already non-empty;
   - try `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`;
   - on options failure, fall back to platform-default `Firebase.initializeApp()` (needs real `google-services.json` / `GoogleService-Info.plist`);
   - any hard failure → treat as "no push", return null tokens / empty refresh stream.
3. Token: Android/FCM via `getToken()`; iOS via `getAPNSToken()` after permission; channel codes `1=FCM`, `2=APNs`.
4. `onTokenRefresh` never throws when native config is absent; if apps empty it kicks async init and returns an empty stream until listeners re-subscribe after device registration.

You should **not** hand-edit a separate `initializeFirebase()` helper unless you fork the factory. After dropping real options + native files:

- set `FIREBASE_CONFIGURED=true` (or your build dart-define / env path that sets `pushEnabled`);
- rebuild native apps so Gradle/Xcode pick up the config files.

## Step 7: Verification

1. Confirm `app/android/app/google-services.json` and
   `app/ios/Runner/GoogleService-Info.plist` exist (not placeholders), and that
   the plist is added to the Runner target in Xcode.
2. Confirm `app/lib/firebase_options.dart` no longer uses `YOUR_PROJECT_ID`
   placeholders (or rely on the native-file fallback path).
3. Check the bundle/application ID you registered in Firebase matches the build.
   The iOS Runner target currently ships the Flutter default
   `com.example.dazhongdianpingApp`; Android release builds override to a
   production application ID. A mismatch is the most common cause of "no token"
   with everything else configured correctly.
4. Build with push enabled:
   `flutter build apk --dart-define=FIREBASE_CONFIGURED=true` /
   `flutter build ios --dart-define=FIREBASE_CONFIGURED=true`.
5. Real device only (the iOS Simulator cannot register for remote
   notifications): grant notification permission, then confirm the token
   registers through the device API and that the server records the push
   channel.
6. Server side: set `APP_PUSH_ENABLED=true` plus the `APP_PUSH_FCM_*` /
   `APP_PUSH_APNS_*` credentials. They default to empty and push stays off, so
   the adapter never fires with half-configured credentials.
7. Optional: Firebase Console → Cloud Messaging → send a test message to the
   registered token.

Without real console credentials, the app must still build and run with push disabled or degraded — that is the expected local default.

## Common Issues

- **No token with pushEnabled=true**: missing/invalid native config or placeholder `DefaultFirebaseOptions`; check log lines prefixed `Firebase`.
- **Permission denied**: iOS notification permission / Android 13+ POST_NOTIFICATIONS.
- **Background messages**: platform handlers (`UNUserNotificationCenter`, FCM background isolate) still need project-specific wiring beyond token registration.
- **Web**: factory returns `NoOpPushTokenService`; PC uses WebSocket站内通知, not FCM web push.

## Next Steps (product, not blockers for this path)

- Surface "Notifications enabled" on profile after successful device token upload.
- Notification settings screen / topic subscription (e.g. nearby shops) when product requires it.