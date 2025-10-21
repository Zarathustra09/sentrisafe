import 'package:flutter/material.dart';
import 'package:sentrisafe/pages/map_page.dart';
import 'package:sentrisafe/pages/report_page.dart';
import 'widgets/top_navbar.dart';
import 'widgets/bottom_navbar.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'constants.dart';

class EntryPointPage extends StatefulWidget {
  const EntryPointPage({Key? key}) : super(key: key);

  @override
  State<EntryPointPage> createState() => _EntryPointPageState();
}

class _EntryPointPageState extends State<EntryPointPage> {
  int _selectedIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopNavbar(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(),
          MapPage(),
          ReportPage(),
          AnnouncementPage(isVisible: _selectedIndex == 3),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        initialIndex: _selectedIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}
