import 'package:flutter/material.dart';
import 'route/router.dart';
import 'route/route_constant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: onboardingScreenRoute,
      onGenerateRoute: generateRoute,
    );
  }
}
