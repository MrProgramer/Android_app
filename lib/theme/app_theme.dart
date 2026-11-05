import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const List<String> persianFontFallback = [
    'Vazirmatn',
    'Shabnam',
    'Sahel',
    'Samim',
    'Noto Sans Arabic',
    'Tahoma',
    'Arial',
    'sans-serif',
  ];

  static TextTheme _buildTextTheme(Color mainColor, Color mutedColor) {
    return TextTheme(
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      headlineMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      titleLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      titleMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      bodyLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mainColor, height: 1.5, fontFamilyFallback: persianFontFallback),
      bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mainColor, height: 1.5, fontFamilyFallback: persianFontFallback),
      bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: mutedColor, height: 1.5, fontFamilyFallback: persianFontFallback),
      labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mainColor, height: 1.4, fontFamilyFallback: persianFontFallback),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: mutedColor, height: 1.4, fontFamilyFallback: persianFontFallback),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: _buildTextTheme(AppColors.textMainLight, AppColors.textMutedLight),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.blue,
        surface: AppColors.cardLight,
        onSurface: AppColors.textMainLight,
        error: AppColors.rose,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardLight,
        foregroundColor: AppColors.textMainLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textMainLight,
          fontFamilyFallback: persianFontFallback,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLight,
        selectedColor: AppColors.primarySurface,
        side: const BorderSide(color: AppColors.borderLight, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 11, fontFamilyFallback: persianFontFallback),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMutedLight, fontFamilyFallback: persianFontFallback),
        hintStyle: const TextStyle(color: AppColors.textMutedLight, fontSize: 12, fontFamilyFallback: persianFontFallback),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: _buildTextTheme(AppColors.textMainDark, AppColors.textMutedDark),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF134E4A),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFF60A5FA),
        surface: AppColors.cardDark,
        onSurface: AppColors.textMainDark,
        error: Color(0xFFFB7185),
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardDark,
        foregroundColor: AppColors.textMainDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textMainDark,
          fontFamilyFallback: persianFontFallback,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardDark,
        selectedColor: AppColors.primarySurfaceDark,
        side: const BorderSide(color: AppColors.borderDark, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 11, fontFamilyFallback: persianFontFallback),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDarkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMutedDark, fontFamilyFallback: persianFontFallback),
        hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 12, fontFamilyFallback: persianFontFallback),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
      ),
    );
  }
}
