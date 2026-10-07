/// Global app configuration and feature flags.
class AppConfig {
  AppConfig._();

  /// Customer-facing app name.
  static const String appName = 'Ferrer Clothing Rental';
  /// Admin portal display name.
  static const String adminPortalName = 'Ferrer Admin Portal';

  /// Whether Firebase initialized successfully.
  static bool firebaseEnabled = false;
}
