import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Color(0xFF2A9D8F),
      secondary: Color(0xFF264653),
      surface: Colors.white,
      // Replaced deprecated background with surfaceContainer
      surfaceContainer: Color(0xFFF5F5F5),
      error: Color(0xFFE76F51),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF264653),
      // Replaced deprecated onBackground with onSurfaceVariant
      onSurfaceVariant: Color(0xFF264653),
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      // Using surfaceTintColor and shadowColor properties for Material 3
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      // backgroundColor is still valid but will be derived from colorScheme if not set
      backgroundColor: Color(0xFF2A9D8F),
      // foregroundColor is still valid but will be derived from colorScheme if not set
      foregroundColor: Colors.white,
      // Adding centerTitle for consistency
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      // In Material 3, FAB uses the container colors and surface tint color
      elevation: 2,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
      // For Material 3, we don't need to specify backgroundColor and foregroundColor
      // as they are automatically picked from the ColorScheme
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF2A9D8F),
      secondary: Color(0xFF264653),
      surface: Color(0xFF1E1E1E),
      surfaceTint: Color(0xFF264653),
      // Replaced deprecated background with surfaceContainer
      surfaceContainer: Color(0xFF121212),
      error: Color(0xFFE76F51),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      // Replaced deprecated onBackground with onSurfaceVariant
      onSurfaceVariant: Colors.white,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      // Using surfaceTintColor and shadowColor properties for Material 3
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      // backgroundColor is still valid but will be derived from colorScheme if not set
      backgroundColor: Color(0xFF1E1E1E),
      // foregroundColor is still valid but will be derived from colorScheme if not set
      foregroundColor: Colors.white,
      // Adding centerTitle for consistency
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      // In Material 3, FAB uses the container colors and surface tint color
      elevation: 2,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
      // For Material 3, we don't need to specify backgroundColor and foregroundColor
      // as they are automatically picked from the ColorScheme
    ),
  );
}
