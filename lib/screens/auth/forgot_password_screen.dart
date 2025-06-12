import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  void _showSuccessMessage(String message) {
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
                  Icons.check_circle_outline_rounded,
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
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: AppTheme.paddingAll16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthService>().resetPassword(
          _emailController.text.trim(),
        );
        if (!mounted) return;
        _showSuccessMessage(
          'Password reset email sent. Please check your inbox.',
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: AppTheme.paddingAll8,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
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
                          Icons.lock_reset_rounded,
                          size: 64,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    Text(
                      'Reset Password',
                      style: AppTheme.displaySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Enter your email address and we\'ll send you a secure link to reset your password.',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing48),
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
                          hintText: 'Enter your email address',
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
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          final error = context
                              .read<AuthService>()
                              .validateEmail(value);
                          return error != null ? '⚠️ $error' : null;
                        },
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _resetPassword(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing32),

                    // Reset Button
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
                        onPressed: _isLoading ? null : _resetPassword,
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
                                  'Send Reset Link',
                                  style: AppTheme.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),

                    // Back to Login
                    Container(
                      padding: AppTheme.paddingV16,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radius8),
                          onTap:
                              _isLoading ? null : () => Navigator.pop(context),
                          child: Container(
                            padding: AppTheme.paddingV8,
                            child: Text(
                              'Back to Sign In',
                              style: AppTheme.labelLarge.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
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
