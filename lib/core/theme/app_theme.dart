import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundBase,
      canvasColor: AppColors.backgroundBase,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandAccent,
        surface: AppColors.cardSurface,
        onSurface: AppColors.primaryText,
        error: AppColors.error,
        secondary: AppColors.brandAccentLight,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorderStroke, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorderStroke,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputSurface,
        hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.brandAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.cardBorderStroke),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandAccentLight,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.cardBorderStroke),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 30),
        headlineMedium: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 24),
        headlineSmall: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 20),
        titleLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: TextStyle(color: AppColors.primaryText, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.secondaryText, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.secondaryText, fontSize: 12),
        labelLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
