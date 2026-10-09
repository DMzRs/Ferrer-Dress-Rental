/// Firestore collection name constants.
class FirestoreCollections {
  FirestoreCollections._();

  /// User profiles collection.
  static const users = 'users';
  /// Catalog items collection.
  static const items = 'items';
  /// Item photos subcollection.
  static const itemPhotos = 'itemPhotos';
  /// Rentals collection.
  static const rentals = 'rentals';
  /// Fitting appointments collection.
  static const appointments = 'appointments';
  /// Item reviews collection.
  static const reviews = 'reviews';
  /// Chat conversations collection.
  static const conversations = 'conversations';
  /// Per-day fitting-slot holds (`{yyyy-MM-dd}/holds/{appointmentId}`).
  static const slotAvailability = 'slotAvailability';
}
