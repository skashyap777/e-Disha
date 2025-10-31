import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:edisha/generated/app_localizations.dart';
import 'package:edisha/screens/otp_verification_screen.dart';
import 'package:edisha/screens/terms_conditions_screen.dart';
import 'package:edisha/screens/privacy_policy_screen.dart';
import 'package:edisha/services/auth_service.dart';
import 'package:edisha/services/auth_api_service.dart';
import 'package:edisha/utils/error_handler.dart';
import 'package:edisha/components/app_button.dart';
import 'package:edisha/components/app_input.dart';
import 'package:edisha/widgets/network_status_indicator.dart';
import 'package:edisha/providers/language_provider.dart';

/// Login screen for user authentication.
///
/// TODO: Integrate real login API in _handleLogin method.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final AuthApiService _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
       vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
  }

  void _startAnimation() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  String? _validateMobile(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterMobileNumber;
    }
    if (value.length != 10) {
      return l10n.mobileNumberMustBe10Digits;
    }
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
      return l10n.pleaseEnterValidIndianMobileNumber;
    }
    return null;
  }

  String? _validateMobileAny(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n?.pleaseEnterMobileNumber ?? 'Please enter your mobile number';
    }
    if (value.length < 10) {
      return l10n?.mobileNumberMustBeAtLeast10Digits ?? 'Mobile number must be at least 10 digits';
    }
    if (value.length > 15) {
      return l10n?.mobileNumberMustBeAtMost15Digits ?? 'Mobile number must be at most 15 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n?.pleaseEnterPassword ?? 'Please enter your password';
    }
    if (value.length < 6) {
      return l10n?.passwordMustBeAtLeast6Characters ?? 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _mobileFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Handles login logic using real API or demo authentication
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    print(
        '📱 LOGIN SCREEN: Starting login process for mobile: ${_mobileController.text}');
    setState(() => _isLoading = true);

    try {
      final result = await _authApiService.login(
          _mobileController.text, _passwordController.text);

      if (mounted) {
        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Login successful! OTP sent.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Navigate to OTP verification only on successful login API call
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  OTPVerificationScreen(phoneNumber: _mobileController.text),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else {
          // Show error and stay on login screen
          String errorMsg = result['message'] ??
              'Login failed. Please check your credentials.';
          
          final errorCode = result['errorCode'];
          
          if (errorCode == 522 || (errorCode != null && errorCode >= 500)) {
            // Show server maintenance dialog for 522 or 5xx errors
            ErrorHandler.showServerMaintenanceDialog(context);
          } else {
            // Show regular error message with retry option
            ErrorHandler.showUserFriendlyError(
              context,
              errorMsg,
              onRetry: _handleLogin,
            );
          }

          // Clear password field for security
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showUserFriendlyError(
          context,
          ErrorHandler.getUserFriendlyMessage(e),
          onRetry: _handleLogin,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return NetworkStatusIndicator(
      child: Scaffold(
        backgroundColor: const Color(0xFF006D77), // Deep teal base
        body: Container(
          decoration: _buildProfessionalBackground(),
          child: Stack(
            children: [
              // Wave/Ripple Pattern Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _WavePatternPainter(),
                ),
              ),
              // Compass Icons
              _buildCompassIcons(),
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                    child: Column(
                      children: [
                        // Header Section with Logo
                        Expanded(
                          flex: 2,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Language switcher at the top of header
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Consumer<LanguageProvider>(
                                          builder: (context, languageProvider, child) {
                                            return GestureDetector(
                                              onTap: () {
                                                print('🌐 Header language switcher tapped!');
                                                _showLanguageDialog(context);
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(right: 20),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: const Color(0xFF3B82F6),
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.language,
                                                        color: const Color(0xFF3B82F6),
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        languageProvider.currentLanguageDisplayName,
                                                        style: const TextStyle(
                                                          color: Color(0xFF1A2A44),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.keyboard_arrow_down,
                                                        color: const Color(0xFF3B82F6),
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Golden Logo Container
                                  ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Container(
                                      width: 160,
                                      height: 160,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white, // White background for better contrast
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFFFFD700), // Golden yellow border
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.dashboard_rounded,
                                            size: 80,
                                            color: Color(0xFF1A2A44), // Navy blue for error icon
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Welcome Text
                                  Text(
                                    l10n?.welcomeBack ?? 'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n?.signInToContinue ?? 'Sign in to continue to e-Disha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Login Form Section
                        Expanded(
                          flex: 3,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    Text(
                                      l10n?.login ?? 'Login',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A2A44),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n?.signInToContinue ?? 'Sign in to continue to e-Disha',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: const Color(0xFF1A2A44).withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // Mobile Number Input
                                    AppInput(
                                      controller: _mobileController,
                                      focusNode: _mobileFocusNode,
                                      label: l10n?.mobileNumber ?? 'Mobile Number',
                                      hintText: l10n?.enterMobileNumber ?? 'Enter your mobile number',
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: const Icon(Icons.phone_android),
                                      maxLength: 15, // Allow longer numbers
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]')), // Allow any digits
                                      ],
                                      validator: _validateMobileAny,
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Password Input
                                    AppInput(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      label: l10n?.password ?? 'Password',
                                      hintText: l10n?.enterPassword ?? 'Enter your password',
                                      obscureText: _obscurePassword,
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword 
                                              ? Icons.visibility_off 
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator: _validatePassword,
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 32),

                                    // Continue Button
                                    AppButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      text: l10n?.login ?? 'Login',
                                      icon: Icons.arrow_forward,
                                      iconPosition: IconPosition.right,
                                      isLoading: _isLoading,
                                      size: AppButtonSize.fullWidth,
                                      height: 56,
                                      semanticLabel: l10n?.login ?? 'Login',
                                      tooltip: 'Proceed to OTP verification',
                                    ),

                                    const Spacer(),

                                    // Footer Text
                                    Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            l10n?.byContinuingYouAgree ?? 'By continuing, you agree to our',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF1A2A44).withOpacity(0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => const TermsConditionsScreen(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  l10n?.termsAndConditions ?? 'Terms & Conditions',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF00CED1),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                ' ${l10n?.and ?? 'and'} ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: const Color(0xFF1A2A44).withOpacity(0.6),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => const PrivacyPolicyScreen(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  l10n?.privacyPolicy ?? 'Privacy Policy',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF00CED1),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }



  // Show language selection dialog
  void _showLanguageDialog(BuildContext context) {
    print('🌐 Showing language dialog...'); // Debug log
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.language, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              Text(l10n?.selectLanguage ?? 'Select Language'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Text('🇺🇸', style: TextStyle(fontSize: 28)),
                      title: Text(
                        l10n?.english ?? 'English',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: languageProvider.isEnglish 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 24) 
                          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                      onTap: () {
                        languageProvider.changeLanguage('en');
                        Navigator.of(context).pop();
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    ListTile(
                      leading: const Text('🇮🇳', style: TextStyle(fontSize: 28)),
                      title: Text(
                        l10n?.hindi ?? 'हिंदी',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: languageProvider.isHindi 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 24) 
                          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                      onTap: () {
                        languageProvider.changeLanguage('hi');
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n?.cancel ?? 'Cancel',
                style: const TextStyle(color: Color(0xFF3B82F6)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Compass icons positioned around the screen
  Widget _buildCompassIcons() {
    return Stack(
      children: [
        // Top left compass
        Positioned(
          top: 100,
          left: 30,
          child: Icon(
            Icons.explore,
            size: 32,
            color: const Color(0xFFFF4040).withOpacity(0.7), // Red
          ),
        ),
        // Top right star
        Positioned(
          top: 120,
          right: 40,
          child: Icon(
            Icons.star,
            size: 28,
            color: const Color(0xFF1E90FF).withOpacity(0.8), // Blue
          ),
        ),
        // Bottom left star
        Positioned(
          bottom: 150,
          left: 50,
          child: Icon(
            Icons.star_border,
            size: 24,
            color: const Color(0xFFFF4040).withOpacity(0.6), // Red
          ),
        ),
        // Bottom right compass
        Positioned(
          bottom: 200,
          right: 30,
          child: Icon(
            Icons.explore_outlined,
            size: 30,
            color: const Color(0xFF1E90FF).withOpacity(0.7), // Blue
          ),
        ),
        // Additional floating elements
        Positioned(
          top: 300,
          left: 20,
          child: Icon(
            Icons.navigation,
            size: 20,
            color: const Color(0xFFFF4040).withOpacity(0.5),
          ),
        ),
        Positioned(
          top: 250,
          right: 60,
          child: Icon(
            Icons.my_location,
            size: 22,
            color: const Color(0xFF1E90FF).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Professional gradient background
  BoxDecoration _buildProfessionalBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF006D77), // Deep teal
          Color(0xFF00CED1), // Bright cyan
          Color(0xFF7FFF00), // Lime green
        ],
        stops: [0.0, 0.6, 1.0],
      ),
    );
  }
}

// Custom painter for wave/ripple background pattern
class _WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Wave pattern paint
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.15);

    // Draw wave patterns
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final amplitude = 30.0 + (i * 10);
      final frequency = 0.02 + (i * 0.005);
      final yOffset = size.height * 0.3 + (i * 40);

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 2) {
        final y = yOffset + amplitude * math.sin(frequency * x);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    // Ripple effects
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.1);

    // Draw ripples from different centers
    final centers = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.3),
    ];

    for (final center in centers) {
      for (int j = 1; j <= 5; j++) {
        canvas.drawCircle(
          center,
          j * 40.0,
          ripplePaint,
        );
      }
    }

    // Subtle geometric patterns
    final geometryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.08);

    // Draw floating geometric shapes
    for (int i = 0; i < 8; i++) {
      final x = (i * 100.0) % size.width;
      final y = (i * 80.0) % size.height;
      final radius = 15.0 + (i % 3) * 5;

      // Draw hexagons
      final hexPath = Path();
      for (int j = 0; j < 6; j++) {
        final angle = (j * 60) * math.pi / 180;
        final px = x + radius * math.cos(angle);
        final py = y + radius * math.sin(angle);

        if (j == 0) {
          hexPath.moveTo(px, py);
        } else {
          hexPath.lineTo(px, py);
        }
      }
      hexPath.close();
      canvas.drawPath(hexPath, geometryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}