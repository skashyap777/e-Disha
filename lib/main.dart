import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:edisha/providers/theme_provider.dart';
import 'package:edisha/services/settings_service.dart';
import 'package:edisha/theme/app_colors.dart';
import 'package:edisha/theme/theme.dart';
import 'package:edisha/screens/splash_screen.dart';
import 'package:edisha/screens/login_page.dart';
import 'package:edisha/screens/dashboard_screen.dart';
import 'package:edisha/screens/terms_and_conditions_screen.dart';
import 'package:edisha/screens/map_screen.dart';
import 'package:edisha/screens/placeholder_screen.dart';
import 'package:edisha/screens/alert_page.dart'; // Import for AlertPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardScreen(),
        '/terms': (context) => const TermsAndConditionsScreen(),
        '/splash': (context) => const SplashScreen(),
        '/route-fixing': (context) =>
            const PlaceholderScreen(title: 'Route Fixing'),
        '/live-tracking': (context) =>
            const PlaceholderScreen(title: 'Live Tracking'),
        '/history': (context) => const PlaceholderScreen(title: 'History'),
        '/vehicle-details': (context) =>
            const PlaceholderScreen(title: 'Vehicle Details'),
        '/add-driver': (context) =>
            const PlaceholderScreen(title: 'Add Driver'),
        '/reports': (context) => const PlaceholderScreen(title: 'Reports'),
        '/map': (context) => const MapScreen(),
        '/alert-page': (context) =>
            const AlertPage(), // Added route for AlertPage (removed const)
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