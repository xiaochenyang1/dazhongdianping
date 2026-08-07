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

## Step 5: Update build.gradle files

### Android (`app/build.gradle.kts` or `app/build.gradle`)

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

android {
    ...
}

dependencies {
    ...
    implementation("com.google.firebase:firebase-messaging:24.0.1")
}
```

Then in `app/build.gradle` (module level):

```kotlin
plugins {
    id 'com.google.gms.google-services'
}
```

### iOS (`Runner.xcodeproj` or `Podfile`)

Ensure Firebase is properly installed via CocoaPods:

```bash
cd ios
pod install
```

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

1. Confirm `app/android/app/google-services.json` and `app/ios/Runner/GoogleService-Info.plist` exist (not placeholders).
2. Confirm `app/lib/firebase_options.dart` no longer uses `YOUR_PROJECT_ID` placeholders (or rely on native-only fallback).
3. Build: `flutter build apk` / `flutter build ios` with push flag enabled.
4. Real device: grant notification permission; confirm token registers via device API and server push channel.
5. Optional: Firebase Console → Cloud Messaging / token history.

Without real console credentials, the app must still build and run with push disabled or degraded — that is the expected local default.

## Common Issues

- **No token with pushEnabled=true**: missing/invalid native config or placeholder `DefaultFirebaseOptions`; check log lines prefixed `Firebase`.
- **Permission denied**: iOS notification permission / Android 13+ POST_NOTIFICATIONS.
- **Background messages**: platform handlers (`UNUserNotificationCenter`, FCM background isolate) still need project-specific wiring beyond token registration.
- **Web**: factory returns `NoOpPushTokenService`; PC uses WebSocket站内通知, not FCM web push.

## Next Steps (product, not blockers for this path)

- Surface "Notifications enabled" on profile after successful device token upload.
- Notification settings screen / topic subscription (e.g. nearby shops) when product requires it.