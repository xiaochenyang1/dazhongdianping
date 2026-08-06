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

## Step 6: Update `push_service.dart` (if needed)

Ensure it uses the new `firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

## Step 7: Verification

1. Build the app: `flutter build apk` (Android) or `flutter build ios` (iOS)
2. Test on a real device
3. Check Firebase Console → Analytics for token registration

## Common Issues

- **No token**: Check Firebase Console → Cloud Messaging → Token history
- **Permission denied**: Ensure `info.plist` has `NSSound` and `NSMicrophone` keys
- **Background messages**: Add `UNNotificationPresentationOptions` in `didReceiveRemoteNotification`

## Next Steps

- Add push token handling to user profile (show "Notifications enabled" status)
- Implement notification settings screen
- Add "Topic" subscription (e.g., "nearby-shops")