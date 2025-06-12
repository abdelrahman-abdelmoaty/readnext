import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Sign in with Google',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.grey700 : AppTheme.grey300).withValues(
              alpha: 0.3,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.grey800 : AppTheme.white,
          foregroundColor: isDark ? AppTheme.white : AppTheme.grey900,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: AppTheme.paddingV20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius16),
            side: BorderSide(
              color: isDark ? AppTheme.grey600 : AppTheme.grey300,
              width: 1.5,
            ),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppTheme.white : AppTheme.grey700,
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google logo
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4285F4), // Google Blue
                            Color(0xFFEA4335), // Google Red
                            Color(0xFFFBBC05), // Google Yellow
                            Color(0xFF34A853), // Google Green
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: AppTheme.titleLarge.copyWith(
                        color: isDark ? AppTheme.white : AppTheme.grey900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
