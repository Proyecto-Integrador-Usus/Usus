import 'package:flutter/material.dart';

abstract final class AppColors {
  static const mustard = Color(0xFFD4AF37);
  static const ivory = Color(0xFFF5F0E6);
  static const espresso = Color(0xFF3B2F2F);
  static const tan = Color(0xFFB08D57);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF81796F);
  static const border = Color(0xFFE8E0D3);
  static const canvas = Color(0xFFFCFAF6);
}

extension AppPalette on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  Color get canvas => Theme.of(this).scaffoldBackgroundColor;
  Color get brandPanel => colors.brightness == Brightness.dark
      ? const Color(0xFF292521)
      : AppColors.espresso;
  Color get goldPanel => colors.brightness == Brightness.dark
      ? const Color(0xFF393019)
      : AppColors.mustard;
}

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.mustard,
      brightness: brightness,
      primary: AppColors.mustard,
      onPrimary: AppColors.espresso,
      surfaceContainerLow: dark ? const Color(0xFF262421) : AppColors.ivory,
      outlineVariant: dark ? const Color(0xFF48443E) : AppColors.border,
      onSurfaceVariant: dark ? const Color(0xFFC2BAB0) : AppColors.muted,
      secondary: dark ? const Color(0xFFD2B286) : AppColors.tan,
      surface: dark ? const Color(0xFF1B1A18) : AppColors.white,
      onSurface: dark ? const Color(0xFFF4F0E9) : AppColors.espresso,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF101010)
          : AppColors.canvas,
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          color: scheme.onSurface,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: scheme.onSurface, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mustard, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? AppColors.mustard : AppColors.espresso,
          foregroundColor: dark ? AppColors.espresso : AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
