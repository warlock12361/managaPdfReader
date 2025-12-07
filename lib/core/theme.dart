import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primaryLight = Color(0xFF1E1E1E); // Very dark user-requested "Ultra-Rich" usually implies dark or high contrast
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _backgroundLight = Color(0xFFF5F5F7); // Paper-like

  static const Color _primaryDark = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF1C1C1E);
  static const Color _backgroundDark = Color(0xFF050505); // Deep Rich Black
  
  static const Color accentColor = Color(0xFFE67E22); // Elegant Orange/Leather color for PDF feel
  
  static TextTheme _buildTextTheme(ThemeData base) {
    return base.textTheme.copyWith(
      displayLarge: GoogleFonts.playfairDisplay( // Serif for elegance
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter( // Sans-serif for UI
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(),
      bodyMedium: GoogleFonts.merriweather( // Serif for reading content preview
         height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: _backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: _primaryLight,
        secondary: accentColor,
        surface: _surfaceLight,
        background: _backgroundLight, 
        onBackground: Colors.black,
      ),
      textTheme: _buildTextTheme(base),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: _backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryDark,
        secondary: accentColor,
        surface: _surfaceDark,
        background: _backgroundDark,
         onBackground: Colors.white,
      ),
      textTheme: _buildTextTheme(base).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
         titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
