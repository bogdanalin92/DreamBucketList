import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/interfaces/auth_service_interface.dart';
import 'base_view_model.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

/// ViewModel for managing authentication state and operations
///
/// This class handles authentication state, user management, and related operations.
/// It uses the AuthServiceInterface to perform actual authentication operations,
/// following the dependency inversion principle.
class AuthViewModel extends BaseViewModel {
  final AuthServiceInterface _authService;
  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.initializing;
  String? _error;
  StreamSubscription? _authSubscription;

  AuthViewModel({required AuthServiceInterface authService})
    : _authService = authService {
    _initAuthListener();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAnonymous => _authService.currentUser?.isAnonymous ?? true;

  // Initialize auth listener
  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _currentUser = UserModel.fromFirebaseUser(user);
        _status = AuthStatus.authenticated;
      } else {
        // Ensure we maintain the anonymous state until explicitly signed out
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        // Anonymous sign-in will be handled by AuthServiceImpl._ensureAuthenticated
      }
      _error = null;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _error = null;
      _status = AuthStatus.initializing;
      notifyListeners();

      await _authService.signInWithEmailPassword(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailPassword(String email, String password) async {
    try {
      _error = null;
      _status = AuthStatus.initializing;
      notifyListeners();

      // Try to create user - Firebase will throw an error if email is already in use
      try {
        await _authService.signUpWithEmailPassword(email, password);
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _error = 'An account already exists with this email address.';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      _error = null;
      notifyListeners();

      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Refresh user data
      final user = _authService.currentUser;
      if (user != null) {
        _currentUser = UserModel.fromFirebaseUser(user);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
