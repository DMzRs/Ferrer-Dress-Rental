import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';
import '../../firebase_options.dart';

/// Firebase initialization helper.
class FirebaseService {
  FirebaseService._();

  /// Initializes Firebase and flags availability.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppConfig.firebaseEnabled = true;
    } on Exception catch (_) {
      AppConfig.firebaseEnabled = false;
    } on Object {
      AppConfig.firebaseEnabled = false;
    }
  }
}
