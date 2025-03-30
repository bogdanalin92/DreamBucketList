import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'interfaces/app_check_service_interface.dart';

/// Implementation of the AppCheckServiceInterface using Firebase App Check.
///
/// This service handles the initialization and management of Firebase App Check,
/// which helps protect your backend resources from abuse by verifying that
/// incoming requests are from your app.
///
/// Used by: main.dart, FirebaseServicesFactory
class AppCheckServiceImpl implements AppCheckServiceInterface {
  final FirebaseAppCheck _appCheck = FirebaseAppCheck.instance;

  @override
  FirebaseAppCheck get instance => _appCheck;

  @override
  Future<void> initialize() async {
    try {
      // Configure different providers based on platform
      if (Platform.isAndroid) {
        // Use Play Integrity for Android with SHA-256 key configured in Firebase Console
        debugPrint('Activating Play Integrity provider for Android');
        await _appCheck.activate(
          androidProvider: AndroidProvider.playIntegrity,
        );
      } else if (Platform.isIOS) {
        // Use Device Check for iOS
        debugPrint('Activating Device Check provider for iOS');
        await _appCheck.activate(appleProvider: AppleProvider.deviceCheck);
      } else if (kDebugMode) {
        // Use debug provider for development
        debugPrint('Activating debug provider for development');
        await _appCheck.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      }

      // Enable token auto refresh
      await setTokenAutoRefreshEnabled(true);

      debugPrint('Firebase App Check initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase App Check: $e');
      // Fall back to debug provider if anything fails
      if (kDebugMode) {
        await _appCheck.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      }
    }
  }

  @override
  Future<String> getToken({bool forceRefresh = false}) async {
    try {
      final result = await _appCheck.getToken(forceRefresh);
      return result ?? '';
    } catch (e) {
      debugPrint('Error getting App Check token: $e');
      return '';
    }
  }

  @override
  Future<void> setTokenAutoRefreshEnabled(
    bool isTokenAutoRefreshEnabled,
  ) async {
    await _appCheck.setTokenAutoRefreshEnabled(isTokenAutoRefreshEnabled);
  }
}
