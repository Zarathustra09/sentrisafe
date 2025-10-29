import 'package:flutter/material.dart';
import '../constants.dart';

class TermsAndConditionsDialog extends StatelessWidget {
  const TermsAndConditionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Constants.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Terms and Conditions & Data Privacy Agreement',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Constants.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Constants.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      'Welcome to SentriSafe!',
                      'Before creating an account or using our services, please carefully read these Terms and Conditions and our Data Privacy Notice. By signing up, you agree to the following:',
                    ),
                    _buildSection(
                      context,
                      '1. Acceptance of Terms',
                      'By registering and using this application, you agree to comply with these Terms and Conditions. If you do not agree, please do not proceed with the registration.',
                    ),
                    _buildSection(
                      context,
                      '2. Purpose of the Application',
                      'This platform allows users to report incidents, crimes, or community concerns for the purpose of public safety and coordination with the proper authorities.',
                    ),
                    _buildSection(
                      context,
                      '3. User Responsibilities',
                      '• You agree to provide accurate and truthful information.\n'
                          '• You shall not submit false reports, offensive content, or data that may harm other users.\n'
                          '• Misuse of the platform may result in account suspension or legal action.',
                    ),
                    _buildSection(
                      context,
                      '4. Data Privacy and Protection',
                      'We value your privacy. All information you provide will be handled in accordance with the Data Privacy Act of 2012 (Republic Act No. 10173).',
                    ),
                    _buildSubSection(
                      context,
                      'a. Information We Collect',
                      '• Personal details (name, contact number, address, email)\n'
                          '• Report details (type of crime, location, description, evidence if any)\n'
                          '• Device and usage data (IP address, location data for mapping)',
                    ),
                    _buildSubSection(
                      context,
                      'b. Purpose of Data Collection',
                      'Your data will only be used for:\n\n'
                          '• Processing and verifying incident reports\n'
                          '• Coordinating with law enforcement and relevant agencies\n'
                          '• Improving the services of the platform\n'
                          '• Ensuring the security and accountability of reports',
                    ),
                    _buildSubSection(
                      context,
                      'c. Data Sharing',
                      'Your data may be shared with:\n\n'
                          '• Government agencies and law enforcement (for investigation)\n'
                          '• Authorized platform administrators (for verification)\n\n'
                          'We will never sell or share your personal data with third parties for marketing or unrelated purposes.',
                    ),
                    _buildSection(
                      context,
                      '5. Data Storage and Security',
                      'All user data is securely stored using encrypted databases. We employ technical and organizational measures to prevent unauthorized access, disclosure, or alteration.',
                    ),
                    _buildSection(
                      context,
                      '6. User Rights',
                      'Under the Data Privacy Act, you have the right to:\n\n'
                          '• Access your personal information\n'
                          '• Correct or update your data\n'
                          '• Withdraw consent or request data deletion (subject to legal obligations)\n\n'
                          'To exercise these rights, contact us at the support section of the app.',
                    ),
                    _buildSection(
                      context,
                      '7. Limitation of Liability',
                      'The app serves as a reporting platform only. It does not guarantee immediate police response or intervention. The developers and administrators are not liable for any damages resulting from misuse, misinformation, or external system issues.',
                    ),
                    _buildSection(
                      context,
                      '8. Consent',
                      'By signing up, you hereby consent to the collection, use, and processing of your personal information as described above.',
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: Constants.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Text(
                        '☑️ By clicking "I Agree" or creating an account, you confirm that:\n\n'
                        '• You have read and understood the Terms and Conditions and Data Privacy Policy.\n'
                        '• You voluntarily consent to the collection and use of your data.\n'
                        '• You are of legal age or have parental/guardian consent to use this platform.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Constants.textPrimary,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Constants.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Constants.textPrimary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppConstants.spacingM,
        left: AppConstants.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Constants.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Constants.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
