// dashboard_screen.dart
// Complete professional Flutter dashboard with modern UI, responsive design,
// proper error handling, state management, and clean architecture for 2025

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'pattern_painter.dart';
import 'alert_management_screen.dart';
import 'driver_management_screen.dart';
import '../providers/dashboard_provider.dart';
import '../services/auth_api_service.dart';
import '../widgets/responsive_dashboard_cards.dart';
import '../widgets/service_management_card.dart';

// App Colors - moved from theme files
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color tertiary = Color(0xFF06B6D4);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral colors
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  
  // Card background
  static const Color cardBackground = Color(0xFFF8FAFC);
  
  // Gradients
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 2;
  Timer? _refreshTimer;
  late AnimationController _animationController;
  bool _isTablet = false;
  String? _userPhoneNumber;

  // Sample dashboard data for UI cards that don't use real API yet
  final Map<String, dynamic> _staticDashboardData = {
    'fleetCategories': {
      'schoolBuses': 20,
      'cabs': 52,
      'passengerVehicles': 42,
      'dumpers': 18,
      'tankers': 26,
      'goodsCarrier': 16,
    },
    'realTimeMetrics': {
      'avgSpeed': 48.2,
      'speedChange': 2.1,
      'totalTrips': 30,
      'tripsChange': -5.2,
      'distanceToday': 2847,
      'distanceChange': 18.3,
    },
    'health': {
      'totalActivated': 8,
      'activatedToday': 10,
      'inactive7Days': 2,
      'inactive30Days': 1,
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    // Fetch initial dashboard data and user info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.fetchDashboardData();
      _loadUserPhoneNumber();
    });
    
    _startAutoRefresh();
  }

  /// Load the user's phone number from stored authentication data
  Future<void> _loadUserPhoneNumber() async {
    try {
      final authService = AuthApiService();
      final phoneNumber = await authService.getStoredMobile();
      if (mounted && phoneNumber != null) {
        setState(() {
          _userPhoneNumber = phoneNumber;
        });
        print('📱 USER PHONE NUMBER LOADED: $phoneNumber');
      }
    } catch (e) {
      print('❌ ERROR LOADING PHONE NUMBER: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refreshDashboard());
  }

  Future<void> _refreshDashboard() async {
    if (mounted) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      await provider.fetchDashboardData();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/route-fixing');
        break;
      case 1:
        Navigator.pushNamed(context, '/live-tracking');
        break;
      case 3:
        // Navigate to Live Tracking and automatically open history playback dialog
        Navigator.pushNamed(
          context, 
          '/live-tracking',
          arguments: {'openHistoryDialog': true},
        );
        break;
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(
                    color:
                        Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Clear authentication data
        final authService = AuthApiService();
        await authService.logout(); // Call API logout
        await authService.clearTokens(); // Clear local tokens
        
        print('🚪 LOGOUT: User logged out and auth data cleared');
        
        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Navigate to login screen
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged out'),
              backgroundColor: Color.fromARGB(213, 50, 230, 50),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('❌ LOGOUT ERROR: $e');
        
        // Dismiss loading dialog if it's showing
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: const ValueKey('dashboard-scaffold'),
      backgroundColor: Colors.transparent, // Make transparent for background image
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      bottomNavigationBar: _buildBottomNavigation(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7DD3FC), // Light teal at top
              Color(0xFF86EFAC), // Pale green at bottom
            ],
          ),
        ),
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            if (provider.hasError) {
              return _buildErrorState(context);
            }
            
            return RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: AppColors.primary,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  _isTablet = constraints.maxWidth > 600;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        if (provider.isLoading && !provider.hasData)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...<Widget>[
                          const SizedBox(height: 8),
                          _isTablet ? _buildTabletGrid(provider) : _buildMobileList(provider),
                        ],
                      ].map((w) => w.animate().fadeIn()).toList(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: const Color(0xFF3B82F6), // Lighter blue for AppBar
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 70,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // Semi-transparent white on navy
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.dashboard_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: Colors.white, // White icon on navy background
            size: 24,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        // Notifications button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Semi-transparent white
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white, // White icon
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertManagementScreen()),
              );
              // Refresh dashboard when returning
              if (context.mounted) {
                final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                dashboardState?._refreshDashboard();
              }
            },
          ),
        ),
        // Profile menu
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.person_rounded,
                  color: colorScheme.onPrimary, size: 20),
            ),
            color: Colors.white, // Solid white for popup menu
            surfaceTintColor: Colors.white,
            onSelected: (String result) {
              if (result == 'logout') {
                _performLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'welcome',
                enabled: false, // Make it non-clickable
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userPhoneNumber != null ? '+91 $_userPhoneNumber' : 'Loading...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: colorScheme.error),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: const Color(0xFFF1F5F9).withOpacity(0.95), // Very light blue-gray background
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 60,
                color: Colors.white,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.dashboard_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                    Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context)),
                _DrawerItem(Icons.route_rounded, 'Route Fixing', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/route-fixing');
                }),
                _DrawerItem(Icons.gps_fixed_rounded, 'Live Tracking', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/live-tracking');
                }),
                _DrawerItem(Icons.history_rounded, 'Vehicle History', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/history');
                }),
                _DrawerItem(Icons.person_add_rounded, 'Add Driver', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/add-driver');
                }),
                _DrawerItem(Icons.notifications_active_rounded, 'Alerts', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/alert-management');
                }),
                _DrawerItem(Icons.description_rounded, 'Reports', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reports');
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '© DARS Transtrade Pvt. Ltd.',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Lighter blue background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.6),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.white,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.route_rounded),
                activeIcon: Icon(Icons.route_rounded),
                label: 'Routes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.my_location_rounded),
                activeIcon: Icon(Icons.my_location_rounded),
                label: 'Live',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                activeIcon: Icon(Icons.history_rounded),
                label: 'History Playback',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(DashboardProvider provider) {
    return Column(
      children: _buildDashboardCards(provider)
          .map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card.animate().fadeIn(),
              ))
          .toList(),
    );
  }

  Widget _buildTabletGrid(DashboardProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _buildDashboardCards(provider)
          .map((card) => card.animate().fadeIn())
          .toList(),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDashboardCards(DashboardProvider provider) {
    return [
      // Responsive Vehicle Status Card
      FadeTransition(
        opacity: _animationController,
        child: const ResponsiveVehicleStatusCard(),
      ),
      // Responsive Alert Overview Card
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: const ResponsiveAlertOverviewCard(),
      ),
      // Responsive Driver Behaviour Card
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: const ResponsiveDriverBehaviourCard(),
      ),
      // Enhanced Service Management Card
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: const ServiceManagementCard(),
      ),
    ];
  }
}

