import 'package:flutter/material.dart';
      import '../constants.dart';

      class TopNavbar extends StatelessWidget {
        const TopNavbar({Key? key}) : super(key: key);

        @override
        Widget build(BuildContext context) {
          return AppBar(
            backgroundColor: Constants.surface,
            elevation: AppConstants.elevationM,
            automaticallyImplyLeading: false,
            title: TextField(
              style: const TextStyle(color: Constants.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Constants.textHint),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: Constants.textSecondary,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.account_circle,
                  color: Constants.textSecondary,
                ),
                onPressed: () {
                  // Handle profile icon tap
                },
              ),
            ],
          );
        }
      }