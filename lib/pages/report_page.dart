import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: TopNavbar(),
      ),
      body: Center(
        child: Text(
          'Report Page Placeholder',
          style: TextStyle(fontSize: 24, color: Colors.black54),
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }
}
