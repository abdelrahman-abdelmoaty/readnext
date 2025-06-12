import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

class AuthNavigationObserver extends NavigatorObserver {
  final List<String> _protectedRoutes = [
    '/profile',
    '/settings',
    '/home',
    '/explore',
    '/library',
  ];

  final List<String> _publicRoutes = [
    '/login',
    '/register',
    '/forgot-password',
  ];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkAuthentication(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkAuthentication(newRoute);
    }
  }

  void _checkAuthentication(Route<dynamic> route) {
    final routeName = route.settings.name;

    if (routeName == null) return;

    // If it's a public route, no authentication needed
    if (_publicRoutes.contains(routeName)) {
      return;
    }

    // If it's a protected route, check authentication
    if (_protectedRoutes.contains(routeName)) {
      // Get the navigator context
      final context = navigator?.context;
      if (context == null) return;

      // Check authentication status
      final authService = Provider.of<AuthService>(context, listen: false);

      if (!authService.isAuthenticated) {
        // User is not authenticated, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            ),
            (route) => false,
          );
        });
      }
    }
  }
}
