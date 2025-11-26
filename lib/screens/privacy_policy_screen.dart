import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Privacy Policy',
              'Last updated: ${DateTime.now().year}',
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Information We Collect',
              'Our PS RENTX PRO application may collect the following information:\n\n'
                  '• Console rental data (console type, rental time, duration)\n'
                  '• Transaction information (payment amount, rental periods)\n'
                  '• Device information for Bluetooth connectivity\n'
                  '• Usage analytics and app performance data\n'
                  '• Local storage data on your device\n\n'
                  'All data is stored locally on your device and is not transmitted to external servers.',
            ),
            _buildSection(
              'How We Use Your Information',
              'We use the collected information to:\n\n'
                  '• Manage console rentals and transactions\n'
                  '• Generate rental reports and summaries\n'
                  '• Connect to Bluetooth printers for receipts\n'
                  '• Improve app functionality and user experience\n'
                  '• Provide customer support',
            ),
            _buildSection(
              'Data Storage and Security',
              '• All rental data is stored locally on your device\n'
                  '• We do not transmit personal data to external servers\n'
                  '• Bluetooth connections are secured using standard Android security protocols\n'
                  '• You can export or delete your data at any time through the app settings',
            ),
            _buildSection(
              'Third-Party Services',
              'Our app uses the following third-party services:\n\n'
                  '• Bluetooth connectivity for printer integration\n'
                  '• Local database storage (SQLite)\n'
                  '• Android system permissions for device functionality',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
                  '• Access your rental data at any time\n'
                  '• Export your data in various formats\n'
                  '• Delete your data from the app\n'
                  '• Request a copy of your information\n'
                  '• Control app permissions through Android settings',
            ),
            _buildSection(
              'Children Privacy',
              'This application is not directed to children under 13 years of age. '
                  'We do not knowingly collect personally identifiable information from children under 13.',
            ),
            _buildSection(
              'Changes to This Policy',
              'We may update our Privacy Policy from time to time. '
                  'We will notify you of any changes by posting the new Privacy Policy in this application.',
            ),
            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us:\n\n'
                  '• Application: PS RENTX PRO\n'
                  '• Platform: Android',
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to App'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 16),
      ],
    );
  }
}
