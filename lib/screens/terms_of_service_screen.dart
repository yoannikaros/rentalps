import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Terms of Service',
              'Last updated: ${DateTime.now().year}',
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Acceptance of Terms',
              'By downloading, installing, or using the PS RENTX PRO application ("the App"), '
                  'you agree to be bound by these Terms of Service ("Terms"). '
                  'If you do not agree to these Terms, please do not use the App.',
            ),
            _buildSection(
              'Description of Service',
              'PS RENTX PRO is a mobile application designed for managing video game console rentals. '
                  'The app allows users to:\n\n'
                  '• Track console rentals and transactions\n'
                  '• Generate rental reports\n'
                  '• Print receipts using Bluetooth printers\n'
                  '• Manage console inventory\n'
                  '• Calculate rental costs and durations',
            ),
            _buildSection(
              'User Responsibilities',
              'As a user of the PS RENTX PRO app, you agree to:\n\n'
                  '• Use the app for lawful purposes only\n'
                  '• Maintain accurate rental records\n'
                  '• Ensure proper handling of rented equipment\n'
                  '• Backup your data regularly\n'
                  '• Report any bugs or issues to improve the app',
            ),
            _buildSection(
              'Data and Privacy',
              '• All rental data is stored locally on your device\n'
                  '• You are responsible for backing up your important data\n'
                  '• The app developers do not have access to your rental data\n'
                  '• Please review our Privacy Policy for more information',
            ),
            _buildSection(
              'Bluetooth and Printer Integration',
              'The app uses Bluetooth connectivity to:\n\n'
                  '• Connect to compatible Bluetooth printers\n'
                  '• Print rental receipts and reports\n'
                  '• You are responsible for ensuring printer compatibility\n'
                  '• The app is not responsible for printer hardware issues',
            ),
            _buildSection(
              'Limitation of Liability',
              'The PS RENTX PRO app is provided "as is" without warranties of any kind. '
                  'In no event shall the app developers be liable for:\n\n'
                  '• Any indirect, incidental, or consequential damages\n'
                  '• Loss of data or business interruption\n'
                  '• Hardware compatibility issues\n'
                  '• User errors or data entry mistakes\n'
                  '• Damages exceeding the amount paid for the app (if any)',
            ),
            _buildSection(
              'App Updates and Support',
              '• We may release updates to improve functionality\n'
                  '• Some features may change over time\n'
                  '• Continued use of the app indicates acceptance of updates\n'
                  '• Technical support is provided through app updates and documentation',
            ),
            _buildSection(
              'Termination',
              'We reserve the right to terminate or suspend access to the app immediately, '
                  'without prior notice or liability, for any reason whatsoever, '
                  'including without limitation if you breach the Terms.',
            ),
            _buildSection(
              'Governing Law',
              'These Terms shall be governed by and construed in accordance with '
                  'the laws of the jurisdiction in which the app is operated, '
                  'without regard to its conflict of law provisions.',
            ),
            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify these Terms at any time. '
                  'If we make material changes, we will notify you through the app '
                  'or by other means. Your continued use of the app after such changes '
                  'constitutes acceptance of the new Terms.',
            ),
            _buildSection(
              'Contact Information',
              'If you have any questions about these Terms of Service, please contact us:\n\n'
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
