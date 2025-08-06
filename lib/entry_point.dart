import 'package:flutter/material.dart';
import 'widgets/top_navbar.dart';
import 'widgets/bottom_navbar.dart';

class EntryPointPage extends StatelessWidget {
  const EntryPointPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: TopNavbar(),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          height: 400,
          width: double.infinity,
          color: Colors.grey[300],
          child: const Center(
            child: Text(
              'Map Placeholder',
              style: TextStyle(fontSize: 24, color: Colors.black54),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }
}
