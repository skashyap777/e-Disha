import 'package:flutter/material.dart';
import 'package:edisha/generated/app_localizations.dart';

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
        title: Text(
          AppLocalizations.of(context)?.termsConditionsTitle ?? 'Terms & Conditions',
          style: const TextStyle(
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
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)?.termsConditionsTitle ?? 'Terms & Conditions',
                              style: const TextStyle(
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
                        '${AppLocalizations.of(context)?.lastUpdated ?? 'Last updated'}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)?.pleaseReadTermsCarefully ?? 'Please read these terms and conditions carefully before using the e-Disha application.',
                        style: const TextStyle(
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
            AppLocalizations.of(context)?.acceptanceOfTermsTitle ?? '1. Acceptance of Terms',
            AppLocalizations.of(context)?.acceptanceOfTermsContent ?? 'By accessing and using the e-Disha application ("App"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
          ),
          _buildSection(
            AppLocalizations.of(context)?.useLicenseTitle ?? '2. Use License',
            AppLocalizations.of(context)?.useLicenseContent ?? 'Permission is granted to temporarily download one copy of e-Disha per device for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to reverse engineer any software contained in the App\n• Remove any copyright or other proprietary notations',
          ),
          _buildSection(
            AppLocalizations.of(context)?.privacyPolicyTermsTitle ?? '3. Privacy Policy',
            AppLocalizations.of(context)?.privacyPolicyTermsContent ?? 'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our service. By using our service, you agree to the collection and use of information in accordance with our Privacy Policy.',
          ),
          _buildSection(
            AppLocalizations.of(context)?.userAccountTitle ?? '4. User Account',
            AppLocalizations.of(context)?.userAccountContent ?? 'When you create an account with us, you must provide information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities that occur under your account.',
          ),
          _buildSection(
            AppLocalizations.of(context)?.vehicleTrackingTitle ?? '5. Vehicle Tracking Services',
            AppLocalizations.of(context)?.vehicleTrackingContent ?? 'e-Disha provides GPS tracking and fleet management services. You understand that:\n\n• Location data accuracy depends on GPS signal availability\n• Service may be temporarily unavailable due to technical issues\n• You are responsible for ensuring proper device installation\n• Data transmission requires active mobile/internet connectivity',
          ),
          _buildSection(
            AppLocalizations.of(context)?.dataCollectionTitle ?? '6. Data Collection and Usage',
            AppLocalizations.of(context)?.dataCollectionContent ?? 'We collect and process data to provide our services effectively:\n\n• Location data for real-time tracking and route optimization\n• Vehicle performance data for maintenance alerts\n• User interaction data to improve app functionality\n• All data collection complies with applicable privacy laws\n• You can control data sharing through app settings',
          ),
          _buildSection(
            AppLocalizations.of(context)?.serviceLimitationsTitle ?? '7. Service Limitations',
            AppLocalizations.of(context)?.serviceLimitationsContent ?? 'Our services are provided \'as is\' and may have limitations:\n\n• GPS accuracy may vary based on environmental conditions\n• Service availability depends on network connectivity\n• We do not guarantee uninterrupted service\n• Features may be updated or modified without prior notice\n• Some features may require additional subscriptions',
          ),
          _buildSection(
            AppLocalizations.of(context)?.userResponsibilitiesTitle ?? '8. User Responsibilities',
            AppLocalizations.of(context)?.userResponsibilitiesContent ?? 'As a user of e-Disha, you agree to:\n\n• Provide accurate and up-to-date information\n• Use the service only for lawful purposes\n• Maintain the security of your account credentials\n• Report any unauthorized use of your account\n• Comply with all applicable laws and regulations\n• Respect the privacy and rights of other users',
          ),
          _buildSection(
            AppLocalizations.of(context)?.prohibitedUsesTitle ?? '9. Prohibited Uses',
            AppLocalizations.of(context)?.prohibitedUsesContent ?? 'You may not use our service for:\n\n• Any unlawful purpose or to solicit others to unlawful acts\n• Violating any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n• Infringing upon or violating our intellectual property rights or the intellectual property rights of others\n• Harassing, abusing, insulting, harming, defaming, slandering, disparaging, intimidating, or discriminating\n• Submitting false or misleading information',
          ),
          _buildSection(
            AppLocalizations.of(context)?.terminationTitle ?? '10. Termination',
            AppLocalizations.of(context)?.terminationContent ?? 'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.',
          ),
          _buildSection(
            AppLocalizations.of(context)?.limitationOfLiabilityTitle ?? '11. Limitation of Liability',
            AppLocalizations.of(context)?.limitationOfLiabilityContent ?? 'In no event shall e-Disha, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of the service.',
          ),
          _buildSection(
            AppLocalizations.of(context)?.updatesToTermsTitle ?? '12. Updates to Terms',
            AppLocalizations.of(context)?.updatesToTermsContent ?? 'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.',
          ),
          _buildSection(
            AppLocalizations.of(context)?.contactInformationTitle ?? '13. Contact Information',
            AppLocalizations.of(context)?.contactInformationContent ?? 'If you have any questions about these Terms and Conditions, please contact us at:\n\nEmail: support@edisha.com\nPhone: +91-XXXXX-XXXXX\nAddress: [Company Address]',
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
                Text(
                  AppLocalizations.of(context)?.thankYouForUsing ?? 'Thank you for using e-Disha',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A44),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.byContinuingYouAcknowledge ?? 'By continuing to use our application, you acknowledge that you have read, understood, and agree to these terms and conditions.',
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
