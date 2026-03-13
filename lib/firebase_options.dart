import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Project: civicshield-e8818
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'run flutterfire configure to set up iOS support.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'run flutterfire configure to set up macOS support.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'run flutterfire configure to set up Windows support.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'run flutterfire configure to set up Linux support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5hNN5MmCXTrn82DizwM8lkxJwjAwcjcY',
    appId: '1:453478818769:android:7a5fdc1192c630d098f6f0',
    messagingSenderId: '453478818769',
    projectId: 'civicshield-e8818',
    storageBucket: 'civicshield-e8818.firebasestorage.app',
  );

  // TODO: Add your web app's Firebase config from Firebase Console
  // if you want to support web platform.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5hNN5MmCXTrn82DizwM8lkxJwjAwcjcY',
    appId: '1:453478818769:android:7a5fdc1192c630d098f6f0',
    messagingSenderId: '453478818769',
    projectId: 'civicshield-e8818',
    storageBucket: 'civicshield-e8818.firebasestorage.app',
  );
}
