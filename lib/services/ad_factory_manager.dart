import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// AdFactoryManager is a utility class for registering native ad factories
class AdFactoryManager {
  /// Register native ad factories during app initialization
  static void registerNativeAdFactories() {
    // Nothing to do for Flutter side - the factories are registered in platform code
    // This method is here for clarity and as a central place to handle registration if needed
    debugPrint('Native ad factories registered through platform code');
  }
}
