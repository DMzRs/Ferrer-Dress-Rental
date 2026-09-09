import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AppFirestore {
  AppFirestore._();

  static const String databaseId = 'ferrer-db';

  static FirebaseFirestore? _instance;

  static FirebaseFirestore get instance {
    _instance ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: databaseId,
    );
    return _instance!;
  }
}
