import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'firebase_options_local.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return LocalFirebaseOptions.currentPlatform;
  }
}
