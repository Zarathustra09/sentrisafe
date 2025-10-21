import 'package:flutter/material.dart';
import '../constants.dart';

class CommunityGuidelinesDialog extends StatelessWidget {
  final VoidCallback onAccept;

  const CommunityGuidelinesDialog({
    Key? key,
    required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Constants.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: Constants.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusM),
                  topRight: Radius.circular(AppConstants.radiusM),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gavel,
                    color: Constants.white,
                    size: 28,
                  ),
                  SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Text(
                      'SentriSafe Community Guidelines',
                      style: TextStyle(
                        color: Constants.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To maintain a safe, respectful, and trustworthy community, all users are expected to follow these guidelines when using the SentriSafe app. These rules ensure that shared information supports public safety and fosters responsible communication.',
                      style: TextStyle(
                        color: Constants.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingL),
                    _buildGuidelineSection(
                      '1. Report Responsibly',
                      [
                        'Only submit accurate and verified information about incidents.',
                        'Avoid spreading false, exaggerated, or misleading reports.',
                        'Include clear details such as time, location, and nature of the incident whenever possible.',
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingM),
                    _buildGuidelineSection(
                      '2. Respect Privacy',
                      [
                        'Do not post personal details, photos, or identifying information about victims, suspects, or witnesses.',
                        'Respect the confidentiality of ongoing investigations.',
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingM),
                    _buildGuidelineSection(
                      '3. Use Appropriate Language',
                      [
                        'Maintain professional and respectful communication at all times.',
                        'Avoid using offensive, discriminatory, or threatening language in reports or comments.',
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingM),
                    _buildGuidelineSection(
                      '4. Avoid Misuse',
                      [
                        'Do not use the app for spam, self-promotion, or irrelevant content.',
                        'Misuse of the reporting system for false claims may lead to temporary or permanent account suspension.',
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingM),
                    _buildGuidelineSection(
                      '5. Stay Safe',
                      [
                        'Do not intervene directly in dangerous situations; instead, contact local authorities.',
                        'Use the app to inform and stay aware, not to take enforcement actions.',
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingM),
                    _buildGuidelineSection(
                      '6. Support Community Trust',
                      [
                        'Engage positively with other users through constructive feedback.',
                        'Help maintain the platform as a safe and reliable source of community awareness.',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Constants.greyLight,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'By using SentriSafe, you agree to follow these community guidelines.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Constants.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingM),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primary,
                        foregroundColor: Constants.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusS,
                          ),
                        ),
                      ),
                      onPressed: onAccept,
                      child: Text(
                        'I Understand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Constants.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppConstants.spacingS),
        ...points.map((point) => Padding(
              padding: EdgeInsets.only(
                left: AppConstants.spacingM,
                bottom: AppConstants.spacingXS,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: Constants.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: Constants.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
