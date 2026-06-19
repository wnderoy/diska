import 'package:flutter/material.dart';

/// Centralized color palette.
/// Values are [static const] (safe for const constructors),
/// but widgets should NOT use `const` constructors that reference these
/// — use plain constructors so hot-reload propagates changes.
class AppColors {
  AppColors._();

  // -- Core tokens --
  static const Color primary = Color(0xFF0E0E10);
  static const Color secondary = Color(0xFFE8E8E8);
  static const Color tertiary = Color(0xFF2A2A2E);
  static const Color accent = Color(0xFF0E0E10);

  // -- Palette accents --
  static const Color purple = Color(0xFF5B4DFF);
  static const Color lime = Color(0xFFC7FF3D);
  static const Color pink = Color(0xFFFF2E8B);

  /// Returns one of the 3 accent colors cycling by index.
  static Color accentByIndex(int i) {
    const accents = [purple, lime, pink];
    return accents[i % accents.length];
  }

  // -- Backgrounds & surfaces --
  static const Color background = Color(0xFFE8E8E8);
  static const Color surface = Color(0xFFD4D4D4);
  static const Color surfaceAlt = Color(0xFFC8C8C8);
  static const Color surfaceDark = Color(0xFF1A1A1E);
  static const Color divider = Color(0xFF0E0E10);

  // -- Text --
  static const Color textPrimary = Color(0xFF0E0E10);
  static const Color textSecondary = Color(0xFF6A6A6E);
  static const Color textLight = Color(0xFF9A9A9E);
  static const Color textOnPrimary = Color(0xFFE8E8E8);
  static const Color textOnDark = Color(0xFFE8E8E8);

  // -- Feedback --
  static const Color success = Color(0xFF0E0E10);
  static const Color error = Color(0xFFFF2E8B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get blackAndWhite {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.primary,
        onSecondary: AppColors.textOnPrimary,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        outline: AppColors.divider,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),

      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.divider, width: 1),
          borderRadius: BorderRadius.circular(0),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.divider, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.textPrimary),
        hintStyle: TextStyle(color: AppColors.textSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: TextStyle(color: AppColors.textOnPrimary),
        side: BorderSide(color: AppColors.divider, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
    );
  }
}
