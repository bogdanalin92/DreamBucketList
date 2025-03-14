import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'interfaces/auth_service_interface.dart';

/// Implementation of the Authentication Service Interface
///
/// Provides concrete implementations for all Firebase Auth operations
/// related to user authentication, registration, and profile management.
///
/// Used by: AuthViewModel, AuthProvider, UserProfileScreen
class AuthServiceImpl implements AuthServiceInterface {
  final FirebaseAuth _auth;

  // List of common valid email domains
  static const List<String> _validEmailDomains = [
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'aol.com',
    'icloud.com',
    'protonmail.com',
    'mail.com',
    'zoho.com',
    'yandex.com',
    'gmx.com',
    'live.com',
    'msn.com',
    'me.com',
    'duck.com',
  ];

  /// Creates an AuthServiceImpl with optional Auth instance for testing
  AuthServiceImpl({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance {
    _ensureAuthenticated();
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  bool get isAuthenticated => _auth.currentUser != null;

  @override
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // New method to ensure user is always authenticated
  Future<void> _ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      await signInAnonymously();
    }
  }

  /// Validates if an email has correct format and comes from a known provider
  ///
  /// Throws an exception if validation fails
  void _validateEmail(String email) {
    // Check format using regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Invalid email format');
    }

    // Extract domain from email
    final domain = email.split('@').last.toLowerCase();

    // Check if domain is from a known provider
    if (!_validEmailDomains.contains(domain)) {
      // Check for edu, gov, org domains which are likely valid
      final validTlds = ['edu', 'gov', 'org', 'net', 'mil'];
      final tld = domain.split('.').last;

      if (!validTlds.contains(tld)) {
        throw Exception('Email domain not recognized as a valid provider');
      }
    }
  }

  @override
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      if (isAnonymous) {
        // If current user is anonymous, we need to handle transition
        final anonymousUserId = _auth.currentUser?.uid;

        // Sign in with email/password
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // If we need to migrate anonymous user data, do it here
          if (anonymousUserId != null) {
            // You might want to implement data migration here if needed
            print(
              'Anonymous user $anonymousUserId converted to email user ${userCredential.user?.uid}',
            );
          }

          return userCredential;
        } on FirebaseAuthException catch (e) {
          // If user not found, throw appropriate exception
          if (e.code == 'user-not-found') {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No user found with this email address.',
            );
          }
          rethrow;
        }
      } else {
        // Direct sign in attempt for already authenticated users
        try {
          return await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          // If user not found, throw appropriate exception
          if (e.code == 'user-not-found') {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No user found with this email address.',
            );
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Error signing in with email and password: $e');
      throw e;
    }
  }

  @override
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // Validate email format and domain
      _validateEmail(email);

      if (isAnonymous) {
        // If current user is anonymous, try to link the account
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        try {
          final userCredential = await _auth.currentUser!.linkWithCredential(
            credential,
          );

          // Store initial user data in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
                'lastUpdated': FieldValue.serverTimestamp(),
              });

          return userCredential;
        } on FirebaseAuthException catch (e) {
          // If email is already in use, try signing out and creating a fresh account
          if (e.code == 'email-already-in-use') {
            // Sign out of the anonymous account
            await _auth.signOut();

            // Create a fresh account
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            // Store initial user data in Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
                  'email': email,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });

            return userCredential;
          }
          // For other errors, just rethrow
          rethrow;
        }
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Store initial user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });

        return userCredential;
      }
    } catch (e) {
      print('Error signing up with email and password: $e');
      throw e;
    }
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      throw e;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Ensure we have an anonymous user after sign out
      await _ensureAuthenticated();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw e;
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      await currentUser!.updateDisplayName(displayName);
      await currentUser!.updatePhotoURL(photoURL);

      // Store user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({
            'displayName': displayName,
            'email': currentUser!.email,
            'photoURL': photoURL,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating profile: $e');
      throw e;
    }
  }

  @override
  Future<UserCredential> linkWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // Validate email format and domain
      _validateEmail(email);

      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      return await currentUser!.linkWithCredential(credential);
    } catch (e) {
      print('Error linking anonymous account: $e');
      throw e;
    }
  }
}