// Enhanced FLEET CATEGORIES CARD
class _FleetCategoriesCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FleetCategoriesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light gray background for all cards
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Light shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Fleet Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B), // Dark text for light cards
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FleetCategoriesCardState._buildFleetGrid(data),
          ],
        ),
      ),
    );
  }
}

class _FleetCategoriesCardState {
  static Widget _buildFleetGrid(Map<String, dynamic> data) {
    final categories = [
      {
        'name': 'School Buses',
        'count': data['schoolBuses'] ?? 0,
        'icon': Icons.directions_bus_outlined,
        'color': const Color(0xFF22C55E), // Green
        'badgeColor': const Color(0xFF86EFAC), // Light green badge
      },
      {
        'name': 'Cabs',
        'count': data['cabs'] ?? 0,
        'icon': Icons.local_taxi_outlined,
        'color': const Color(0xFFF59E0B), // Orange
        'badgeColor': const Color(0xFFFDE047), // Yellow badge
      },
      {
        'name': 'Passenger Vehicles',
        'count': data['passengerVehicles'] ?? 0,
        'icon': Icons.directions_car_outlined,
        'color': const Color(0xFF3B82F6), // Blue
        'badgeColor': const Color(0xFF7DD3FC), // Light blue badge
      },
      {
        'name': 'Dumpers',
        'count': data['dumpers'] ?? 0,
        'icon': Icons.construction_outlined,
        'color': const Color(0xFF8B5CF6), // Purple
        'badgeColor': const Color(0xFFC084FC), // Light purple badge
      },
      {
        'name': 'Tankers',
        'count': data['tankers'] ?? 0,
        'icon': Icons.local_shipping_outlined,
        'color': const Color(0xFFEF4444), // Red
        'badgeColor': const Color(0xFFFCA5A5), // Light red badge
      },
      {
        'name': 'Goods Carrier',
        'count': data['goodsCarrier'] ?? 0,
        'icon': Icons.fire_truck_outlined,
        'color': const Color(0xFF06B6D4), // Cyan
        'badgeColor': const Color(0xFF67E8F9), // Light cyan badge
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4, // Reduced from 2.2 to make cards taller
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _FleetCategoriesCardState._buildCategoryCard(category);
      },
    );
  }

