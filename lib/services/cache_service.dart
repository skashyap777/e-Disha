import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A service for caching dashboard data locally using SharedPreferences.
class CacheService {
  static const String _cacheKey = 'dashboard_data';

  /// Caches the provided dashboard data as a JSON string.
  ///
  /// TODO: In the future, replace or supplement this with API calls to sync data with the backend.
  static Future<void> cacheData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  /// Retrieves cached dashboard data, or null if not present or on error.
  ///
  /// TODO: In the future, fetch data from the backend API if cache is empty or stale.
  static Future<Map<String, dynamic>?> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) {
      return null;
    }
    try {
      return jsonDecode(cached);
    } catch (e) {
      // Handle potential JSON decoding errors
      print('Error decoding cached data: $e');
      return null;
    }
  }
}
