import 'app_check_service_impl.dart';
import 'auth_service_impl.dart';
import 'firebase_service_impl.dart';
import 'interfaces/app_check_service_interface.dart';
import 'interfaces/auth_service_interface.dart';
import 'interfaces/firebase_service_interface.dart';

/// Factory for creating and accessing Firebase services.
///
/// This class follows the Singleton pattern to ensure a single instance is used throughout the app.
/// It provides access to authentication, Firestore services, and App Check via their interfaces.
///
/// Used by: All ViewModels, Providers, and UI components that need Firebase access
class FirebaseServicesFactory {
  static final FirebaseServicesFactory _instance =
      FirebaseServicesFactory._internal();

  // Lazily initialized services
  late final AuthServiceInterface _authService;
  late final FirebaseServiceInterface _firestoreService;
  late final AppCheckServiceInterface _appCheckService;

  /// Private constructor for singleton pattern
  FirebaseServicesFactory._internal() {
    _authService = AuthServiceImpl();
    _firestoreService = FirebaseServiceImpl();
    _appCheckService = AppCheckServiceImpl();
  }

  /// Factory constructor to return the singleton instance
  factory FirebaseServicesFactory() {
    return _instance;
  }

  /// Creates a new instance with custom implementations (primarily for testing)
  static FirebaseServicesFactory createWithCustomImplementations({
    AuthServiceInterface? authService,
    FirebaseServiceInterface? firestoreService,
    AppCheckServiceInterface? appCheckService,
  }) {
    final factory = FirebaseServicesFactory._internal();
    if (authService != null) {
      factory._authService = authService;
    }
    if (firestoreService != null) {
      factory._firestoreService = firestoreService;
    }
    if (appCheckService != null) {
      factory._appCheckService = appCheckService;
    }
    return factory;
  }

  /// Get the authentication service
  AuthServiceInterface get authService => _authService;

  /// Get the Firestore service
  FirebaseServiceInterface get firestoreService => _firestoreService;

  /// Get the App Check service
  AppCheckServiceInterface get appCheckService => _appCheckService;
}
