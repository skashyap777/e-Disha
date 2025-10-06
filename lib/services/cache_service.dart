import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service class for caching data locally in e-Disha app
class CacheService {
  static const Duration _defaultTtl = Duration(minutes: 30);
  static const String _timestampSuffix = '_timestamp';

  /// Cache data with TTL (Time To Live)
  Future<void> cacheData(String key, dynamic data, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(key, jsonData);
      await prefs.setInt(key + _timestampSuffix, timestamp);
    } catch (e) {
      // Handle error silently to avoid disrupting app flow
      print('[CacheService] Cache write error for key $key: $e');
    }
  }

  /// Get cached data if not expired
  Future<T?> getCachedData<T>(String key, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(key);
      final timestamp = prefs.getInt(key + _timestampSuffix);

      if (jsonData == null || timestamp == null) {
        return null;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = cacheTime.add(ttl ?? _defaultTtl);

      if (DateTime.now().isAfter(expiryTime)) {
        // Cache expired, remove it
        await clearCache(key);
        return null;
      }

      return jsonDecode(jsonData) as T;
    } catch (e) {
      print('[CacheService] Cache read error for key $key: $e');
      return null;
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid(String key, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(key + _timestampSuffix);

      if (timestamp == null) {
        return false;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = cacheTime.add(ttl ?? _defaultTtl);

      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove(key + _timestampSuffix);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.endsWith(_timestampSuffix) ||
            keys.contains(key + _timestampSuffix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Cache vehicle data
  Future<void> cacheVehicleData(Map<String, dynamic> data) async {
    await cacheData('vehicle_data', data, ttl: const Duration(minutes: 10));
  }

  /// Get cached vehicle data
  Future<Map<String, dynamic>?> getCachedVehicleData() async {
    return await getCachedData<Map<String, dynamic>>('vehicle_data');
  }

  /// Cache dashboard data
  Future<void> cacheDashboardData(Map<String, dynamic> data) async {
    await cacheData('dashboard_data', data, ttl: const Duration(minutes: 5));
  }

  /// Get cached dashboard data
  Future<Map<String, dynamic>?> getCachedDashboardData() async {
    return await getCachedData<Map<String, dynamic>>('dashboard_data');
  }

  /// Cache user profile
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await cacheData('user_profile', profile, ttl: const Duration(hours: 24));
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    return await getCachedData<Map<String, dynamic>>('user_profile');
  }

  /// Cache alert data
  Future<void> cacheAlertData(List<Map<String, dynamic>> alerts) async {
    await cacheData('alert_data', alerts, ttl: const Duration(minutes: 3));
  }

  /// Get cached alert data
  Future<List<Map<String, dynamic>>?> getCachedAlertData() async {
    final data = await getCachedData<List<dynamic>>('alert_data');
    return data?.cast<Map<String, dynamic>>();
  }

  /// Cache driver data
  Future<void> cacheDriverData(List<Map<String, dynamic>> drivers) async {
    await cacheData('driver_data', drivers, ttl: const Duration(minutes: 15));
  }

  /// Get cached driver data
  Future<List<Map<String, dynamic>>?> getCachedDriverData() async {
    final data = await getCachedData<List<dynamic>>('driver_data');
    return data?.cast<Map<String, dynamic>>();
  }

  /// Cache route data
  Future<void> cacheRouteData(List<Map<String, dynamic>> routes) async {
    await cacheData('route_data', routes, ttl: const Duration(hours: 1));
  }

  /// Get cached route data
  Future<List<Map<String, dynamic>>?> getCachedRouteData() async {
    final data = await getCachedData<List<dynamic>>('route_data');
    return data?.cast<Map<String, dynamic>>();
  }

  /// Cache settings
  Future<void> cacheSettings(Map<String, dynamic> settings) async {
    await cacheData('app_settings', settings, ttl: const Duration(days: 7));
  }

  /// Get cached settings
  Future<Map<String, dynamic>?> getCachedSettings() async {
    return await getCachedData<Map<String, dynamic>>('app_settings');
  }

  /// Get cache size (approximate)
  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int size = 0;
      
      for (final key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          size += value.length;
        }
      }
      
      return size;
    } catch (e) {
      return 0;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int totalKeys = 0;
      int dataKeys = 0;
      int timestampKeys = 0;
      int expiredKeys = 0;
      
      for (final key in keys) {
        totalKeys++;
        if (key.endsWith(_timestampSuffix)) {
          timestampKeys++;
        } else {
          dataKeys++;
          
          // Check if expired
          final timestamp = prefs.getInt(key + _timestampSuffix);
          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final expiryTime = cacheTime.add(_defaultTtl);
            if (DateTime.now().isAfter(expiryTime)) {
              expiredKeys++;
            }
          }
        }
      }
      
      return {
        'totalKeys': totalKeys,
        'dataKeys': dataKeys,
        'timestampKeys': timestampKeys,
        'expiredKeys': expiredKeys,
        'size': await getCacheSize(),
      };
    } catch (e) {
      return {};
    }
  }

  // Backward compatibility methods
  static Future<void> cacheDashboardDataStatic(Map<String, dynamic> data) async {
    final service = CacheService();
    await service.cacheDashboardData(data);
  }

  static Future<Map<String, dynamic>?> getCachedDashboardDataStatic() async {
    final service = CacheService();
    return await service.getCachedDashboardData();
  }
}
