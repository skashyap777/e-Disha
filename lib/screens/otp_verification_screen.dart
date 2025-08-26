import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:edisha/theme/theme.dart';
import 'package:edisha/screens/dashboard_screen.dart';
import 'package:edisha/theme/app_colors.dart';

/// Screen for OTP verification after login.
///
/// TODO: Integrate real OTP send/verify API in _sendOTP and _verifyOTP methods.
class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 30;
  late Timer _timer;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _initializeAnimations();
    _sendOTP(); // Auto-send OTP when screen loads
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Reduced duration
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      // Reduced scale end value further
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.linear, // Changed to a simpler curve
      ),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Sends OTP to the user's phone number. Replace with real API call in the future.
  Future<void> _sendOTP() async {
    if (mounted) {
      setState(() {
        _isResending = true;
      });
    }

    try {
      // TODO: Replace with real OTP send API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    'OTP sent to +91 ${widget.phoneNumber}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).extension<AppColors>()!.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            margin: const EdgeInsets.all(AppTheme.spacing16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    'Failed to send OTP: $e',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            margin: const EdgeInsets.all(AppTheme.spacing16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    if (mounted) {
      setState(() {
        _resendTimer = 30;
      });
    }
    _startResendTimer();
    await _sendOTP();
  }

  /// Verifies the entered OTP. Replace with real API call in the future.
  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    // Store the OTP text before any async operations
    final String otpText = _otpController.text;

    if (otpText.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    'Please enter a valid 6-digit OTP',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).extension<AppColors>()!.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            margin: const EdgeInsets.all(AppTheme.spacing16),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // TODO: Replace with real OTP verify API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Simulate OTP verification (123456 is always valid for demo)
      if (otpText == '123456') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const DashboardScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      'Invalid OTP. Please try again.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              margin: const EdgeInsets.all(AppTheme.spacing16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    'Verification failed: $e',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            margin: const EdgeInsets.all(AppTheme.spacing16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'OTP Verification',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radius24),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppTheme.spacing32),

                      // OTP Icon with Pulse Animation
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: Theme.of(context)
                                .extension<AppColors>()!
                                .primaryGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            boxShadow: AppTheme.getShadow(Theme.of(context)
                                .extension<AppColors>()!
                                .shadow['default']!),
                          ),
                          child: const Icon(
                            Icons.phone_android,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing32),

                      // Title
                      Text(
                        'Verify Your Phone',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacing16),

                      // Subtitle
                      Text(
                        'We\'ve sent a 6-digit verification code to',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .extension<AppColors>()!
                                  .neutral[600],
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacing8),

                      // Phone Number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing20,
                          vertical: AppTheme.spacing12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '+91 ${widget.phoneNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing40),

                      // OTP Input Field
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        onChanged: (value) {},
                        onCompleted: (value) {
                          _verifyOTP();
                        },
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius12),
                          fieldHeight: AppTheme.spacing56,
                          fieldWidth: AppTheme.spacing48,
                          activeFillColor: Theme.of(context).cardColor,
                          activeColor: Theme.of(context).colorScheme.primary,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Theme.of(context)
                              .extension<AppColors>()!
                              .border['default'],
                          selectedFillColor: Theme.of(context).cardColor,
                          inactiveFillColor: Theme.of(context).cardColor,
                        ),
                        keyboardType: TextInputType.number,
                        enableActiveFill: true,
                        animationType: AnimationType.fade,
                        textStyle:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: AppTheme.spacing32),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: AppTheme.spacing56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Theme.of(context)
                                .extension<AppColors>()!
                                .shadow['default'],
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radius16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing32,
                              vertical: AppTheme.spacing20,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spacing12),
                                    Text(
                                      'Verify OTP',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing24),

                      // Resend OTP Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Didn\'t receive the code? ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .extension<AppColors>()!
                                      .neutral[600],
                                ),
                          ),
                          GestureDetector(
                            onTap: _resendTimer > 0 ? null : _resendOTP,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
                                vertical: AppTheme.spacing4,
                              ),
                              decoration: BoxDecoration(
                                color: _resendTimer > 0
                                    ? Theme.of(context)
                                        .extension<AppColors>()!
                                        .border['default']
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radius8),
                              ),
                              child: Text(
                                _resendTimer > 0
                                    ? 'Resend in $_resendTimer seconds'
                                    : 'Resend OTP',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _resendTimer > 0
                                          ? Theme.of(context)
                                              .extension<AppColors>()!
                                              .neutral[600]
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isResending) ...[
                        const SizedBox(height: AppTheme.spacing16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            Text(
                              'Sending OTP...',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .extension<AppColors>()!
                                        .neutral[600],
                                  ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacing40),

                      // Demo OTP Hint
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing20),
                        decoration: BoxDecoration(
                          gradient: Theme.of(context)
                              .extension<AppColors>()!
                              .infoGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius16),
                          boxShadow: AppTheme.getShadow(Theme.of(context)
                              .extension<AppColors>()!
                              .shadow['default']!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: AppTheme.spacing16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demo Mode',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.spacing4),
                                  Text(
                                    'Use 123456 as OTP for testing',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}
