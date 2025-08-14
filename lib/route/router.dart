import 'package:flutter/material.dart';
import 'package:sentrisafe/pages/auth/registration_page.dart';
import 'screen_export.dart';
import '../entry_point.dart';
import '../pages/map_page.dart';
import '../pages/report_page.dart';
import '../pages/announcement_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onboardingScreenRoute:
      return MaterialPageRoute(builder: (context) => const OnboardingScreen());
    case loginScreenRoute:
      return MaterialPageRoute(builder: (context) => LoginPage());
    case registerScreenRoute:
      return MaterialPageRoute(builder: (context) => RegistrationPage());
    case homeScreenRoute:
      return MaterialPageRoute(builder: (context) => const EntryPointPage());
    case mapScreenRoute:
      return MaterialPageRoute(builder: (context) => const MapPage());
    case reportScreenRoute:
      return MaterialPageRoute(builder: (context) => const ReportPage());
    case discussionScreenRoute:
      return MaterialPageRoute(builder: (context) => const AnnouncementPage());
    default:
      return MaterialPageRoute(builder: (context) => const OnboardingScreen());
  }
}
