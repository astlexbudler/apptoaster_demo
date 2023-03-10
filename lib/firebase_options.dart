// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC2H1n3-tib4mLmJ87dkmn4CUEbIgzigRA',
    appId: '1:3121618070:web:3d598c5dd86665e5e436b7',
    messagingSenderId: '3121618070',
    projectId: 'apptoaster-demo',
    authDomain: 'apptoaster-demo.firebaseapp.com',
    storageBucket: 'apptoaster-demo.appspot.com',
    measurementId: 'G-RB9E0N7E9E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmpOaqcvJS_4ZNVMEzJNkSvcgH9SjWVxs',
    appId: '1:3121618070:android:dd3e5615edce9f7ee436b7',
    messagingSenderId: '3121618070',
    projectId: 'apptoaster-demo',
    storageBucket: 'apptoaster-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAElcmNRVjrgMeY9rWmQAuI4cyzNLvv3W0',
    appId: '1:3121618070:ios:e434a1363ade6136e436b7',
    messagingSenderId: '3121618070',
    projectId: 'apptoaster-demo',
    storageBucket: 'apptoaster-demo.appspot.com',
    iosClientId: '3121618070-h3692gtc3d53qu4fdmukrptr1b223vhh.apps.googleusercontent.com',
    iosBundleId: 'com.apptoaster.demo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAElcmNRVjrgMeY9rWmQAuI4cyzNLvv3W0',
    appId: '1:3121618070:ios:e434a1363ade6136e436b7',
    messagingSenderId: '3121618070',
    projectId: 'apptoaster-demo',
    storageBucket: 'apptoaster-demo.appspot.com',
    iosClientId: '3121618070-h3692gtc3d53qu4fdmukrptr1b223vhh.apps.googleusercontent.com',
    iosBundleId: 'com.apptoaster.demo',
  );
}
