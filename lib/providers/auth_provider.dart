import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/interfaces/firebase_service_interface.dart';
import '../services/interfaces/auth_service_interface.dart';
import '../models/user_model.dart';

/// Provider for authentication state and operations
///
/// This class provides authentication state to the widget tree and
/// handles authentication-related operations. It uses the AuthServiceInterface
/// and FirebaseServiceInterface to perform actual operations.
class AuthProvider extends ChangeNotifier {
  final AuthServiceInterface _authService;
  final FirebaseServiceInterface _firestoreService;
  final FirebaseFirestore _firestore;
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isAdmin = false;

  /// Creates a new AuthProvider with the provided services
  AuthProvider({
    required AuthServiceInterface authService,
    required FirebaseServiceInterface firestoreService,
    FirebaseFirestore? firestore,
  }) : _authService = authService,
       _firestoreService = firestoreService,
       _firestore = firestore ?? FirebaseFirestore.instance {
    _initializeUser();
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  String get userId => _user?.uid ?? '';
  String get userEmail => _user?.email ?? '';
  User? get currentUser => _user;
  String? get displayName => _user?.displayName;
  UserModel? get userModel => _userModel;

  void _initializeUser() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        // Fetch or create user model when user signs in
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        _userModel =
            userDoc.exists
                ? UserModel.fromMap(userDoc.data()!)
                : UserModel.fromFirebaseUser(user);

        if (!user.isAnonymous) {
          await _checkAdminStatus();
        } else {
          _isAdmin = false;
        }
      } else {
        _isAdmin = false;
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _checkAdminStatus() async {
    try {
      if (_user == null || _user!.isAnonymous) {
        _isAdmin = false;
        return;
      }

      final docRef =
          await _firestore.collection('admins').doc(_user!.uid).get();

      _isAdmin = docRef.exists;
      notifyListeners();
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to sign in - Firebase will throw an error if user doesn't exist
      try {
        await _authService.signInWithEmailPassword(email, password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this email address.',
          );
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to create user - Firebase will throw an error if email is already in use
      try {
        await _authService.signUpWithEmailPassword(email, password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'An account already exists with this email address.',
          );
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error signing up with email and password: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateProfile(displayName: name);

      // Update Firestore user document
      await _firestore.collection('users').doc(_user!.uid).update({
        'displayName': name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePrivacyConsent(PrivacyConsent newConsent) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user == null || _user!.isAnonymous) {
        throw Exception('User must be signed in to update privacy preferences');
      }

      // Update or create Firestore user document with new consent using set with merge
      await _firestore.collection('users').doc(_user!.uid).set({
        'privacyConsent': newConsent.toMap(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local user model
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(privacyConsent: newConsent);
      }
    } catch (e) {
      print('Error updating privacy consent: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool canShareWithThirdParties() {
    return _userModel?.privacyConsent.thirdPartyShareConsent ?? false;
  }

  bool canCollectAnalytics() {
    return _userModel?.privacyConsent.analyticsConsent ?? false;
  }

  bool canPerformAdminOperation() {
    return _isAdmin && !isAnonymous;
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _firestoreService.deleteBucketListItem(itemId);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }
}
