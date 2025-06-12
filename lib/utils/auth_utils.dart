import 'dart:async';
import 'package:flutter/foundation.dart';

class AuthUtils {
  // Debounce timer to prevent too frequent auth state changes
  static Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Debounce function to limit frequent calls
  static void debounce(VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, callback);
  }

  // Check if an error is critical and requires sign out
  static bool isCriticalAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('user-disabled') ||
        errorString.contains('invalid-user-token') ||
        errorString.contains('token-expired') ||
        errorString.contains('session invalid') ||
        errorString.contains('account-exists-with-different-credential');
  }

  // Check if an error is network-related and can be retried
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('dns') ||
        errorString.contains('socket');
  }

  // Format error message for user display
  static String formatErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Remove technical prefixes
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }

    if (errorString.startsWith('FirebaseAuthException: ')) {
      return errorString.substring(23);
    }

    return errorString;
  }

  // Cleanup resources
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
