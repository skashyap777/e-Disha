// dashboard_screen.dart
// Complete professional Flutter dashboard with modern UI, responsive design,
// proper error handling, state management, and clean architecture for 2025

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:edisha/providers/theme_provider.dart';
import 'package:edisha/screens/alert_page.dart';
import 'package:edisha/theme/app_colors.dart';
import 'package:flutter/foundation.dart';

enum LoadingState { idle, loading, success, error }

class DashboardProvider extends ChangeNotifier {
  LoadingState _loadingState = LoadingState.idle;
  Map<String, dynamic> _dashboardData = {};
  String? _error;
  DateTime? _lastUpdated;

  LoadingState get loadingState => _loadingState;
  Map<String, dynamic> get dashboardData => _dashboardData;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get hasData => _dashboardData.isNotEmpty;

  Future<void> fetchDashboardData() async {
    _loadingState = LoadingState.loading;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      _dashboardData = {
        'vehicles': {'total': 15, 'active': 12, 'inactive': 3},
        'emergency': {'genuine': 60, 'fake': 25, 'total': 85},
        // ... rest of data
      };

      _lastUpdated = DateTime.now();
      _loadingState = LoadingState.success;
    } catch (e) {
      _error = e.toString();
      _loadingState = LoadingState.error;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _loadingState = LoadingState.idle;
    notifyListeners();
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 2;
  bool _isLoading = false;
  bool _hasError = false;
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  bool _isTablet = false;

  // Sample dashboard data (move to provider in production)
  final Map<String, dynamic> _dashboardData = {
    'vehicles': {'total': 15, 'active': 12, 'inactive': 3},
    'emergency': {'genuine': 60, 'fake': 25, 'total': 85},
    'alerts': {'thisMonth': 8, 'today': 2, 'total': 164},
    'health': {
      'totalActivated': 12,
      'activatedToday': 3,
      'inactive7Days': 1,
      'inactive30Days': 2,
    },
    'driver': {'harshBraking': 2, 'suddenTurn': 1, 'overspeeding': 5},
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refreshDashboard());
  }

  Future<void> _refreshDashboard() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
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
        Navigator.pushNamed(context, '/history');
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
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged out'),
              backgroundColor: Color.fromARGB(213, 50, 230, 50),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: const ValueKey('dashboard-scaffold'),
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      bottomNavigationBar: _buildBottomNavigation(context),
      body: _hasError
          ? _buildErrorState(context)
          : RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: colorScheme.primary,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  _isTablet = constraints.maxWidth > 600;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        _QuickStats(
                          data: _dashboardData,
                          animation: _animationController,
                          theme: theme,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Analytics Overview',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        _isTablet ? _buildTabletGrid() : _buildMobileList(),
                      ].map((w) => w.animate().fadeIn()).toList(),
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
      backgroundColor: theme.cardColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'lib/assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.dashboard_rounded,
                size: 32,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            size: 24,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        // Theme toggle button
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  final provider =
                      Provider.of<ThemeProvider>(context, listen: false);
                  provider.setThemeMode(
                    provider.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                  );
                },
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              ),
            );
          },
        ),
        // Notifications button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.2),
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
                      );
                    },
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertPage()),
              );
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
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
            color: theme.cardColor,
            onSelected: (String result) {
              if (result == 'logout') {
                _performLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'welcome',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Test owner I',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '1000000007',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: colorScheme.error),
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
      backgroundColor: theme.cardColor,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Image.asset(
                'lib/assets/images/logo.png',
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
                    Icons.dashboard, 'Dashboard', () => Navigator.pop(context)),
                _DrawerItem(Icons.route_outlined, 'Route Fixing', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/route-fixing');
                }),
                _DrawerItem(Icons.gps_fixed, 'Live Tracking', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/live-tracking');
                }),
                _DrawerItem(Icons.history, 'History Playback', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/history');
                }),
                _DrawerItem(Icons.person_add, 'Add Driver', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/add-driver');
                }),
                _DrawerItem(Icons.notifications_active, 'Alerts', () {
                  // Added Alert button
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/alert-page');
                }),
                _DrawerItem(Icons.description, 'Reports', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reports');
                }),
                _DrawerItem(Icons.map, 'Map View', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/map');
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
                color: colorScheme.onSurface.withOpacity(0.7),
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
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: colorScheme.primary,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.alt_route_outlined),
                activeIcon: Icon(Icons.alt_route),
                label: 'Routes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.gps_not_fixed_outlined),
                activeIcon: Icon(Icons.gps_fixed),
                label: 'Live',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: _buildDashboardCards()
          .map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card.animate().fadeIn(),
              ))
          .toList(),
    );
  }

  Widget _buildTabletGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _buildDashboardCards()
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

  List<Widget> _buildDashboardCards() {
    return [
      FadeTransition(
        opacity: _animationController,
        child: _VehicleCard(data: _dashboardData['vehicles']),
      ),
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: _EmergencyCard(data: _dashboardData['emergency']),
      ),
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: _AlertsCard(data: _dashboardData['alerts']),
      ),
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: _HealthCard(data: _dashboardData['health']),
      ),
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: _DriverCard(data: _dashboardData['driver']),
      ),
    ];
  }
}

