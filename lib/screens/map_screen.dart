import 'package:flutter/material.dart';
import 'package:edisha/theme/theme.dart';
import 'package:edisha/theme/app_colors.dart';

/// Map screen placeholder for future map integration.
///
/// TODO: Integrate Google Maps and backend location APIs here.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String _statusMessage = 'Initializing map...';
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMap();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeMap() async {
    try {
      // Simulate initialization delay
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _statusMessage = 'Map ready!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error initializing map: $e';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Map View',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radius24),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showMapInfo(context);
            },
            tooltip: 'Map Information',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildMapView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).extension<AppColors>()!.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: Theme.of(context).extension<AppColors>()!.shadow,
                ),
                child: const Icon(
                  Icons.map,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
            Text(
              'Loading Map...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color:
                        Theme.of(context).extension<AppColors>()!.neutral[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing32),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Status Card
            Container(
              margin: const EdgeInsets.all(AppTheme.spacing16),
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radius16),
                boxShadow: Theme.of(context).extension<AppColors>()!.shadow,
                border: Border.all(
                  color: Theme.of(context)
                      .extension<AppColors>()!
                      .border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Map Status',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context)
                                        .extension<AppColors>()!
                                        .neutral[600],
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          _statusMessage,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Demo Map Placeholder
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radius20),
                  border: Border.all(
                    color: Theme.of(context)
                        .extension<AppColors>()!
                        .border,
                    width: 1,
                  ),
                  boxShadow: Theme.of(context).extension<AppColors>()!.shadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius20),
                  child: Stack(
                    children: [
                      // Background Pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: MapPatternPainter(
                            color: Theme.of(context)
                                .extension<AppColors>()!
                                .border,
                          ),
                        ),
                      ),

                      // Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull),
                                ),
                                child: Icon(
                                  Icons.map,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing24),
                            Text(
                              'Map View Coming Soon!',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing24,
                                vertical: AppTheme.spacing16,
                              ),
                              child: Text(
                                'This is a placeholder for the map functionality.\nThe actual map will be implemented here with full Google Maps integration.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .extension<AppColors>()!
                                          .neutral[600],
                                      height: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing32),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showMapInfo(context);
                              },
                              icon: const Icon(Icons.info),
                              label: const Text('Learn More'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing32,
                                  vertical: AppTheme.spacing16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radius12),
                                ),
                                elevation: 0,
                                shadowColor: Theme.of(context)
                                    .extension<AppColors>()!
                                    .shadow[0].color,
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

            // Action Buttons
            Container(
              margin: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showFeatureInfo(context, 'Demo Route',
                            'This feature will allow you to create and visualize routes between different locations on the map.');
                      },
                      icon: const Icon(Icons.route),
                      label: const Text('Demo Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius12),
                        ),
                        elevation: 0,
                        shadowColor: Theme.of(context)
                            .extension<AppColors>()!
                            .shadow[0].color,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showFeatureInfo(context, 'Location Services',
                            'This feature will provide real-time location tracking and navigation capabilities.');
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('My Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).extension<AppColors>()!.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius12),
                        ),
                        elevation: 0,
                        shadowColor: Theme.of(context)
                            .extension<AppColors>()!
                            .shadow[0].color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.map,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'Map Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status: DEMO MODE',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).extension<AppColors>()!.info,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'The map is currently running in demo mode and will work without any API keys. It includes:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing12),
              _buildFeatureItem('Demo locations for major Indian cities'),
              _buildFeatureItem(
                  'Current location detection (if permissions granted)'),
              _buildFeatureItem('Interactive markers and routes'),
              _buildFeatureItem(
                  'Fallback to default location if GPS unavailable'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFeatureInfo(
      BuildContext context, String title, String description) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).extension<AppColors>()!.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        margin: const EdgeInsets.all(AppTheme.spacing16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).extension<AppColors>()!.success,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for map background pattern
class MapPatternPainter extends CustomPainter {
  final Color color;

  MapPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
