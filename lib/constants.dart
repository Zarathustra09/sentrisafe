// lib/constants.dart
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

class Constants {
  // Primary Colors
  static const Color primary = Color(0xFF00BCD4); // Teal/Cyan
  static const Color primaryDark = Color(0xFF00ACC1);
  static const Color primaryLight = Color(0xFF26C6DA);

  // Secondary Colors
  static const Color secondary = Color(0xFF1A1A1A); // Dark background
  static const Color secondaryDark = Color(0xFF0D0D0D);
  static const Color secondaryLight = Color(0xFF2D2D2D);

  // Accent Colors
  static const Color accent = Color(0xFF4FC3F7); // Light blue accent
  static const Color accentDark = Color(0xFF29B6F6);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF424242);

  // Background Colors
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF2D2D2D);
  static const Color surfaceLight = Color(0xFF424242);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textHint = Color(0xFF78909C);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF00BCD4),
    Color(0xFF00ACC1),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF0D0D0D),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF4FC3F7),
    Color(0xFF29B6F6),
  ];
}

class AppConstants {
  // App Information
  static const String appName = 'FreedomChat';
  static const String appVersion = '1.0.0';

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 800);
  static const Duration animationVerySlow = Duration(milliseconds: 1200);

  // Form Validation Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadious = 12.0;
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const String pasNotMatchErrorText = "passwords do not match";
}

// Form Validators
final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 digits long'),
]);

final emaildValidator = MultiValidator([
  RequiredValidator(errorText: 'Email is required'),
  EmailValidator(errorText: "Enter a valid email address"),
]);

const String baseUrl = 'http://192.168.18.78/api';
const String storageUrl = 'http://192.168.18.78/storage';
const String googleApiKey = 'AIzaSyDXaFeKPaKXgpFPp0IGlJuviW2RZCM9OtU';
