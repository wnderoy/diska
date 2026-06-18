import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);
  static const Color _grey = Color(0xFF888888);
  static const Color _lightGrey = Color(0xFFF0F0F0);

  static ThemeData get blackAndWhite {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _white,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: _black,
        onPrimary: _white,
        secondary: _black,
        onSecondary: _white,
        surface: _white,
        onSurface: _black,
        error: _black,
        onError: _white,
        outline: _black,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _white,
        foregroundColor: _black,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: _black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _white,
        selectedItemColor: _black,
        unselectedItemColor: _grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _black,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: _grey,
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _black,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: _black,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: _black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: _black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: _grey,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: _black,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: _black,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: _black,
        size: 24,
      ),

      cardTheme: CardThemeData(
        color: _white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _black, width: 1),
          borderRadius: BorderRadius.circular(0),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: _lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _black, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _black, width: 2),
        ),
        labelStyle: TextStyle(color: _black),
        hintStyle: TextStyle(color: _grey),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _white,
        selectedColor: _black,
        labelStyle: const TextStyle(color: _black),
        secondaryLabelStyle: const TextStyle(color: _white),
        side: const BorderSide(color: _black, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
      ),
    );
  }
}
