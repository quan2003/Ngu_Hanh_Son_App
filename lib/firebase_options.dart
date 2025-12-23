// File: lib/firebase_options.dart
// This file should be auto-generated using FlutterFire CLI
// To generate this file, run:
// flutter pub global activate flutterfire_cli
// flutterfire configure

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
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC-D8aCCwhUEfu0DNsRPANU3Rn4tWlieMw',
    appId: '1:437180084643:web:14419f83bec7c0919d6a16',
    messagingSenderId: '437180084643',
    projectId: 'nhs-flutter',
    authDomain: 'nhs-flutter.firebaseapp.com',
    storageBucket: 'nhs-flutter.firebasestorage.app',
    measurementId: 'G-8EQ763EMVC',
  );

  // TODO: Replace with your Firebase project configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALKvDqKXLi-A7hVcaSY91uq_Kl-21l4UM',
    appId: '1:437180084643:android:8f7c849229c5125f9d6a16',
    messagingSenderId: '437180084643',
    projectId: 'nhs-flutter',
    storageBucket: 'nhs-flutter.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCDEXjfHkPe_vuS8layW6LYfAEEhyBm0V4',
    appId: '1:437180084643:ios:3a68dc8e6a2637489d6a16',
    messagingSenderId: '437180084643',
    projectId: 'nhs-flutter',
    storageBucket: 'nhs-flutter.firebasestorage.app',
    iosBundleId: 'vn.nguhanhson.dangbo.nhsDangboApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCDEXjfHkPe_vuS8layW6LYfAEEhyBm0V4',
    appId: '1:437180084643:ios:3a68dc8e6a2637489d6a16',
    messagingSenderId: '437180084643',
    projectId: 'nhs-flutter',
    storageBucket: 'nhs-flutter.firebasestorage.app',
    iosBundleId: 'vn.nguhanhson.dangbo.nhsDangboApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC-D8aCCwhUEfu0DNsRPANU3Rn4tWlieMw',
    appId: '1:437180084643:web:72cd855cda8656e19d6a16',
    messagingSenderId: '437180084643',
    projectId: 'nhs-flutter',
    authDomain: 'nhs-flutter.firebaseapp.com',
    storageBucket: 'nhs-flutter.firebasestorage.app',
    measurementId: 'G-GCJFTFREZ4',
  );
}
