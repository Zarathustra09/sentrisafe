import 'package:flutter/material.dart';
import '../constants.dart';
import '../profile.dart';

class TopNavbar extends StatelessWidget {
  const TopNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Constants.surface,
      elevation: AppConstants.elevationM,
      automaticallyImplyLeading: false,
      title: Text(
        'SentriSafe',
        style: TextStyle(
          color: Constants.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Constants.textSecondary),
          onPressed: () {
            // Handle search functionality
          },
        ),
        IconButton(
          icon: Icon(Icons.account_circle, color: Constants.textSecondary),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => ProfilePage()));
          },
        ),
      ],
    );
  }
}
