import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system mode, toggle to opposite of current system setting
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    }
    notifyListeners();
  }

  // Helper methods to get colors based on current theme
  Color getUserMessageBg(BuildContext context) {
    return isDarkMode
        ? AppColors.darkUserMessageBg
        : AppColors.lightUserMessageBg;
  }

  Color getAiMessageBg(BuildContext context) {
    return isDarkMode ? AppColors.darkAiMessageBg : AppColors.lightAiMessageBg;
  }

  Color getUserMessageText(BuildContext context) {
    return isDarkMode
        ? AppColors.darkUserMessageText
        : AppColors.lightUserMessageText;
  }

  Color getAiMessageText(BuildContext context) {
    return isDarkMode
        ? AppColors.darkAiMessageText
        : AppColors.lightAiMessageText;
  }

  Color getTextPrimary(BuildContext context) {
    return isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  }

  Color getTextSecondary(BuildContext context) {
    return isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
  }

  Color getTextHint(BuildContext context) {
    return isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint;
  }

  Color getSurface(BuildContext context) {
    return isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
  }

  Color getBackground(BuildContext context) {
    return isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
  }
}
