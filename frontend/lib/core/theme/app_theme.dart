import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color primaryContainerColor = Color(0xFF1B5E20);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color tertiaryColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color onSurfaceColor = Color(0xFF191C1D);
  static const Color outlineColor = Color(0xFF707A6C);
  static const Color errorColor = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryContainerColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        error: errorColor,
        onSurface: onSurfaceColor,
        outline: outlineColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w600, letterSpacing: -0.25),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 1,
      ),
      buttonTheme: const ButtonThemeData(
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
      ),
    );
  }
}