// ----------------------------------------------------------------------------
// SUPPORTING WIDGETS
// ----------------------------------------------------------------------------

// Drawer Item Widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem(this.icon, this.title, this.onTap);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      onTap: onTap,
    );
  }
}

// Quick Stats Header Widget
class _QuickStats extends StatelessWidget {
  final Map<String, dynamic> data;
  final AnimationController animation;
  final ThemeData theme;

  const _QuickStats({
    required this.data,
    required this.animation,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.speed, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Fleet Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    'Active Vehicles',
                    '${data['vehicles']['active']}',
                    Icons.directions_car,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _StatItem('Total Alerts', '${data['alerts']['total']}',
                      Icons.warning),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _StatItem('SOS Calls', '${data['emergency']['total']}',
                      Icons.emergency),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Enhanced VEHICLE STATUS CARD
class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VehicleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/vehicle-details'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vehicle Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '${data['total']}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Vehicles',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: data['active'] / data['total'],
                  backgroundColor: colorScheme.outline.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusItem(
                      context, 'Active', data['active'], Colors.green),
                  _buildStatusItem(context, 'Inactive', data['inactive'],
                      colorScheme.onSurface.withOpacity(0.7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(
      BuildContext context, String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// Enhanced EMERGENCY ALERT CARD
class _EmergencyCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const _EmergencyCard({required this.data});

  @override
  State<_EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<_EmergencyCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Emergency Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        centerSpaceRadius: 25,
                        sectionsSpace: 2,
                        sections: [
                          PieChartSectionData(
                            color: const Color.fromARGB(213, 50, 230, 50),
                            value: widget.data['genuine'].toDouble(),
                            title: touchedIndex == 0
                                ? '${widget.data['genuine']}'
                                : '',
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: touchedIndex == 0 ? 35 : 30,
                          ),
                          PieChartSectionData(
                            color: colorScheme.error,
                            value: widget.data['fake'].toDouble(),
                            title: touchedIndex == 1
                                ? '${widget.data['fake']}'
                                : '',
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: touchedIndex == 1 ? 35 : 30,
                          ),
                        ],
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 200),
                      swapAnimationCurve: Curves.easeInOut,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.data['total']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Total SOS Calls',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLegendItem(
                          context,
                          const Color.fromARGB(213, 50, 230, 50),
                          'Genuine',
                          widget.data['genuine']),
                      const SizedBox(height: 8),
                      _buildLegendItem(context, colorScheme.error,
                          'False Alarm', widget.data['fake']),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      BuildContext context, Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// Enhanced ALERTS CARD
class _AlertsCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AlertsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'System Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAlertRow(context, 'Today', data['today'], Icons.today),
            const SizedBox(height: 12),
            _buildAlertRow(
                context, 'This Month', data['thisMonth'], Icons.calendar_month),
            const SizedBox(height: 12),
            _buildAlertRow(context, 'Total', data['total'], Icons.history,
                isHighlighted: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertRow(
      BuildContext context, String label, int value, IconData icon,
      {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primary.withOpacity(0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: colorScheme.primary.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isHighlighted
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$value',
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
}

// Enhanced HEALTH CARD
class _HealthCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HealthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        const Color.fromARGB(213, 50, 230, 50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Color.fromARGB(213, 50, 230, 50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Health Monitoring',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHealthRow(
                context, 'Active Today', data['activatedToday'], Icons.today),
            const SizedBox(height: 12),
            _buildHealthRow(context, 'Total Active', data['totalActivated'],
                Icons.monitor_heart),
            const SizedBox(height: 12),
            _buildHealthRow(context, '7 Days Inactive', data['inactive7Days'],
                Icons.schedule),
            const SizedBox(height: 12),
            _buildHealthRow(context, '30 Days Inactive', data['inactive30Days'],
                Icons.warning_amber),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRow(
      BuildContext context, String label, int value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getStatusColor() {
      if (label.contains('Inactive')) {
        return value > 0
            ? const Color.fromARGB(255, 252, 107, 39)
            : const Color.fromARGB(213, 50, 230, 50);
      }
      return value > 0
          ? const Color.fromARGB(213, 50, 230, 50)
          : colorScheme.onSurface.withOpacity(0.7);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$value',
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
}

// Enhanced DRIVER CARD
class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DriverCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/vehicle-details'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Driver Behavior',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDriverRow(context, 'Harsh Braking', data['harshBraking'],
                  Icons.warning),
              const SizedBox(height: 12),
              _buildDriverRow(context, 'Sudden Turns', data['suddenTurn'],
                  Icons.turn_sharp_left),
              const SizedBox(height: 12),
              _buildDriverRow(
                  context, 'Overspeeding', data['overspeeding'], Icons.speed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverRow(
      BuildContext context, String label, int value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getSeverityColor() {
      if (value == 0) return const Color.fromARGB(213, 50, 230, 50);
      if (value <= 2) return const Color.fromARGB(255, 252, 107, 39);
      return const Color(0xFFEF4444);
    }

    String getSeverityLabel() {
      if (value == 0) return 'Good';
      if (value <= 2) return 'Fair';
      return 'Poor';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
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
                    color: colorScheme.onSurface,
                  ),
                ),
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
              '$value',
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
}
