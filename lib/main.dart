import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/seed_service.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';

import 'screens/explore/explore_screen.dart';
import 'screens/library/library_screen.dart';
import 'utils/route_guard.dart';
import 'utils/logger.dart';
import 'utils/debug_helper.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';

// Navigation observer for logging route changes
class _NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? 'unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'none';
    Logger.navDebug('Navigated to: $routeName (from: $previousRouteName)');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = route.settings.name ?? 'unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'none';
    Logger.navDebug('Popped from: $routeName (to: $previousRouteName)');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newRouteName = newRoute?.settings.name ?? 'unknown';
    final oldRouteName = oldRoute?.settings.name ?? 'unknown';
    Logger.navDebug('Replaced: $oldRouteName with: $newRouteName');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.info('🚀 App starting - Read Next');
  Logger.debug('Initializing Firebase...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.info('✅ Firebase initialized successfully');

    // Configure Firebase Auth settings to fix locale warnings
    FirebaseAuth.instance.setLanguageCode('en');
    Logger.debug('Firebase Auth language code set to: en');

    Logger.info('🎯 Launching app...');

    // Test logging system in debug mode
    DebugHelper.logAppState();
    DebugHelper.testLogging();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    Logger.critical('❌ Failed to initialize Firebase', e, stackTrace);
    // Still try to run the app
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.debug('Building MyApp widget');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) {
            Logger.authDebug('Creating AuthService provider');
            return AuthService();
          },
        ),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        ChangeNotifierProvider<SeedService>(create: (_) => SeedService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Read Next',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const AuthWrapper(),
            onGenerateRoute: _generateRoute,
            debugShowCheckedModeBanner: false,
            navigatorObservers: [_NavigationObserver()],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(
                      context,
                    ).textScaler.scale(1.0).clamp(0.8, 1.2),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  // Route generator with authentication guards
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Logger.navDebug(
      'Generating route for: ${settings.name} with args: ${settings.arguments}',
    );

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
      case '/login':
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );
      case '/register':
        return MaterialPageRoute(
          builder: (context) => const RegisterScreen(),
          settings: settings,
        );
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (context) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (context) => const RouteGuard(child: ProfileScreen()),
          settings: settings,
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (context) => const RouteGuard(child: SettingsScreen()),
          settings: settings,
        );

      case '/search':
      case '/explore':
        return MaterialPageRoute(
          builder: (context) => const RouteGuard(child: ExploreScreen()),
          settings: settings,
        );
      case '/library':
        return MaterialPageRoute(
          builder: (context) => const RouteGuard(child: LibraryScreen()),
          settings: settings,
        );
      default:
        // Return to AuthWrapper for any unknown routes
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
    }
  }
}
