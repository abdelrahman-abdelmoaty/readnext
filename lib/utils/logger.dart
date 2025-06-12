import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, critical }

class Logger {
  static const String _appName = 'ReadNext';
  static bool _enableLogging = kDebugMode; // Only log in debug mode by default

  // Enable/disable logging
  static void setLoggingEnabled(bool enabled) {
    _enableLogging = enabled;
  }

  // Main logging method
  static void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_enableLogging) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(8);
    final logMessage = '[$_appName] $timestamp [$levelStr] $message';

    // Use debugPrint in debug mode, print in other modes
    if (kDebugMode) {
      debugPrint(logMessage);
      if (error != null) {
        debugPrint('[$_appName] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_appName] Stack trace:\n$stackTrace');
      }
    } else {
      debugPrint(logMessage);
      if (error != null) {
        debugPrint('[$_appName] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_appName] Stack trace:\n$stackTrace');
      }
    }
  }

  // Debug logs - for detailed debugging information
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  // Info logs - for general information
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  // Warning logs - for potential issues
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  // Error logs - for actual errors
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  // Critical logs - for critical system errors
  static void critical(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }

  // Convenience methods for common scenarios
  static void authDebug(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debug('[AUTH] $message', error, stackTrace);
  }

  static void serviceDebug(
    String serviceName,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debug('[${serviceName.toUpperCase()}] $message', error, stackTrace);
  }

  static void screenDebug(
    String screenName,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debug('[SCREEN:${screenName.toUpperCase()}] $message', error, stackTrace);
  }

  static void navDebug(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debug('[NAVIGATION] $message', error, stackTrace);
  }

  static void apiDebug(
    String endpoint,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debug('[API:$endpoint] $message', error, stackTrace);
  }

  static void userAction(String action, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' - Data: $data' : '';
    info('[USER_ACTION] $action$dataStr');
  }

  static void performanceDebug(
    String operation,
    Duration duration, [
    Map<String, dynamic>? data,
  ]) {
    final dataStr = data != null ? ' - Data: $data' : '';
    debug('[PERFORMANCE] $operation took ${duration.inMilliseconds}ms$dataStr');
  }
}
