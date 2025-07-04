import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  /// Initialize user data from Firestore
  Future<void> initializeUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      _userModel = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Don't reload if we already have the user data for this user
    if (_userModel != null && _userModel!.uid == user.uid) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        _userModel = UserModel.fromMap(userDoc.data()!);
      } else {
        // Create new user model from Firebase Auth user
        _userModel = UserModel.fromFirebaseUser(user);
        await saveUserModel(_userModel!);
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
      // Fallback to Firebase Auth user
      _userModel = UserModel.fromFirebaseUser(user);

      // Try to save the user model to Firestore
      try {
        await saveUserModel(_userModel!);
      } catch (saveError) {
        debugPrint('Error saving fallback user model: $saveError');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save user model to Firestore
  Future<void> saveUserModel(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .set(userModel.toMap(), SetOptions(merge: true));

      _userModel = userModel;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user model: $e');
      // Still update the local model even if Firestore save fails
      _userModel = userModel;
      notifyListeners();
      rethrow;
    }
  }

  /// Update user avatar data
  Future<void> updateAvatar({
    required String? avatarData,
    required AvatarType avatarType,
    int? backgroundColor,
  }) async {
    if (_userModel == null) {
      // Try to initialize user first
      await initializeUser();
      if (_userModel == null) {
        throw Exception('Unable to load user data');
      }
    }

    final updatedUser = _userModel!.copyWith(
      avatarData: avatarData,
      avatarType: avatarType,
      backgroundColor: backgroundColor,
    );

    await saveUserModel(updatedUser);
  }

  /// Update user display name
  Future<void> updateDisplayName(String displayName) async {
    if (_userModel == null) {
      // Try to initialize user first
      await initializeUser();
      if (_userModel == null) {
        throw Exception('Unable to load user data');
      }
    }

    // Update Firebase Auth profile
    await _auth.currentUser?.updateDisplayName(displayName);

    // Update Firestore document
    final updatedUser = _userModel!.copyWith(displayName: displayName);
    await saveUserModel(updatedUser);
  }

  /// Refresh user data from Firestore
  Future<void> refreshUserData() async {
    await initializeUser();
  }

  /// Clear user data (for sign out)
  void clearUser() {
    _userModel = null;
    notifyListeners();
  }
}
