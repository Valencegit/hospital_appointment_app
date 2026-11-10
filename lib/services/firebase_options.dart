// File: lib/services/firebase_options.dart
// Generated from google-services.json for project: hospitalappointmentapp-41135
//
// ⚠️  Do NOT commit this file to a public repository — it contains your
//    project's API key. Add it to .gitignore if the repo is public.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not configured for this project. '
        'Run flutterfire configure to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS is not configured yet. '
          'Add GoogleService-Info.plist and re-run flutterfire configure.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS is not configured for this project.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows is not configured for this project.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux is not configured for this project.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Android configuration extracted from google-services.json
  /// Project:  hospitalappointmentapp-41135
  /// App ID:   1:414695035637:android:b6cf8e0d057ccf42cf2bbc
  /// Package:  com.hospital_appointment_app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCrKiw9wKCQ1PZI9VXziSku5_X8BS7xExU',
    appId: '1:414695035637:android:b6cf8e0d057ccf42cf2bbc',
    messagingSenderId: '414695035637',
    projectId: 'hospitalappointmentapp-41135',
    storageBucket: 'hospitalappointmentapp-41135.firebasestorage.app',
    databaseURL:
        'https://hospitalappointmentapp-41135-default-rtdb.firebaseio.com',
  );
}
