import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF6A1B9A); // Dark purple color

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: const Color(0xFF212121), // Darker text for better contrast
      primary: _primaryColor,
      primaryContainer: Color(0xFF9C4DCC), // Lighter purple for containers
      onPrimary: Colors.white,
      secondary: Color(0xFF9C27B0), // Accent color
      onSecondary: Colors.white,
      surfaceVariant: Color(0xFFF3E5F5), // Light purple background
      onSurfaceVariant: Color(
        0xFF4A148C,
      ), // Dark purple for text on light backgrounds
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          colorScheme.surface, // Changed from background to surface
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        secondarySelectedColor: colorScheme.primary,
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212), // Dark background
      onSurface: Colors.white, // White text on dark background
      primary: _primaryColor,
      primaryContainer: Color(0xFF9C4DCC), // Lighter purple for containers
      onPrimary: Colors.white,
      secondary: Color(0xFFCE93D8), // Lighter purple for accents
      onSecondary: Colors.black,
      surfaceVariant: Color(0xFF1E1E1E), // Slightly lighter than surface
      onSurfaceVariant: Color(
        0xFFD1C4E9,
      ), // Light purple for text on dark backgrounds
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          colorScheme.surface, // Use the main surface for scaffold background
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        secondarySelectedColor: colorScheme.primary,
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
