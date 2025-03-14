import 'package:firebase_auth/firebase_auth.dart';

/// Interface for authentication services that defines the contract for all auth operations.
///
/// This interface is implemented by concrete auth service classes and allows for:
/// - User authentication (email/password, anonymous)
/// - User registration
/// - Password reset
/// - Profile management
///
/// Used by: AuthViewModel, AuthProvider, UserProfileScreen
abstract class AuthServiceInterface {
  /// Get the current authenticated user or null if not authenticated
  User? get currentUser;

  /// Check if there is an authenticated user
  bool get isAuthenticated;

  /// Check if the current user is authenticated anonymously
  bool get isAnonymous;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password);

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(String email, String password);

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously();

  /// Sign out current user
  Future<void> signOut();

  /// Reset password for email
  Future<void> resetPassword(String email);

  /// Update user profile (display name, photo URL)
  Future<void> updateProfile({String? displayName, String? photoURL});

  /// Link anonymous account with email/password credentials
  Future<UserCredential> linkWithEmailPassword(String email, String password);

  /// Listen to auth state changes
  Stream<User?> get authStateChanges;
}
