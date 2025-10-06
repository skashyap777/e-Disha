import 'package:flutter/material.dart';
import 'package:edisha/theme/theme.dart';
import 'package:edisha/screens/login_screen.dart';
import 'package:edisha/screens/dashboard_screen.dart';
import 'package:edisha/services/auth_api_service.dart';

/// Splash screen with animated logo and app initialization.
///
/// TODO: Check login/auth state from backend API before navigating to login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo scale animation
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Logo pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Background fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Text slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Text opacity animation
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimationSequence() async {
    // Start background fade
    _fadeController.forward();

    // Wait a bit then start main animation
    await Future.delayed(const Duration(milliseconds: 300));
    _mainController.forward();

    // Start pulse after main animation
    await Future.delayed(const Duration(milliseconds: 1200));
    _pulseController.repeat(reverse: true);

    // Check authentication status
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      final authService = AuthApiService();
      final isAuthenticated = await authService.isAuthenticated();
      
      print('🔍 SPLASH: isAuthenticated = $isAuthenticated');
      
      // Navigate based on authentication status
      final targetScreen = isAuthenticated 
          ? const DashboardScreen() 
          : const LoginScreen();
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // Top section with logo
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo container with animations
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color.fromARGB(255, 255, 255, 255)
                                            .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacing32),
                      ],
                    ),
                  ),
                ),

                // Bottom section with tagline and loading
                Expanded(
                  flex: 2,
                  child: FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tagline
                        Text(
                          'Your Digital Guide',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.black.withOpacity(0.9),
                                    fontWeight: FontWeight.w300,
                                  ),
                        ),

                        const SizedBox(height: AppTheme.spacing24),

                        // Loading indicator
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black.withOpacity(0.8),
                            ),
                            strokeWidth: 3,
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacing24),

                        // Loading text
                        Text(
                          'Initializing...',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),

                        const SizedBox(height: AppTheme.spacing40),

                        // Version info
                        Text(
                          'Version 1.0.0',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
