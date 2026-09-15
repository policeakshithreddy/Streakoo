import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Keys can be injected at build time via --dart-define.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
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
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'YOUR_FIREBASE_ANDROID_API_KEY',
    ),
    appId: '1:542929031554:android:cb8bf7d1b1441bf0c37f9b',
    messagingSenderId: '542929031554',
    projectId: 'streakooo',
    storageBucket: 'streakooo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'YOUR_FIREBASE_IOS_API_KEY',
    ),
    appId: '1:542929031554:ios:4d30e699a48feb5bc37f9b',
    messagingSenderId: '542929031554',
    projectId: 'streakooo',
    storageBucket: 'streakooo.firebasestorage.app',
    iosBundleId: 'com.example.streakoo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_MACOS_API_KEY',
      defaultValue: 'YOUR_FIREBASE_MACOS_API_KEY',
    ),
    appId: '1:542929031554:ios:4d30e699a48feb5bc37f9b',
    messagingSenderId: '542929031554',
    projectId: 'streakooo',
    storageBucket: 'streakooo.firebasestorage.app',
    iosBundleId: 'com.example.streakoo',
  );
}
