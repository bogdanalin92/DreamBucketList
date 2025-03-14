import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminUtils {
  /// Shows an error message when a non-admin user tries to access admin features
  static void showAdminOnlyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This operation is restricted to administrators only.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Check if the current user can perform admin operations
  /// Returns true if allowed, false if not (and shows an error message)
  static bool checkAdminPermission(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.canPerformAdminOperation()) {
      showAdminOnlyMessage(context);
      return false;
    }
    return true;
  }
}
