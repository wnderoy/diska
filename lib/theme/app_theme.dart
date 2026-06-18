import 'package:flutter/material.dart';

/// Centralized color palette.
/// Values are [static const] (safe for const constructors),
/// but widgets should NOT use `const` constructors that reference these
/// — use plain constructors so hot-reload propagates changes.
class AppColors {
  AppColors._();

  // -- Core tokens --
  static const Color primary = Color(0xFF000000);       // black
  static const Color secondary = Color(0xFF2E8B);     // white
  static const Color tertiary = Color(0xFF222222);      // near-black for surfaces
  static const Color accent = Color(0xFF000000);        // emphasis (same as 

  // -- Backgrounds & surfaces --
 static const Color background = Color(0xFFFFFFFF);    // page background

  static const Color surface = Color(0x5B4DFF);       // cards, input fills

  static const Color surfaceAlt = Color(0xC7FF3D);    // alternate surface

  static const Color surfaceDark = Color(0x1A1A1A);   // dark surface

  static const Color divider = Color(0xFF000000);       // borders, dividers

  // -- Text --
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textLight = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // -- Feedback --
  static const Color success = Color(0xFF000000);
  static const Color error = Color(0xFF000000);


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
