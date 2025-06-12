import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import 'login_screen.dart';
import '../main/main_navigation.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.screenDebug('AuthWrapper', 'Building AuthWrapper widget');

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        Logger.screenDebug(
          'AuthWrapper',
          'Auth state: ${authService.authState.name}, User: ${authService.currentUser?.email ?? 'null'}',
        );

        switch (authService.authState) {
          case AuthState.initial:
          case AuthState.loading:
            Logger.screenDebug('AuthWrapper', 'Showing loading screen');
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );

          case AuthState.authenticated:
            Logger.screenDebug(
              'AuthWrapper',
              'User is authenticated: ${authService.currentUser?.email}',
            );
            return const MainNavigation();

          case AuthState.unauthenticated:
            Logger.screenDebug(
              'AuthWrapper',
              'User is not authenticated, showing login screen',
            );
            return const LoginScreen();

          case AuthState.error:
            Logger.screenDebug(
              'AuthWrapper',
              'Authentication error occurred: ${authService.errorMessage}',
            );
            // Show error message briefly, then proceed to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && authService.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authService.errorMessage!),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            });
            return const LoginScreen();
        }
      },
    );
  }
}
