import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:edisha/providers/theme_provider.dart';
import 'package:edisha/providers/dashboard_provider.dart';
import 'package:edisha/services/settings_service.dart';
import 'package:edisha/theme/theme.dart';
import 'package:edisha/screens/splash_screen.dart';
import 'package:edisha/screens/login_screen.dart';
import 'package:edisha/screens/dashboard_screen.dart';
import 'package:edisha/screens/terms_and_conditions_screen.dart'; // Initial terms acceptance
import 'package:edisha/screens/terms_conditions_screen.dart'; // Terms page from login
import 'package:edisha/screens/privacy_policy_screen.dart';
import 'package:edisha/screens/map_screen.dart';
import 'package:edisha/screens/alert_page.dart'; // Import for AlertPage
import 'package:edisha/screens/live_tracking_screen.dart';
import 'package:edisha/screens/alert_management_screen.dart';
import 'package:edisha/screens/notification_screen.dart';
import 'package:edisha/screens/driver_management_screen.dart';
import 'package:edisha/screens/route_fixing_screen.dart';
import 'package:edisha/screens/vehicle_history_screen.dart';
import 'package:edisha/screens/route_history_screen.dart';
import 'package:edisha/screens/route_map_view_screen.dart';
import 'package:edisha/services/device_service.dart';
import 'package:edisha/services/route_service.dart';
import 'package:edisha/core/service_locator.dart';
import 'package:edisha/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize e-Disha service locator
  await setupEDishaServices();
  
  // Initialize FCM Service
  await FCMService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Disha',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/terms': (context) => const TermsConditionsScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/splash': (context) => const SplashScreen(),
        // '/live-tracking' route removed from here - now handled in onGenerateRoute
        '/history': (context) => const VehicleHistoryScreen(),
        '/vehicle-details': (context) =>
            const PlaceholderScreen(title: 'Vehicle Details'),
        '/add-driver': (context) => const DriverManagementScreen(),
        '/driver-management': (context) => const DriverManagementScreen(),
        '/alert-management': (context) => const AlertManagementScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/reports': (context) => const PlaceholderScreen(title: 'Reports'),
        '/map': (context) => const MapScreen(),
        '/alert-page': (context) =>
            const AlertPage(), // Added route for AlertPage (removed const)
      },
      onGenerateRoute: (settings) {
        // Handle routes that need arguments
        if (settings.name == '/live-tracking') {
          // Live tracking can accept optional openHistoryDialog parameter
          final args = settings.arguments as Map<String, dynamic>?;
          final openHistoryDialog = args?['openHistoryDialog'] as bool? ?? false;
          return MaterialPageRoute(
            builder: (context) => LiveTrackingScreen(openHistoryDialog: openHistoryDialog),
          );
        } else if (settings.name == '/vehicle-route-history') {
          final vehicle = settings.arguments as DeviceOwnerData?;
          if (vehicle != null) {
            return MaterialPageRoute(
              builder: (context) => RouteHistoryScreen(vehicle: vehicle),
            );
          }
        } else if (settings.name == '/route-map-view') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null &&
              args['vehicle'] != null &&
              args['route'] != null) {
            return MaterialPageRoute(
              builder: (context) => RouteMapViewScreen(
                vehicle: args['vehicle'] as DeviceOwnerData,
                route: args['route'] as RouteData,
              ),
            );
          }
        } else if (settings.name == '/route-fixing') {
          // Route fixing can accept optional vehicle parameter
          final vehicle = settings.arguments as DeviceOwnerData?;
          return MaterialPageRoute(
            builder: (context) => RouteFixingScreen(vehicle: vehicle),
          );
        }
        return null;
      },
      home: const AppInitializer(),
    );
  }
}

// Placeholder screen for all unimplemented features
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForTitle(title),
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '$title Screen',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                _getDescriptionForTitle(title),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Route Fixing':
        return Icons.route_outlined;
      case 'Live Tracking':
        return Icons.gps_fixed;
      case 'History':
        return Icons.history;
      case 'Vehicle Details':
        return Icons.directions_car_outlined;
      case 'Add Driver':
        return Icons.person_add_outlined;
      case 'Reports':
        return Icons.assessment_outlined;
      default:
        return Icons.dashboard_outlined;
    }
  }

  String _getDescriptionForTitle(String title) {
    switch (title) {
      case 'Route Fixing':
        return 'Create and manage predefined routes for your vehicles. Set waypoints, optimize paths, and assign routes to devices.';
      case 'History':
        return 'View historical tracking data, routes taken, and vehicle movement patterns over time.';
      case 'Reports':
        return 'Generate detailed reports on vehicle usage, driver behavior, alerts, and system performance.';
      case 'Vehicle Details':
        return 'View comprehensive information about your vehicles including specs, maintenance history, and current status.';
      default:
        return 'This feature will be available soon. We\'re working hard to bring you the best experience!';
    }
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = SettingsService();

    return FutureBuilder<bool>(
      future: settingsService.hasAcceptedTerms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  'Loading e-Disha',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we get ready',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and retry',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AppInitializer()),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else {
          final accepted = snapshot.data ?? false;
          if (accepted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
              );
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const TermsAndConditionsScreen()),
              );
            });
          }
          return Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          );
        }
      },
    );
  }
}
