import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Privacy Policy for Word Game',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thank you for choosing to join our community at [Your Company Name]',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Information We Collect'),
            const SizedBox(height: 12),
            const Text(
              'We may collect limited information to improve your experience, including:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Personal Information: We do not collect personal information like your name, email address, or phone number unless you provide it directly (e.g., through support requests).'),
            _buildBulletPoint('Device Information: To improve performance, we may collect non-personal data such as device type, operating system, and app usage statistics.'),
            _buildBulletPoint('Game Data: We collect information related to your gameplay (like scores, levels achieved, and progress) to enhance your user experience.'),
            
            const SizedBox(height: 24),
            _buildSectionTitle('How We Use Your Information'),
            const SizedBox(height: 12),
            _buildBulletPoint('We use the collected information to:'),
            _buildBulletPoint('Improve the App and fix bugs'),
            _buildBulletPoint('Personalize your experience'),
            _buildBulletPoint('Monitor usage and trends to improve our service'),
            _buildBulletPoint('Provide customer support when needed'),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Sharing Your Information'),
            const SizedBox(height: 12),
            const Text(
              'We do NOT sell, rent, or trade your personal information to third parties. We may share limited non-personal data with:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Analytics services (like Google Analytics or Firebase) to help us understand usage patterns.'),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Data Security'),
            const SizedBox(height: 12),
            const Text(
              'We take reasonable measures to protect your information from unauthorized access, loss, misuse, or alteration. However, no method of transmission over the internet or mobile device is 100% secure.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Children\'s Privacy'),
            const SizedBox(height: 12),
            const Text(
              'Our App is intended for general audiences and does not knowingly collect information from children under 13. If we learn that we have collected personal information from a child without parental consent, we will delete it promptly.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Third-Party Links'),
            const SizedBox(height: 12),
            const Text(
              'Our App may contain links to third-party websites or services. We are not responsible for the privacy practices of those third parties.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Your Privacy Rights'),
            const SizedBox(height: 12),
            const Text(
              'Depending on your location, you may have right to access, correct, or delete your personal information. Contact us if you wish to exercise these rights.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Changes to This Policy'),
            const SizedBox(height: 12),
            const Text(
              'We may update this Privacy Policy from time to time. When we do, we will revise the "Effective Date" at the top. We encourage you to review this policy regularly.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 12),
            const Text(
              'If you have any questions about this Privacy Policy, please contact us at:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Email: [Your Contact Email]'),
            _buildBulletPoint('Address: [Your Company Address if needed]'),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 1.3,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}