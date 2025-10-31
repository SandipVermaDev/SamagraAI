import 'package:flutter/material.dart';

class AppColors {
  // Base palette colors
  static const Color deepPurple = Color(0xFF1B0E20);
  static const Color darkPurple = Color(0xFF44334A);
  static const Color mediumPurple = Color(0xFF795690);
  static const Color brightPurple = Color(0xFF9570C6);
  static const Color lightPurple = Color(0xFFD1C0EC);
  static const Color warmPurple = Color(0xFFC4ADDD);
  static const Color softPink = Color(0xFFDB99C7);
  static const Color lavenderBg = Color(0xFFE1D3E8);
  static const Color darkReadableText = Color(0xFF391B49);
  static const Color mutedGray = Color(0xFF484149);

  // Light theme colors
  static const Color lightBackground = lavenderBg;
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = darkReadableText;
  static const Color lightTextSecondary = mutedGray;
  static const Color lightTextHint = mediumPurple;

  // Dark theme colors
  static const Color darkBackground = deepPurple;
  static const Color darkSurface = darkPurple;
  static const Color darkTextPrimary = lightPurple;
  static const Color darkTextSecondary = warmPurple;
  static const Color darkTextHint = brightPurple;

  // Chat bubble colors
  static const Color lightUserMessageBg = Color(0xFFC29CE4);
  static const Color lightAiMessageBg = lightPurple;
  static const Color lightUserMessageText = Colors.white;
  static const Color lightAiMessageText = darkReadableText;

  static const Color darkUserMessageBg = Color(0xFF4B2C61);
  static const Color darkAiMessageBg = mediumPurple;
  static const Color darkUserMessageText = Colors.white;
  static const Color darkAiMessageText = Colors.white;

  // Document banner colors
  static const Color lightDocumentBanner = Color(0xFFE8F5E8);
  static const Color lightDocumentBannerText = Color(0xFF2E7D32);
  static const Color darkDocumentBanner = Color(0xFF2A3A2A);
  static const Color darkDocumentBannerText = Color(0xFF81C784);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = mediumPurple;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.mediumPurple,
        brightness: Brightness.light,
        primary: AppColors.mediumPurple,
        onPrimary: Colors.white,
        secondary: AppColors.softPink,
        surface: AppColors.lightSurface,
        onSurface: AppColors.mutedGray,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brightPurple,
        brightness: Brightness.dark,
        primary: AppColors.brightPurple,
        onPrimary: AppColors.deepPurple,
        secondary: AppColors.softPink,
        surface: AppColors.darkSurface,
        onSurface: AppColors.warmPurple,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.darkPurple,
        filled: true,
      ),
    );
  }
}
