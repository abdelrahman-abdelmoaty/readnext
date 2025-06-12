import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

class RouteGuard extends StatelessWidget {
  final Widget child;
  final bool requireAuth;

  const RouteGuard({super.key, required this.child, this.requireAuth = true});

  @override
  Widget build(BuildContext context) {
    if (!requireAuth) {
      return child;
    }

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        switch (authService.authState) {
          case AuthState.initial:
          case AuthState.loading:
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Checking authentication...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );

          case AuthState.authenticated:
            return child;

          case AuthState.unauthenticated:
          case AuthState.error:
            // Redirect to login if not authenticated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            });

            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Redirecting to login...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
