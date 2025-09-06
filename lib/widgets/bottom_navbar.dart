import 'package:flutter/material.dart';
import '../constants.dart';

class BottomNavbar extends StatefulWidget {
  final int? initialIndex;
  final Function(int)? onTabChanged;

  const BottomNavbar({Key? key, this.initialIndex, this.onTabChanged})
    : super(key: key);

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
  }

  @override
  void didUpdateWidget(BottomNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex && widget.initialIndex != null) {
      setState(() {
        _selectedIndex = widget.initialIndex!;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Constants.surface,
      selectedItemColor: Constants.primary,
      unselectedItemColor: Constants.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: AppConstants.elevationM,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_outlined),
          activeIcon: Icon(Icons.report),
          label: 'Report',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.announcement_outlined),
          activeIcon: Icon(Icons.announcement),
          label: 'Announcements',
        ),
      ],
    );
  }
}