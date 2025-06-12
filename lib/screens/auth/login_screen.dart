import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../utils/logger.dart';
import '../../utils/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: AppTheme.paddingAll4,
          child: Row(
            children: [
              Container(
                padding: AppTheme.paddingAll8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: AppTheme.paddingAll16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      Logger.userAction('Login attempt', {
        'email': _emailController.text.trim(),
      });
      setState(() => _isLoading = true);
      try {
        await context.read<AuthService>().signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Navigation will be handled by AuthWrapper
        Logger.userAction('Login successful', {
          'email': _emailController.text.trim(),
        });
      } on FirebaseAuthException catch (e) {
        Logger.screenDebug(
          'LoginScreen',
          'Login failed with FirebaseAuthException',
          e,
        );
        if (!mounted) return;
        _showErrorMessage(e.message ?? 'An error occurred');
      } catch (e) {
        if (!mounted) return;
        _showErrorMessage('An unexpected error occurred');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    Logger.userAction('Google sign-in attempt');
    setState(() => _isGoogleLoading = true);
    try {
      await context.read<AuthService>().signInWithGoogle();
      // Navigation will be handled by AuthWrapper
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorMessage(e.message ?? 'Google sign-in failed');
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final isAuthLoading = authService.isLoading;
        final isAnyLoading = _isLoading || _isGoogleLoading || isAuthLoading;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppTheme.paddingAll24,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo/Icon
                        Center(
                          child: Container(
                            padding: AppTheme.paddingAll20,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius20,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              size: 64,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing32),

                        // Welcome Text
                        Text(
                          'Welcome Back!',
                          style: AppTheme.displaySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'Sign in to continue your reading journey',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing48),
                        // Email Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius16,
                            ),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            style: AppTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'Enter your email',
                              hintStyle: AppTheme.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              prefixIcon: Container(
                                padding: AppTheme.paddingAll12,
                                child: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.error,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.error,
                                  width: 2,
                                ),
                              ),
                              errorStyle: AppTheme.bodySmall.copyWith(
                                color: AppTheme.error,
                                height: 1.2,
                              ),
                              contentPadding: AppTheme.paddingH20.add(
                                AppTheme.paddingV16,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final error = context
                                  .read<AuthService>()
                                  .validateEmail(value);
                              return error != null ? '⚠️ $error' : null;
                            },
                            enabled: !isAnyLoading,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing20),

                        // Password Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius16,
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            style: AppTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              hintStyle: AppTheme.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              prefixIcon: Container(
                                padding: AppTheme.paddingAll12,
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                              suffixIcon: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius12,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radius12,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  child: Container(
                                    padding: AppTheme.paddingAll12,
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.error,
                                  width: 2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.error,
                                  width: 2,
                                ),
                              ),
                              errorStyle: AppTheme.bodySmall.copyWith(
                                color: AppTheme.error,
                                height: 1.2,
                              ),
                              contentPadding: AppTheme.paddingH20.add(
                                AppTheme.paddingV16,
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '🔒 Please enter your password';
                              }
                              return null;
                            },
                            enabled: !isAnyLoading,
                            onFieldSubmitted: (_) => _login(),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing12),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius8,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                              onTap:
                                  isAnyLoading
                                      ? null
                                      : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                              child: Container(
                                padding: AppTheme.paddingH12.add(
                                  AppTheme.paddingV8,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing32),

                        // Login Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius16,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: AppTheme.paddingV20,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius16,
                                ),
                              ),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Sign In',
                                      style: AppTheme.titleLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing24),

                        // Divider with "OR" text
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            Container(
                              margin: AppTheme.paddingH24,
                              padding: AppTheme.paddingH16.add(
                                AppTheme.paddingV8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius20,
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'OR',
                                style: AppTheme.labelMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing24),

                        // Google Sign-In Button
                        GoogleSignInButton(
                          onPressed: () => _signInWithGoogle(),
                          isLoading: _isGoogleLoading,
                        ),
                        const SizedBox(height: AppTheme.spacing32),

                        // Register Link
                        Container(
                          padding: AppTheme.paddingV16,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius16,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius8,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radius8,
                                  ),
                                  onTap:
                                      isAnyLoading
                                          ? null
                                          : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const RegisterScreen(),
                                              ),
                                            );
                                          },
                                  child: Container(
                                    padding: AppTheme.paddingH8.add(
                                      AppTheme.paddingV4,
                                    ),
                                    child: Text(
                                      'Sign Up',
                                      style: AppTheme.labelLarge.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
