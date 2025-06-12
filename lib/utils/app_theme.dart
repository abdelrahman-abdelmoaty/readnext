import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Single-Shade Color System - Robust and Unified Design
  // Base Warm Teal Palette - All colors derived from single hue for consistency
  static const Color primary = Color(0xFF14B8A6); // Teal-500 - Main brand
  static const Color primaryDark = Color(0xFF0D9488); // Teal-600 - Dark variant
  static const Color primaryLight = Color(
    0xFF2DD4BF,
  ); // Teal-400 - Light variant
  static const Color primaryVeryLight = Color(
    0xFF7DD3FC,
  ); // Teal-300 - Very light
  static const Color primaryUltraLight = Color(
    0xFFB2F5EA,
  ); // Teal-200 - Ultra light backgrounds
  static const Color primaryFaint = Color(
    0xFFF0FDFA,
  ); // Teal-50 - Faint backgrounds

  // Secondary uses darker shades of the same teal
  static const Color secondary = Color(
    0xFF0F766E,
  ); // Teal-700 - Secondary actions
  static const Color secondaryLight = Color(
    0xFF0D9488,
  ); // Teal-600 - Light secondary

  // Accent uses lighter shades for highlights
  static const Color accent = Color(
    0xFF2DD4BF,
  ); // Teal-400 - Accents and highlights
  static const Color success = Color(
    0xFF059669,
  ); // Emerald-600 - Success states
  static const Color warning = Color(0xFFF59E0B); // Amber-500 - Warning states
  static const Color error = Color(0xFFDC2626); // Red-600 - Error states

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  static const Color black = Color(0xFF000000);

  // Text Styles
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.025,
    height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.025,
    height: 1.1,
  );

  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.025,
    height: 1.2,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.025,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.025,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.025,
    height: 1.4,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: grey50,

      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: white,
        secondary: secondary,
        onSecondary: white,
        surface: white,
        onSurface: grey900,
        error: error,
        onError: white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: grey900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headlineMedium.copyWith(color: grey900),
        iconTheme: const IconThemeData(color: grey700),
        surfaceTintColor: Colors.transparent,
      ),

      textTheme: TextTheme(
        displayLarge: displayLarge.copyWith(color: grey900),
        displayMedium: displayMedium.copyWith(color: grey900),
        displaySmall: displaySmall.copyWith(color: grey900),
        headlineLarge: headlineLarge.copyWith(color: grey900),
        headlineMedium: headlineMedium.copyWith(color: grey900),
        headlineSmall: headlineSmall.copyWith(color: grey900),
        titleLarge: titleLarge.copyWith(color: grey900),
        titleMedium: titleMedium.copyWith(color: grey700),
        titleSmall: titleSmall.copyWith(color: grey600),
        bodyLarge: bodyLarge.copyWith(color: grey700),
        bodyMedium: bodyMedium.copyWith(color: grey600),
        bodySmall: bodySmall.copyWith(color: grey500),
        labelLarge: labelLarge.copyWith(color: grey700),
        labelMedium: labelMedium.copyWith(color: grey600),
        labelSmall: labelSmall.copyWith(color: grey500),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: paddingButton,
          textStyle: titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: paddingButton,
          textStyle: titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: paddingH16.add(paddingV12),
          textStyle: titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardTheme(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
        margin: marginCard,
        shadowColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: paddingInput,
        hintStyle: bodyMedium.copyWith(color: grey400),
        labelStyle: bodyMedium.copyWith(color: grey600),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: labelMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: labelMedium,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryUltraLight,
        selectedColor: primary,
        labelStyle: labelMedium.copyWith(color: secondary),
        padding: paddingChip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: paddingH16.add(paddingV8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        titleTextStyle: titleLarge.copyWith(color: grey900),
        subtitleTextStyle: bodyMedium.copyWith(color: grey600),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: grey900,

      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        onPrimary: grey900,
        secondary: secondaryLight,
        onSecondary: grey900,
        surface: grey800,
        onSurface: white,
        error: error,
        onError: white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: grey800,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headlineMedium.copyWith(color: white),
        iconTheme: const IconThemeData(color: grey300),
        surfaceTintColor: Colors.transparent,
      ),

      textTheme: TextTheme(
        displayLarge: displayLarge.copyWith(color: white),
        displayMedium: displayMedium.copyWith(color: white),
        displaySmall: displaySmall.copyWith(color: white),
        headlineLarge: headlineLarge.copyWith(color: white),
        headlineMedium: headlineMedium.copyWith(color: white),
        headlineSmall: headlineSmall.copyWith(color: white),
        titleLarge: titleLarge.copyWith(color: white),
        titleMedium: titleMedium.copyWith(color: grey300),
        titleSmall: titleSmall.copyWith(color: grey400),
        bodyLarge: bodyLarge.copyWith(color: grey300),
        bodyMedium: bodyMedium.copyWith(color: grey400),
        bodySmall: bodySmall.copyWith(color: grey500),
        labelLarge: labelLarge.copyWith(color: grey300),
        labelMedium: labelMedium.copyWith(color: grey400),
        labelSmall: labelSmall.copyWith(color: grey500),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: grey900,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: paddingButton,
          textStyle: titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
          padding: paddingButton,
          textStyle: titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius8),
          ),
          padding: paddingH16.add(paddingV12),
          textStyle: titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardTheme(
        color: grey800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
        margin: marginCard,
        shadowColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey700,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: grey600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: grey600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: paddingInput,
        hintStyle: bodyMedium.copyWith(color: grey500),
        labelStyle: bodyMedium.copyWith(color: grey400),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: grey800,
        selectedItemColor: primaryLight,
        unselectedItemColor: grey500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: labelMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: labelMedium,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryDark,
        selectedColor: primaryLight,
        labelStyle: labelMedium.copyWith(color: primaryUltraLight),
        padding: paddingChip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius20),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: grey900,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: paddingH16.add(paddingV8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        titleTextStyle: titleLarge.copyWith(color: white),
        subtitleTextStyle: bodyMedium.copyWith(color: grey400),
      ),
    );
  }

  // Spacing Constants
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing18 = 18.0;
  static const double spacing20 = 20.0;
  static const double spacing22 = 22.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  // Border Radius Constants - Following 4px increments for consistency
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius18 = 18.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;

  // Standardized EdgeInsets
  static const EdgeInsets paddingAll2 = EdgeInsets.all(spacing2);
  static const EdgeInsets paddingAll4 = EdgeInsets.all(spacing4);
  static const EdgeInsets paddingAll6 = EdgeInsets.all(spacing6);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(spacing12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(spacing20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(spacing24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(spacing32);

  static const EdgeInsets paddingH4 = EdgeInsets.symmetric(
    horizontal: spacing4,
  );
  static const EdgeInsets paddingH8 = EdgeInsets.symmetric(
    horizontal: spacing8,
  );
  static const EdgeInsets paddingH12 = EdgeInsets.symmetric(
    horizontal: spacing12,
  );
  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(
    horizontal: spacing16,
  );
  static const EdgeInsets paddingH20 = EdgeInsets.symmetric(
    horizontal: spacing20,
  );
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(
    horizontal: spacing24,
  );

  static const EdgeInsets paddingV4 = EdgeInsets.symmetric(vertical: spacing4);
  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: spacing8);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(
    vertical: spacing12,
  );
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(
    vertical: spacing16,
  );
  static const EdgeInsets paddingV20 = EdgeInsets.symmetric(
    vertical: spacing20,
  );

  // Common EdgeInsets combinations
  static const EdgeInsets paddingCard = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: spacing24,
    vertical: spacing16,
  );
  static const EdgeInsets paddingChip = EdgeInsets.symmetric(
    horizontal: spacing12,
    vertical: spacing8,
  );
  static const EdgeInsets paddingInput = EdgeInsets.all(spacing16);

  // Standardized Margins
  static const EdgeInsets marginAll4 = EdgeInsets.all(spacing4);
  static const EdgeInsets marginAll8 = EdgeInsets.all(spacing8);
  static const EdgeInsets marginAll12 = EdgeInsets.all(spacing12);
  static const EdgeInsets marginAll16 = EdgeInsets.all(spacing16);
  static const EdgeInsets marginAll20 = EdgeInsets.all(spacing20);
  static const EdgeInsets marginAll24 = EdgeInsets.all(spacing24);

  static const EdgeInsets marginScreen = EdgeInsets.fromLTRB(
    spacing16,
    spacing16,
    spacing16,
    spacing16,
  );
  static const EdgeInsets marginCard = EdgeInsets.all(spacing8);
  static const EdgeInsets marginBottomNav = EdgeInsets.fromLTRB(
    spacing48,
    0,
    spacing48,
    spacing16,
  );

  // Standardized Elevation System
  static List<BoxShadow> elevation0 = []; // No shadow

  static List<BoxShadow> elevation1(bool isDark) => [
    BoxShadow(
      color: (isDark ? Colors.black : grey900).withValues(alpha: 0.06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> elevation2(bool isDark) => [
    BoxShadow(
      color: (isDark ? Colors.black : grey900).withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevation3(bool isDark) => [
    BoxShadow(
      color: (isDark ? Colors.black : grey900).withValues(alpha: 0.10),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevation4(bool isDark) => [
    BoxShadow(
      color: (isDark ? Colors.black : grey900).withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // Legacy shadow styles (deprecated - use elevation system above)
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: grey900.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: grey900.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get largeShadow => [
    BoxShadow(
      color: grey900.withValues(alpha: 0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