  static Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final appColors = theme.extension<AppColors>();
        
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.95), // Use light card background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neutral200, // Light border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Light shadow
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Increased back to 16 for better spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8), // Increased back to 8
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 20, // Increased back to 20
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: category['badgeColor'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${category['count']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: category['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Increased spacing
            Expanded( // Changed from Flexible to Expanded for better text display
              child: Text(
                category['name'] as String,
                style: TextStyle(
                  fontSize: 13, // Increased from 11 to 13
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700, // Dark text
                  letterSpacing: 0.1,
                  height: 1.3, // Added line height for better readability
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
      }
    );
  }
}

// Enhanced REAL-TIME METRICS CARD
class _RealTimeMetricsCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RealTimeMetricsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light gray background for all cards
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Light shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1), // Light info background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    color: AppColors.info, // Info color
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Real-Time Metrics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral800, // Dark text
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1), // Light success background
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success, // Success color
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMetricsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Avg Speed',
            '${data['avgSpeed'] ?? 0} km/h',
            data['speedChange'] ?? 0.0,
            Icons.speed_outlined,
            const Color(0xFF06B6D4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Total Trips',
            '${data['totalTrips'] ?? 0}',
            data['tripsChange'] ?? 0.0,
            Icons.directions_car_outlined,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Distance Today',
            '${data['distanceToday'] ?? 0} km',
            data['distanceChange'] ?? 0.0,
            Icons.straighten_outlined,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, double change, IconData icon, Color color) {
    final isPositive = change >= 0;
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final appColors = theme.extension<AppColors>();
        
        return Container(
          padding: const EdgeInsets.all(14), // Reduced from 16
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC).withOpacity(0.95), // Very light gray with good opacity
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.neutral200, // Light border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Light shadow
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 12,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Reduced from 12
              Text(
                value,
                style: TextStyle(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3), // Reduced from 4
              Text(
                title,
                style: TextStyle(
                  fontSize: 10, // Reduced from 11
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral500, // Medium gray text
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// Drawer Item Widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem(this.icon, this.title, this.onTap);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF6B7280),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF334155),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

// Enhanced VEHICLE STATUS CARD with real ignition and professional status
class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VehicleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColors>();
    
    // Get real ignition data
    final ignitionOn = data['ignitionOn'] ?? 0;
    final ignitionOff = data['ignitionOff'] ?? 0;
    final moving = data['moving'] ?? 0;
    final idle = data['idle'] ?? 0;
    final stopped = data['stopped'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/vehicle-details'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light gray background for all cards
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Light shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Vehicle Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B), // Dark text for light cards
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${data['total']}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B), // Dark text for light cards
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Total Vehicles',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Ignition Status Section
              Text(
                'Ignition Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusItem(
                      context, 
                      'Ignition ON', 
                      ignitionOn, 
                      const Color(0xFF22C55E), // Bright green for ON
                      Icons.power_settings_new_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusItem(
                      context, 
                      'Ignition OFF', 
                      ignitionOff,
                      const Color(0xFFEF4444), // Red for OFF
                      Icons.power_off_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Vehicle Movement Status Section
              Text(
                'Movement Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusItem(
                      context, 
                      'Moving', 
                      moving, 
                      const Color(0xFF3B82F6), // Blue for moving
                      Icons.directions_car_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusItem(
                      context, 
                      'Idle', 
                      idle,
                      const Color(0xFFF59E0B), // Orange for idle
                      Icons.pause_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusItem(
                      context, 
                      'Stopped', 
                      stopped,
                      const Color(0xFF8B5CF6), // Purple for stopped
                      Icons.stop_circle_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(
      BuildContext context, String label, int value, Color color, IconData icon) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Enhanced ALERTS CARD
class _AlertsCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _AlertsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/alert-management');
        // Refresh dashboard when returning
        if (context.mounted) {
          final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
          dashboardState?._refreshDashboard();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light gray background for all cards
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Light shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1), // Light warning background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: AppColors.warning, // Warning color
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Alerts Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral800, // Dark text
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildAlertItem(
                    'This Month',
                    '${data?['thisMonth'] ?? 0}',
                    Icons.calendar_month_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAlertItem(
                    'Today',
                    '${data?['today'] ?? 0}',
                    Icons.today_rounded,
                    const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAlertItem(
                    'Total',
                    '${data?['total'] ?? 0}',
                    Icons.info_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String value, IconData icon, Color color) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final appColors = theme.extension<AppColors>();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC).withOpacity(0.95), // Very light gray with good opacity
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.neutral200, // Light border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Light shadow
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral500, // Medium gray text
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    );
  }
}

// Enhanced HEALTH CARD
class _HealthCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _HealthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light gray background for all cards
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Light shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1), // Light info background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.info, // Info color
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Health Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral800, // Dark text
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3, // Increased to reduce height and prevent overflow
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildHealthItem(
                  'Activated',
                  '${data?['totalActivated'] ?? 0}',
                  Icons.power_settings_new_rounded,
                  const Color(0xFF10B981),
                ),
                _buildHealthItem(
                  'Today',
                  '${data?['activatedToday'] ?? 0}',
                  Icons.today_rounded,
                  const Color(0xFF0EA5E9),
                ),
                _buildHealthItem(
                  'Inactive 7D',
                  '${data?['inactive7Days'] ?? 0}',
                  Icons.schedule_rounded,
                  const Color(0xFFF59E0B),
                ),
                _buildHealthItem(
                  'Inactive 30D',
                  '${data?['inactive30Days'] ?? 0}',
                  Icons.warning_rounded,
                  const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String title, String value, IconData icon, Color color) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final appColors = theme.extension<AppColors>();
        
        return Container(
          padding: const EdgeInsets.all(8), // Further reduced to prevent overflow
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC).withOpacity(0.95), // Very light gray with good opacity
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neutral200, // Light border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Light shadow
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(3), // Further reduced to save space
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16, // Reduced from 18
                ),
              ),
              const SizedBox(height: 2), // Reduced to prevent overflow
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 1), // Minimal spacing to prevent overflow
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10, // Reduced from 11
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500, // Medium gray text
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// Enhanced DRIVER CARD
class _DriverCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const _DriverCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/driver-management');
        // Refresh dashboard when returning
        if (context.mounted) {
          final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
          dashboardState?._refreshDashboard();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light gray background for all cards
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Light shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1), // Use theme secondary color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: colorScheme.secondary, // Use theme secondary color
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Driver Behavior',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral800, // Dark text
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                _buildDriverItem(
                  'Total Drivers',
                  '${data?['totalDrivers'] ?? 0}',
                  Icons.people_rounded,
                  const Color(0xFF8B5CF6),
                  false,
                ),
                const SizedBox(height: 12),
                _buildDriverItem(
                  'Harsh Braking',
                  '${data?['harshBraking'] ?? 0}',
                  Icons.warning_rounded,
                  const Color(0xFFEF4444),
                  true,
                ),
                const SizedBox(height: 12),
                _buildDriverItem(
                  'Sudden Turn',
                  '${data?['suddenTurn'] ?? 0}',
                  Icons.turn_right_rounded,
                  const Color(0xFFF59E0B),
                  true,
                ),
                const SizedBox(height: 12),
                _buildDriverItem(
                  'Overspeeding',
                  '${data?['overspeeding'] ?? 0}',
                  Icons.speed_rounded,
                  const Color(0xFF06B6D4),
                  true,
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDriverItem(String label, String value, IconData icon, Color color, bool isCountMetric) {
    Color getSeverityColor() {
      final intValue = int.tryParse(value) ?? 0;
      if (!isCountMetric) return color;
      if (intValue == 0) return const Color(0xFF10B981); // Green for good
      if (intValue <= 5) return const Color(0xFFF59E0B); // Yellow for moderate
      return const Color(0xFFEF4444); // Red for high
    }

    String getSeverityLabel() {
      final intValue = int.tryParse(value) ?? 0;
      if (!isCountMetric) return '';
      if (intValue == 0) return 'Excellent';
      if (intValue <= 2) return 'Good';
      if (intValue <= 5) return 'Fair';
      return 'Poor';
    }

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final appColors = theme.extension<AppColors>();
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC).withOpacity(0.95), // Very light gray with good opacity
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neutral200, // Light border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Light shadow
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutral800, // Dark text for light cards
                      ),
                    ),
                    // Only show severity label for performance metrics, not count metrics
                    if (isCountMetric)
                      Text(
                        getSeverityLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: getSeverityColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: getSeverityColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// Service Management Card
class _ServiceManagementCard extends StatelessWidget {
  const _ServiceManagementCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_applications_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Service Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildServiceTile(
                  context,
                  'Alerts',
                  Icons.notifications_active,
                  Colors.red,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AlertManagementScreen()),
                    );
                    // Refresh dashboard when returning
                    if (context.mounted) {
                      final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                      dashboardState?._refreshDashboard();
                    }
                  },
                ),
                _buildServiceTile(
                  context,
                  'Drivers',
                  Icons.person_add,
                  Colors.blue,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DriverManagementScreen()),
                    );
                    // Refresh dashboard when returning
                    if (context.mounted) {
                      final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                      dashboardState?._refreshDashboard();
                    }
                  },
                ),
                _buildServiceTile(
                  context,
                  'Routes',
                  Icons.route,
                  Colors.green,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route Management coming soon!')),
                  ),
                ),
                _buildServiceTile(
                  context,
                  'Devices',
                  Icons.device_hub,
                  Colors.orange,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Device Management coming soon!')),
                  ),
                ),
                _buildServiceTile(
                  context,
                  'Notifications',
                  Icons.notifications,
                  Colors.purple,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification Center coming soon!')),
                  ),
                ),
                _buildServiceTile(
                  context,
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings Management coming soon!')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
