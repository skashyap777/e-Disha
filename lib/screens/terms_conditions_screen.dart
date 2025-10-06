import 'package:flutter/material.dart';

/// Terms and Conditions screen displaying app policies and usage terms
class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Terms & Conditions',
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
                        Color(0xFF006D77),
                        Color(0xFF00CED1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF006D77).withOpacity(0.3),
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
                              Icons.description,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Terms & Conditions',
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
                        'Please read these terms and conditions carefully before using the e-Disha application.',
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

                // Terms Content
                _buildTermsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCard() {
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
            '1. Acceptance of Terms',
            'By accessing and using the e-Disha application ("App"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
          ),
          _buildSection(
            '2. Use License',
            'Permission is granted to temporarily download one copy of e-Disha per device for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to reverse engineer any software contained in the App\n• Remove any copyright or other proprietary notations',
          ),
          _buildSection(
            '3. Privacy Policy',
            'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our service. By using our service, you agree to the collection and use of information in accordance with our Privacy Policy.',
          ),
          _buildSection(
            '4. User Account',
            'When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities that occur under your account.',
          ),
          _buildSection(
            '5. Vehicle Tracking Services',
            'e-Disha provides GPS tracking and fleet management services. You understand that:\n\n• Location data accuracy depends on GPS signal availability\n• Service may be temporarily unavailable due to technical issues\n• You are responsible for ensuring proper device installation\n• Data transmission requires active mobile/internet connectivity',
          ),
          _buildSection(
            '6. Data Collection and Usage',
            'We collect and process the following types of data:\n\n• Vehicle location and movement data\n• User account information\n• Device and usage statistics\n• Communication logs\n\nThis data is used to provide tracking services, improve our application, and ensure security.',
          ),
          _buildSection(
            '7. Service Limitations',
            'You acknowledge that the service is provided "as is" and that we do not guarantee:\n\n• Continuous, uninterrupted service availability\n• 100% accuracy of location data\n• Real-time data transmission\n• Compatibility with all devices or networks',
          ),
          _buildSection(
            '8. User Responsibilities',
            'As a user of e-Disha, you agree to:\n\n• Use the service lawfully and responsibly\n• Not interfere with or disrupt the service\n• Keep your account credentials secure\n• Report any security vulnerabilities or issues\n• Comply with applicable traffic and vehicle regulations',
          ),
          _buildSection(
            '9. Prohibited Uses',
            'You may not use our service:\n\n• For any unlawful purpose or to solicit others to perform unlawful acts\n• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n• To infringe upon or violate our intellectual property rights or the intellectual property rights of others\n• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate\n• To submit false or misleading information',
          ),
          _buildSection(
            '10. Termination',
            'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever including without limitation if you breach the Terms.',
          ),
          _buildSection(
            '11. Limitation of Liability',
            'In no event shall e-Disha, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of the service.',
          ),
          _buildSection(
            '12. Updates to Terms',
            'We reserve the right to update or modify these Terms at any time without prior notice. Your continued use of the service after any such changes constitutes your acceptance of the new Terms.',
          ),
          _buildSection(
            '13. Contact Information',
            'If you have any questions about these Terms and Conditions, please contact us at:\n\nEmail: support@edisha.com\nPhone: +91-XXXXX-XXXXX\nAddress: [Company Address]',
          ),

          const SizedBox(height: 32),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00CED1).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF006D77),
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thank you for using e-Disha',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A44),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By continuing to use our application, you acknowledge that you have read, understood, and agree to these terms and conditions.',
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
