import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class SampleFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SAMPLE-API-KEY-WEB',
    appId: '1:1234567890:web:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'sportsbook-36vn',
    authDomain: 'sportsbook-36vn.firebaseapp.com',
    storageBucket: 'sportsbook-36vn.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SAMPLE-API-KEY-ANDROID',
    appId: '1:1234567890:android:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'sportsbook-36vn',
    storageBucket: 'sportsbook-36vn.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SAMPLE-API-KEY-IOS',
    appId: '1:1234567890:ios:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'sportsbook-36vn',
    storageBucket: 'sportsbook-36vn.appspot.com',
    iosBundleId: 'com.example.sportsbook36vn',
  );
}
