import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for managing ads across the app
class AdService {
  static AdService? _instance;

  // Use test ad unit IDs during development
  static const String _androidNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _iosNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  // For production, replace these with your real ad unit IDs
  static const String _androidProdNativeAdUnitId =
      'ca-app-pub-4297483923057424/7344359319';
  static const String _iosProdNativeAdUnitId =
      'ca-app-pub-4297483923057424/XXXXXXXXXXXXX'; // Replace with your iOS production ID

  /// Controls frequency of ads in lists - show an ad every this many items
  static const int adInterval = 5;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Get singleton instance
  static Future<AdService> getInstance() async {
    if (_instance == null) {
      _instance = AdService();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Initialize MobileAds SDK
  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      await MobileAds.instance.initialize();
      // Request test configuration in debug mode
      if (kDebugMode) {
        final testDeviceIds = [
          'YOUR_TEST_DEVICE_ID',
        ]; // Add your test device IDs
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: testDeviceIds),
        );
      }
      _initialized = true;
      debugPrint('Mobile ads initialized successfully');
    } catch (e) {
      debugPrint('Error initializing mobile ads: $e');
      // Don't set _initialized to true if initialization failed
    }
  }

  /// Gets the appropriate native ad unit ID based on platform and environment
  String getNativeAdUnitId() {
    if (!_initialized) {
      debugPrint('Warning: Ads not initialized when requesting ad unit ID');
    }

    // Use test ads during development, production ads in release builds
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return _androidNativeAdUnitId;
      } else if (Platform.isIOS) {
        return _iosNativeAdUnitId;
      }
    } else {
      // Production mode - use real ad unit IDs
      if (Platform.isAndroid) {
        return _androidProdNativeAdUnitId;
      } else if (Platform.isIOS) {
        // Verify iOS ad unit ID is properly set
        if (_iosProdNativeAdUnitId.contains('XXXXXXXXXXXXX')) {
          debugPrint(
            'Error: Production iOS ad unit ID not properly configured',
          );
          return _iosNativeAdUnitId; // Fallback to test ad in case of misconfiguration
        }
        return _iosProdNativeAdUnitId;
      }
    }

    debugPrint('Warning: Unknown platform, defaulting to Android ad unit ID');
    return _androidNativeAdUnitId;
  }

  /// Determines if an ad should be shown at a specific position in a list
  bool shouldShowAdAtPosition(int position) {
    // Skip the first few positions to avoid showing ads at the very top
    if (position < 2) return false;

    // Show an ad every [adInterval] items
    return (position + 1) % adInterval == 0;
  }
}
