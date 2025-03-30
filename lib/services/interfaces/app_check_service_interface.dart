import 'package:firebase_app_check/firebase_app_check.dart';

/// Interface for Firebase App Check services that defines the contract for app integrity verification.
///
/// This interface is implemented by concrete App Check service classes and allows for:
/// - Initializing App Check with appropriate providers
/// - Getting App Check token when needed
/// - Verifying app's authenticity
///
/// Used by: FirebaseServicesFactory, main.dart
abstract class AppCheckServiceInterface {
  /// Initialize App Check with appropriate providers
  Future<void> initialize();

  /// Get the current App Check token
  Future<String> getToken({bool forceRefresh = false});

  /// Set the token auto refresh enabled
  Future<void> setTokenAutoRefreshEnabled(bool isTokenAutoRefreshEnabled);

  /// Get the App Check instance
  FirebaseAppCheck get instance;
}
