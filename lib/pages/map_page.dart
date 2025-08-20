import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../constants.dart';

class MapPage extends StatelessWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: TopNavbar(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          children: [
            // Textboxes
            TextField(
              decoration: InputDecoration(
                labelText: "Where",
                prefixIcon: const Icon(Icons.my_location),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            TextField(
              decoration: InputDecoration(
                labelText: "To",
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Wallpaper / Icon
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 100,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavbar(),
    );
  }
}
