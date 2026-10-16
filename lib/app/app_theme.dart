import 'package:flutter/material.dart';

ThemeData companionTheme() {
  const colors = ColorScheme.dark(
    primary: Color(0xFF7DD3FC),
    onPrimary: Color(0xFF082F49),
    secondary: Color(0xFF67E8F9),
    onSecondary: Color(0xFF083344),
    surface: Color(0xFF0C121B),
    onSurface: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFFB7C4D6),
    surfaceContainerLow: Color(0xFF121C29),
    surfaceContainerHigh: Color(0xFF1E2C3D),
    outline: Color(0xFF66788E),
    outlineVariant: Color(0xFF2B3B4F),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF552322),
    onErrorContainer: Color(0xFFFFDAD6),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        height: 1.2,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.5,
        color: colors.onSurfaceVariant,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
