import 'package:flutter/material.dart';

/// Privacy Policy screen displaying data collection and usage policies
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF1A2A44),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1A2A44),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00CED1).withOpacity(0.3),
                  const Color(0xFF006D77).withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6), // Purple
                        Color(0xFF06B6D4), // Cyan
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.privacy_tip,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your privacy is important to us. This policy explains how we collect, use, and protect your information.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Content
                _buildPrivacyCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            '1. Information We Collect',
            'We collect several types of information from and about users of our App:\n\n• Personal Information: Name, phone number, email address\n• Vehicle Information: Vehicle details, registration number, device ID\n• Location Data: GPS coordinates, routes, speed, and movement patterns\n• Usage Data: App interactions, features used, session duration\n• Device Information: Device type, operating system, unique identifiers',
          ),
          _buildSection(
            '2. How We Use Your Information',
            'We use the information we collect for various purposes:\n\n• Provide and maintain our GPS tracking services\n• Process transactions and send related information\n• Send technical notices, updates, and support messages\n• Respond to your comments, questions, and requests\n• Monitor and analyze trends, usage, and activities\n• Improve our services and develop new features\n• Ensure security and prevent fraud',
          ),
          _buildSection(
            '3. Location Data',
            'Our App collects precise location data to provide tracking services:\n\n• Real-time GPS coordinates of your vehicles\n• Historical location and route data\n• Geofencing and alert information\n• Speed and movement analytics\n\nLocation data is essential for our core services and is collected only when the app is in use or running in the background with your permission.',
          ),
          _buildSection(
            '4. Data Sharing and Disclosure',
            'We do not sell, trade, or otherwise transfer your personal information to third parties except:\n\n• With your explicit consent\n• To comply with legal obligations\n• To protect our rights and prevent fraud\n• With service providers who assist our operations\n• In case of business transfer or merger\n\nAll third-party service providers are contractually bound to protect your information.',
          ),
          _buildSection(
            '5. Data Security',
            'We implement appropriate security measures to protect your information:\n\n• Encryption of data in transit and at rest\n• Secure server infrastructure with access controls\n• Regular security audits and monitoring\n• Employee training on data protection\n• Multi-factor authentication for admin access\n\nHowever, no method of transmission over the Internet is 100% secure.',
          ),
          _buildSection(
            '6. Data Retention',
            'We retain your personal information for as long as necessary to:\n\n• Provide our services to you\n• Comply with legal obligations\n• Resolve disputes and enforce agreements\n• Meet regulatory requirements\n\nLocation data is typically retained for up to 2 years unless longer retention is required by law.',
          ),
          _buildSection(
            '7. Your Privacy Rights',
            'You have the following rights regarding your personal information:\n\n• Access: Request copies of your personal data\n• Correction: Request correction of inaccurate information\n• Deletion: Request deletion of your personal data\n• Portability: Request transfer of your data\n• Restriction: Request limitation of processing\n• Objection: Object to processing of your data',
          ),
          _buildSection(
            '8. Cookies and Tracking Technologies',
            'We use cookies and similar technologies to:\n\n• Remember your preferences and settings\n• Analyze app usage and performance\n• Provide personalized content and features\n• Improve user experience\n\nYou can control cookie preferences through your device settings.',
          ),
          _buildSection(
            '9. Children\'s Privacy',
            'Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we discover that a child under 13 has provided us with personal information, we will delete such information immediately.',
          ),
          _buildSection(
            '10. International Data Transfers',
            'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information during such transfers in accordance with applicable data protection laws.',
          ),
          _buildSection(
            '11. Changes to Privacy Policy',
            'We may update our Privacy Policy from time to time. We will notify you of any changes by:\n\n• Posting the new Privacy Policy on this page\n• Sending an email notification\n• Displaying a prominent notice in the app\n\nContinued use of our service after changes constitutes acceptance of the updated policy.',
          ),
          _buildSection(
            '12. Contact Us',
            'If you have any questions about this Privacy Policy or our data practices, please contact us:\n\nEmail: privacy@edisha.com\nPhone: +91-XXXXX-XXXXX\nAddress: [Company Address]\n\nData Protection Officer: dpo@edisha.com',
          ),

          const SizedBox(height: 32),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A44),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We are committed to protecting your privacy and ensuring the security of your personal information while providing the best possible service.',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1A2A44).withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2A44),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF1A2A44).withOpacity(0.8),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
