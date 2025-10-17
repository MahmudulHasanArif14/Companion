import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==================== EXISTING COLORS FROM YOUR CODE ====================
  static const Color primaryBlue = Color(0xFF3267E3);
  static const Color secondaryOrange = Color(0xFFFFB93A);
  static const Color accentCyan = Color(0xFF4CAF50);
  static const Color darkPurple = Color(0xFF2E004C);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF178327);

  // ==================== LIGHT THEME ====================
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightPrimary = Color(0xFF3267E3);
  static const Color lightSecondary = Color(0xFFFFB93A);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightButtonPrimary = Color(0xFF3267E3);
  static const Color lightButtonSecondary = Color(0xFFFFB93A);
  static const Color lightButtonText = Color(0xFFFFFFFF);

  // ==================== DARK THEME ====================
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xA6242F3E);
  static const Color darkPrimary = Color(0xFF448AFF); // Lighter blue for dark mode
  static const Color darkSecondary = Color(0xFFFFB74D); // Lighter orange for dark mode
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkButtonPrimary = Color(0xFF448AFF);
  static const Color darkButtonSecondary = Color(0xFFFFB74D);
  static const Color darkButtonText = Color(0xFF000000);

  // ==================== DYNAMIC GETTERS ====================
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color primaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimary
        : lightPrimary;
  }

  static Color secondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondary
        : lightSecondary;
  }

  static Color textPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color buttonPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkButtonPrimary
        : lightButtonPrimary;
  }

  static Color buttonSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkButtonSecondary
        : lightButtonSecondary;
  }

  static Color buttonTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkButtonText
        : lightButtonText;
  }

  // ==================== SPECIFIC COMPONENT COLORS ====================
  static Color getAppBarColor(BuildContext context) {
    return primaryColor(context);
  }

  static Color getScaffoldBackground(BuildContext context) {
    return backgroundColor(context);
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  // ==================== SEMANTIC COLORS ====================
  static Color getSuccessColor(BuildContext context) {
    return const Color(0xFF4CAF50);
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFCF6679)
        : const Color(0xFFD32F2F);
  }

  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFFFB93A);
  }


  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFD0FAFF)
        : const Color(0xFF673AB7);
  }
}