import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Project: civicsheild-3d808
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
    apiKey: 'AIzaSyCzOp8HFnKz5MuZVS305s0hmMIT1GwQ5lo',
    appId: '1:299870255203:android:02a083f18e7812b8922056',
    messagingSenderId: '299870255203',
    projectId: 'civicsheild-3d808',
    storageBucket: 'civicsheild-3d808.firebasestorage.app',
  );

  // TODO: Add your web app's Firebase config from Firebase Console
  // if you want to support web platform.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCzOp8HFnKz5MuZVS305s0hmMIT1GwQ5lo',
    appId: '1:299870255203:android:02a083f18e7812b8922056',
    messagingSenderId: '299870255203',
    projectId: 'civicsheild-3d808',
    storageBucket: 'civicsheild-3d808.firebasestorage.app',
  );
}
