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
/// IMPORTANT: Play Integrity API Setup (replaces deprecated SafetyNet)
/// ================================================================
/// To avoid SafetyNet deprecation warnings, ensure your Firebase Console is configured with:
///
/// 1. In Firebase Console > Project Settings > App Check:
///    - Enable Play Integrity for Android apps
///    - Add your app's SHA-256 fingerprints (debug and release)
///    - Remove any SafetyNet configurations if present
///
/// 2. Get SHA-256 fingerprints using:
///    - Debug: `./gradlew signingReport`
///    - Release: From your keystore or Google Play Console
///
/// 3. Enable App Check for Firestore and other Firebase services
///
/// Used by: main.dart, FirebaseServicesFactory
class AppCheckServiceImpl implements AppCheckServiceInterface {
  final FirebaseAppCheck _appCheck = FirebaseAppCheck.instance;

  @override
  FirebaseAppCheck get instance => _appCheck;

  @override
  Future<void> initialize() async {
    try {
      debugPrint('🔥 Starting Firebase App Check initialization...');
      debugPrint(
        'Platform: ${Platform.isAndroid
            ? "Android"
            : Platform.isIOS
            ? "iOS"
            : "Other"}',
      );
      debugPrint('Debug mode: $kDebugMode');

      // For development and debug builds, always use debug provider first
      if (kDebugMode) {
        debugPrint('Debug mode detected - using debug provider for App Check');
        await _appCheck.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        debugPrint('✅ Debug provider activated successfully');
      } else {
        // Production configuration
        if (Platform.isAndroid) {
          // Use Play Integrity for Android (replaces SafetyNet)
          // Ensure SHA-256 fingerprints are configured in Firebase Console
          debugPrint(
            'Activating Play Integrity provider for Android (replaces SafetyNet)',
          );
          await _appCheck.activate(
            androidProvider: AndroidProvider.playIntegrity,
          );
          debugPrint('✅ Play Integrity provider activated successfully');
        } else if (Platform.isIOS) {
          // Use Device Check for iOS
          debugPrint('Activating Device Check provider for iOS');
          await _appCheck.activate(appleProvider: AppleProvider.deviceCheck);
          debugPrint('✅ Device Check provider activated successfully');
        }
      }

      // Enable token auto refresh
      debugPrint('Enabling token auto refresh...');
      await setTokenAutoRefreshEnabled(true);

      // Test token generation immediately with multiple attempts
      debugPrint('Testing token generation...');
      for (int i = 0; i < 3; i++) {
        try {
          final token = await getToken(forceRefresh: true);
          if (token.isNotEmpty) {
            debugPrint(
              '✅ App Check token generated successfully (attempt ${i + 1})',
            );
            debugPrint('Token preview: ${token.substring(0, 20)}...');
            break;
          } else {
            debugPrint('⚠️ App Check token is empty (attempt ${i + 1})');
            if (i < 2) {
              await Future.delayed(Duration(seconds: 1));
            }
          }
        } catch (tokenError) {
          debugPrint(
            '❌ Token generation error (attempt ${i + 1}): $tokenError',
          );
          if (i < 2) {
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }

      debugPrint('🎉 Firebase App Check initialization completed');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase App Check: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      await _handleAppCheckFallback();
    }
  }

  Future<void> _handleAppCheckFallback() async {
    try {
      debugPrint('Attempting App Check fallback initialization...');

      // Always fall back to debug provider during development
      if (kDebugMode) {
        debugPrint('Falling back to debug provider for App Check');
        await _appCheck.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );

        // Test the fallback token
        final token = await getToken(forceRefresh: true);
        if (token.isNotEmpty) {
          debugPrint('App Check fallback successful with debug token');
        } else {
          debugPrint('App Check fallback completed but no token generated');
        }
      } else {
        debugPrint('Production mode: App Check will use placeholder tokens');
        // In production, Firebase will automatically handle failed App Check
        // by using placeholder tokens when properly configured
      }
    } catch (fallbackError) {
      debugPrint('App Check fallback initialization failed: $fallbackError');
      debugPrint(
        'Firebase will handle App Check failures gracefully with placeholder tokens',
      );
      // This is acceptable - Firebase Firestore will still work with appropriate rules
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
