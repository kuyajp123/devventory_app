import 'package:flutter/material.dart';
import 'package:devventory_app/shared/presentation/companion_style.dart';

ThemeData companionTheme() {
  const colors = ColorScheme.dark(
    primary: CompanionStyle.accent,
    onPrimary: Color(0xFF082F49),
    secondary: Color(0xFF67E8F9),
    onSecondary: Color(0xFF083344),
    surface: CompanionStyle.background,
    onSurface: Color(0xFFF0F5FC),
    onSurfaceVariant: Color(0xFFB7C4D6),
    surfaceContainerLowest: CompanionStyle.inset,
    surfaceContainerLow: CompanionStyle.surface,
    surfaceContainer: CompanionStyle.surface,
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
    fontFamily: 'Inter',
  );
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(CompanionStyle.controlRadius),
  );
  OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.2,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: colors.onSurfaceVariant,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.5,
        color: colors.onSurfaceVariant,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      labelStyle: TextStyle(color: colors.onSurfaceVariant),
      hintStyle: TextStyle(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: colors.onSurfaceVariant,
      suffixIconColor: colors.onSurfaceVariant,
      border: fieldBorder(colors.outlineVariant),
      enabledBorder: fieldBorder(colors.outline),
      disabledBorder: fieldBorder(colors.outlineVariant),
      focusedBorder: fieldBorder(colors.primary, 2),
      errorBorder: fieldBorder(colors.error),
      focusedErrorBorder: fieldBorder(colors.error, 2),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        shape: controlShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 56),
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: colors.outline),
        shape: controlShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant, space: 1),
    cardTheme: CardThemeData(
      color: colors.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(CompanionStyle.cardRadius),
      ),
    ),
  );
}
