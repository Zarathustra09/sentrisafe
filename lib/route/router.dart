import 'package:flutter/material.dart';
import 'package:sentrisafe/pages/auth/registration_page.dart';
import 'screen_export.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onboardingScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OnboardingScreen(),
      );
    case loginScreenRoute:
      return MaterialPageRoute(
        builder: (context) => LoginPage(),
      );
    case registerScreenRoute:
      return MaterialPageRoute(
        builder: (context) => RegistrationPage(),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const OnboardingScreen(),
      );
  }
}