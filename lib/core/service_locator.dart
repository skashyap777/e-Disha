import 'package:get_it/get_it.dart';
import 'package:edisha/services/gps_tracking_service.dart';
import 'package:edisha/services/auth_api_service.dart';
import 'package:edisha/services/device_service.dart';
import 'package:edisha/services/route_service.dart';
import 'package:edisha/services/settings_service.dart';
import 'package:edisha/services/notification_service.dart';
import 'package:edisha/services/driver_api_service.dart';
import 'package:edisha/services/alert_api_service.dart';
import 'package:edisha/services/cache_service.dart';
import 'package:edisha/services/behavioral_events_service.dart';
import 'package:edisha/services/notification_api_service.dart';

final getIt = GetIt.instance;

/// Initialize all e-Disha services as singletons
/// Call this method in main() before runApp()
Future<void> setupEDishaServices() async {
  // Core e-Disha Services - Lazy Singletons (created when first requested)
  getIt.registerLazySingleton<GPSTrackingService>(() => GPSTrackingService());
  getIt.registerLazySingleton<AuthApiService>(() => AuthApiService());
  getIt.registerLazySingleton<DeviceService>(() => DeviceService());
  getIt.registerLazySingleton<RouteService>(() => RouteService());
  getIt.registerLazySingleton<SettingsService>(() => SettingsService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<DriverApiService>(() => DriverApiService());
  getIt.registerLazySingleton<AlertApiService>(() => AlertApiService());
  getIt.registerLazySingleton<CacheService>(() => CacheService());
  getIt.registerLazySingleton<BehavioralEventsService>(() => BehavioralEventsService());
  getIt.registerLazySingleton<NotificationApiService>(() => NotificationApiService());

  print('✅ e-Disha Service Locator initialized successfully');
}

/// Clean up all e-Disha services when app is closing
Future<void> disposeEDishaServices() async {
  // Dispose services that need cleanup
  if (getIt.isRegistered<GPSTrackingService>()) {
    final gpsService = getIt<GPSTrackingService>();
    // Stop any ongoing GPS tracking
    // gpsService.stopRealTimeTracking(); // Uncomment if method exists
  }
  
  if (getIt.isRegistered<CacheService>()) {
    final cacheService = getIt<CacheService>();
    // Clear cache if needed
    // await cacheService.clearAll(); // Uncomment if method exists
  }
  
  await getIt.reset();
  print('✅ All e-Disha services disposed');
}

/// Helper function to get services easily
/// Usage: getEDishaService<GPSTrackingService>()
T getEDishaService<T extends Object>() => getIt<T>();

/// Check if a service is registered
bool isEDishaServiceRegistered<T extends Object>() => getIt.isRegistered<T>();