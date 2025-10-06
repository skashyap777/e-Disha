import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// A service for managing user settings and preferences.
///
/// TODO: In the future, sync settings with backend APIs for multi-device support.
class SettingsService {
  static const String _vehicleTypeKey = 'vehicle_type';
  static const String _updateIntervalKey = 'update_interval';
  static const String _mapTypeKey = 'map_type';
  static const String _showTrafficKey = 'show_traffic';
  static const String _autoStartTrackingKey = 'auto_start_tracking';

  /// Checks if the user has accepted the terms.
  Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('acceptedTerms') ?? false;
  }

  /// Sets the user's acceptance of terms.
  Future<void> setAcceptedTerms(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', value);
  }

  // Vehicle Type Settings
  Future<String> getVehicleType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_vehicleTypeKey) ?? 'yellowCar';
    } catch (e) {
      debugPrint('Error getting vehicle type: $e');
      return 'yellowCar';
    }
  }

  Future<bool> setVehicleType(String vehicleType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_vehicleTypeKey, vehicleType);
    } catch (e) {
      debugPrint('Error setting vehicle type: $e');
      return false;
    }
  }

  // Update Interval Settings
  Future<int> getUpdateInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_updateIntervalKey) ?? 5; // Default 5 seconds
    } catch (e) {
      debugPrint('Error getting update interval: $e');
      return 5;
    }
  }

  Future<bool> setUpdateInterval(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_updateIntervalKey, seconds);
    } catch (e) {
      debugPrint('Error setting update interval: $e');
      return false;
    }
  }

  // Map Type Settings
  Future<String> getMapType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_mapTypeKey) ?? 'normal';
    } catch (e) {
      debugPrint('Error getting map type: $e');
      return 'normal';
    }
  }

  Future<bool> setMapType(String mapType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_mapTypeKey, mapType);
    } catch (e) {
      debugPrint('Error setting map type: $e');
      return false;
    }
  }

  // Traffic Settings
  Future<bool> getShowTraffic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showTrafficKey) ?? false;
    } catch (e) {
      debugPrint('Error getting show traffic setting: $e');
      return false;
    }
  }

  Future<bool> setShowTraffic(bool showTraffic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_showTrafficKey, showTraffic);
    } catch (e) {
      debugPrint('Error setting show traffic: $e');
      return false;
    }
  }

  // Auto Start Tracking Settings
  Future<bool> getAutoStartTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoStartTrackingKey) ?? true; // Default true
    } catch (e) {
      debugPrint('Error getting auto start tracking setting: $e');
      return true;
    }
  }

  Future<bool> setAutoStartTracking(bool autoStart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_autoStartTrackingKey, autoStart);
    } catch (e) {
      debugPrint('Error setting auto start tracking: $e');
      return false;
    }
  }

  // Check if this is the first time opening GPS tracking
  Future<bool> isFirstGPSLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirst = !prefs.containsKey(_vehicleTypeKey);
      if (isFirst) {
        // Set default values on first launch
        await setVehicleType('yellowCar');
        await setUpdateInterval(5);
        await setMapType('normal');
        await setShowTraffic(false);
        await setAutoStartTracking(true);
      }
      return isFirst;
    } catch (e) {
      debugPrint('Error checking first GPS launch: $e');
      return false;
    }
  }
}
