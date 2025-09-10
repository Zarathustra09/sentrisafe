import 'package:flutter/material.dart';
import 'services/shared_preferences.dart';
import 'services/auth/auth_service.dart';
import 'route/router.dart';
import 'route/route_constant.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/auth/login_page.dart';
import 'entry_point.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    // Check if user is already logged in
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      return const EntryPointPage();
    }

    // Check if it's first time opening the app
    final isNew = await SharedPrefService.getIsNew();
    if (isNew == null || isNew == true) {
      return const OnboardingScreen();
    } else {
      return LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialPage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MaterialApp(
          title: 'SentriSafe',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: snapshot.data,
          onGenerateRoute: generateRoute,
        );
      },
    );
  }
}