import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget {
  const TopNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.account_circle, color: Colors.grey[700]),
          onPressed: () {
            // Handle profile icon tap
          },
        ),
      ],
    );
  }
}
