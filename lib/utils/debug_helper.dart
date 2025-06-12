import 'package:flutter/foundation.dart';
import 'logger.dart';

class DebugHelper {
  static bool _isDebugMode = kDebugMode;

  // Enable/disable debug mode
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
    Logger.setLoggingEnabled(enabled);
  }

  static bool get isDebugMode => _isDebugMode;

  // Test all logging levels
  static void testLogging() {
    if (!_isDebugMode) return;

    Logger.info('🧪 Testing logging system...');

    // Test different log levels
    Logger.debug('This is a debug message');
    Logger.info('This is an info message');
    Logger.warning('This is a warning message');
    Logger.error('This is an error message');
    Logger.critical('This is a critical message');

    // Test convenience methods
    Logger.authDebug('Testing auth debug logging');
    Logger.serviceDebug('TestService', 'Testing service debug logging');
    Logger.screenDebug('TestScreen', 'Testing screen debug logging');
    Logger.navDebug('Testing navigation debug logging');
    Logger.apiDebug('/test', 'Testing API debug logging');

    // Test user action logging
    Logger.userAction('Test Action', {'key': 'value', 'number': 42});

    // Test performance logging
    Logger.performanceDebug(
      'Test Operation',
      const Duration(milliseconds: 150),
    );

    // Test error logging with stack trace
    try {
      throw Exception('Test exception for logging');
    } catch (e, stackTrace) {
      Logger.error('Testing error logging with stack trace', e, stackTrace);
    }

    Logger.info('✅ Logging system test completed');
  }

  // Log app state information
  static void logAppState() {
    if (!_isDebugMode) return;

    Logger.info('📱 App State Information:');
    Logger.debug('Debug mode: $_isDebugMode');
    Logger.debug('Platform: ${defaultTargetPlatform.name}');
    Logger.debug('Release mode: ${kReleaseMode ? 'Yes' : 'No'}');
    Logger.debug('Profile mode: ${kProfileMode ? 'Yes' : 'No'}');
  }

  // Log memory usage (basic)
  static void logMemoryUsage() {
    if (!_isDebugMode) return;

    // Note: This is a basic implementation
    // For more detailed memory profiling, use Flutter DevTools
    Logger.debug(
      '💾 Memory usage logging requested (use Flutter DevTools for detailed analysis)',
    );
  }

  // Log widget build information
  static void logWidgetBuild(String widgetName, [Map<String, dynamic>? data]) {
    if (!_isDebugMode) return;

    final dataStr = data != null ? ' - Data: $data' : '';
    Logger.debug('🏗️ [WIDGET_BUILD] $widgetName$dataStr');
  }

  // Log network requests
  static void logNetworkRequest(
    String method,
    String url, [
    Map<String, dynamic>? data,
  ]) {
    if (!_isDebugMode) return;

    final dataStr = data != null ? ' - Data: $data' : '';
    Logger.debug('🌐 [NETWORK] $method $url$dataStr');
  }

  // Log database operations
  static void logDatabaseOperation(
    String operation,
    String collection, [
    Map<String, dynamic>? data,
  ]) {
    if (!_isDebugMode) return;

    final dataStr = data != null ? ' - Data: $data' : '';
    Logger.debug('🗄️ [DATABASE] $operation on $collection$dataStr');
  }
}
