import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Shared Firestore instance accessor.
class AppFirestore {
  AppFirestore._();

  /// Named Firestore database id.
  static const String databaseId = 'ferrer-db';

  static FirebaseFirestore? _instance;

  /// Lazily created Firestore instance.
  static FirebaseFirestore get instance {
    _instance ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: databaseId,
    );
    return _instance!;
  }
}
