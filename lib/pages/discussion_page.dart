import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../constants.dart';

class DiscussionPage extends StatelessWidget {
  const DiscussionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopNavbar(),
      ),
      body: Container(
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
                      Icons.forum_outlined,
                      size: 48,
                      color: Constants.accent,
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Text(
                      'Community Discussion',
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'Join community discussions and forums',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Constants.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }
}