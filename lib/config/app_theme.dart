import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF22B14C);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: Colors.black,
      primary: _primaryColor,
      onPrimary: Colors.white,
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
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
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
      surface: const Color(
        0xFF121212,
      ), // This will be the main background surface
      onSurface: Colors.white, // This will be the main onSurface
      primary: _primaryColor,
      onPrimary: Colors.white,
      // The following surface and onSurface are for components, and are correctly placed.
      // No need to change them.
      // surface: const Color(0xFF1E1E1E),
      // onSurface: Colors.white,
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
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
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
