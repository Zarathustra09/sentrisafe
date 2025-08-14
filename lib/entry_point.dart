import 'package:flutter/material.dart';
import 'widgets/top_navbar.dart';
import 'widgets/bottom_navbar.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart'; // Add this import
import 'constants.dart';

class EntryPointPage extends StatefulWidget {
  const EntryPointPage({Key? key}) : super(key: key);

  @override
  State<EntryPointPage> createState() => _EntryPointPageState();
}

class _EntryPointPageState extends State<EntryPointPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    _buildMapPage(),
    _buildReportPage(),
    AnnouncementPage(), // Replace the discussion page with announcement page
  ];

  static Widget _buildMapPage() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingXL),
              decoration: BoxDecoration(
                color: Constants.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Constants.black.withOpacity(0.1),
                    blurRadius: AppConstants.elevationL,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: Constants.primary,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Interactive Map',
                    style: TextStyle(
                      color: Constants.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'Map functionality will be implemented here',
                    style: TextStyle(
                      color: Constants.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildReportPage() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingXL),
              decoration: BoxDecoration(
                color: Constants.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Constants.black.withOpacity(0.1),
                    blurRadius: AppConstants.elevationL,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.report_outlined,
                    size: 48,
                    color: Constants.warning,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Report Incidents',
                    style: TextStyle(
                      color: Constants.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    'Report safety incidents and concerns here',
                    style: TextStyle(
                      color: Constants.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        children: _pages,
      ),
      bottomNavigationBar: BottomNavbar(
        initialIndex: _selectedIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}