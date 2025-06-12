import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthService>().registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
        // Navigation will be handled by AuthWrapper
      } on FirebaseAuthException catch (e) {
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
                          Icons.person_add_rounded,
                          size: 64,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Sign Up Text
                    Text(
                      'Sign Up',
                      style: AppTheme.displaySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Join the reading community',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing48),

                    // Name Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        style: AppTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          hintStyle: AppTheme.bodyMedium.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Container(
                            padding: AppTheme.paddingAll12,
                            child: Icon(
                              Icons.person_outline_rounded,
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
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '👤 Please enter your name';
                          }
                          if (value.length < 2) {
                            return '👤 Name must be at least 2 characters';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
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
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
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
                                  color: Theme.of(context).colorScheme.onSurface
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
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final error = context
                              .read<AuthService>()
                              .validatePassword(value);
                          return error != null ? '🔒 $error' : null;
                        },
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    // Confirm Password Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
                      ),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        style: AppTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
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
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              child: Container(
                                padding: AppTheme.paddingAll12,
                                child: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Theme.of(context).colorScheme.onSurface
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
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '🔒 Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return '🔒 Passwords do not match';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _register(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),
                    // Sign Up Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  'Sign Up',
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
                          padding: AppTheme.paddingH16.add(AppTheme.paddingV8),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                      text: 'Sign up with Google',
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Sign In Link
                    Container(
                      padding: AppTheme.paddingV16,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: AppTheme.bodyMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                                  (_isLoading || _isGoogleLoading)
                                      ? null
                                      : () => Navigator.pop(context),
                              child: Container(
                                padding: AppTheme.paddingH8.add(
                                  AppTheme.paddingV4,
                                ),
                                child: Text(
                                  'Sign In',
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
  }
}
