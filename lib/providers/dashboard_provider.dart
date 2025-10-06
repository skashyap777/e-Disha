import 'package:flutter/foundation.dart';
import '../services/cache_service.dart';
import '../services/alert_api_service.dart';
import '../services/driver_api_service.dart';
import '../services/gps_tracking_service.dart';

enum LoadingState { idle, loading, success, error }

/// Enhanced dashboard provider for managing vehicle tracking and fleet data
/// for e-Disha application with comprehensive state management
class DashboardProvider extends ChangeNotifier {
  LoadingState _loadingState = LoadingState.idle;
  Map<String, dynamic> _dashboardData = {};
  String? _error;
  DateTime? _lastUpdated;

  // Services
  final CacheService _cacheService = CacheService();
  final AlertApiService _alertService = AlertApiService();
  final DriverApiService _driverService = DriverApiService();
  final GPSTrackingService _gpsService = GPSTrackingService();

  // Getters
  LoadingState get loadingState => _loadingState;
  Map<String, dynamic> get dashboardData => _dashboardData;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get hasData => _dashboardData.isNotEmpty;

  /// Updates the dashboard data and notifies listeners.
  void updateData(Map<String, dynamic> newData) {
    _dashboardData = newData;
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  /// Fetches comprehensive dashboard data for fleet management
  Future<void> fetchDashboardData() async {
    _loadingState = LoadingState.loading;
    _error = null;
    notifyListeners();

    try {
      // Try to get cached data first
      final cachedData = await _cacheService.getCachedDashboardData();
      if (cachedData != null) {
        _dashboardData = cachedData;
        _loadingState = LoadingState.success;
        _lastUpdated = DateTime.now();
        notifyListeners();
      }

      // Fetch fresh data from services
      final results = await Future.wait([
        _fetchVehicleData(),
        _fetchAlertData(),
        _fetchDriverData(),
      ], eagerError: false);

      // Combine all data
      final vehicleData = results[0] as Map<String, dynamic>? ?? {};
      final alertData = results[1] as Map<String, dynamic>? ?? {};
      final driverData = results[2] as Map<String, dynamic>? ?? {};

      _dashboardData = {
        'vehicles': vehicleData,
        'alerts': alertData,
        'drivers': driverData,
        'analytics': _calculateAnalytics(vehicleData, alertData, driverData),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Cache the new data
      await _cacheService.cacheDashboardData(_dashboardData);

      _lastUpdated = DateTime.now();
      _loadingState = LoadingState.success;
    } catch (e) {
      _error = e.toString();
      _loadingState = LoadingState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Fetch vehicle tracking data with professional metrics
  Future<Map<String, dynamic>> _fetchVehicleData() async {
    try {
      final vehicles = await _gpsService.fetchGPSData();
      final totalVehicles = vehicles.length;
      final now = DateTime.now();
      
      // Active vehicles: GPS data received within last 30 minutes
      final activeVehicles = vehicles.where((vehicle) {
        final timeDiff = now.difference(vehicle.timestamp);
        return timeDiff.inMinutes <= 30;
      }).length;
      
      final inactiveVehicles = totalVehicles - activeVehicles;
      
      // Ignition ON: Active vehicles with ignition status = "1"
      final ignitionOnVehicles = vehicles.where((vehicle) {
        final timeDiff = now.difference(vehicle.timestamp);
        return timeDiff.inMinutes <= 30 && vehicle.isIgnitionOn;
      }).length;
      
      // Ignition OFF: Active vehicles with ignition status = "0"
      final ignitionOffVehicles = vehicles.where((vehicle) {
        final timeDiff = now.difference(vehicle.timestamp);
        return timeDiff.inMinutes <= 30 && !vehicle.isIgnitionOn;
      }).length;
      
      // Moving: Vehicles with speed > 0
      final movingVehicles = vehicles.where((vehicle) {
        final timeDiff = now.difference(vehicle.timestamp);
        return timeDiff.inMinutes <= 30 && (vehicle.speed ?? 0) > 0;
      }).length;
      
      // Idle: Ignition ON but speed = 0
      final idleVehicles = vehicles.where((vehicle) {
        final timeDiff = now.difference(vehicle.timestamp);
        return timeDiff.inMinutes <= 30 && 
               vehicle.isIgnitionOn && 
               (vehicle.speed ?? 0) == 0;
      }).length;
      
      // Stopped: Ignition OFF
      final stoppedVehicles = ignitionOffVehicles;

      return {
        'total': totalVehicles,
        'active': activeVehicles,
        'inactive': inactiveVehicles,
        'ignitionOn': ignitionOnVehicles,
        'ignitionOff': ignitionOffVehicles,
        'moving': movingVehicles,
        'idle': idleVehicles,
        'stopped': stoppedVehicles,
        'tracking': vehicles.map((v) {
          final timeDiff = now.difference(v.timestamp);
          final isActive = timeDiff.inMinutes <= 30;
          
          // Calculate professional vehicle status
          String status;
          if (!isActive) {
            status = 'Inactive';
          } else if (v.isIgnitionOn) {
            if ((v.speed ?? 0) > 0) {
              status = 'Moving';
            } else {
              status = 'Idle';
            }
          } else {
            status = 'Stopped';
          }
          
          return {
            'id': v.id,
            'vehicleId': v.vehicleId ?? v.id,
            'latitude': v.latitude,
            'longitude': v.longitude,
            'speed': v.speed,
            'ignition': v.ignitionStatus,
            'ignitionOn': v.isIgnitionOn,
            'status': status,
            'timestamp': v.timestamp.toIso8601String(),
            'isActive': isActive,
          };
        }).toList(),
      };
    } catch (e) {
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'ignitionOn': 0,
        'ignitionOff': 0,
        'moving': 0,
        'idle': 0,
        'stopped': 0,
        'tracking': [],
        'error': e.toString(),
      };
    }
  }

  /// Fetch alert data
  Future<Map<String, dynamic>> _fetchAlertData() async {
    try {
      final alertsResponse = await _alertService.fetchAlerts();
      final alerts = alertsResponse['data'] ?? [];
      
      final todayAlerts = alerts.where((alert) {
        final alertTime = DateTime.tryParse(alert['timestamp']?.toString() ?? '') ?? DateTime.now();
        final today = DateTime.now();
        return alertTime.year == today.year && 
               alertTime.month == today.month && 
               alertTime.day == today.day;
      }).length;

      final highPriorityAlerts = alerts.where((alert) => 
        alert['severity']?.toString().toLowerCase() == 'high' ||
        alert['severity']?.toString().toLowerCase() == 'critical'
      ).length;

      return {
        'total': alerts.length,
        'today': todayAlerts,
        'highPriority': highPriorityAlerts,
        'recent': alerts.take(10).toList(),
      };
    } catch (e) {
      return {
        'total': 0,
        'today': 0,
        'highPriority': 0,
        'recent': [],
        'error': e.toString(),
      };
    }
  }

  /// Fetch driver data
  Future<Map<String, dynamic>> _fetchDriverData() async {
    try {
      final driversResponse = await _driverService.getTagOwnerList();
      
      // Extract the data list from response
      List<dynamic> driversList = [];
      if (driversResponse['success'] == true && driversResponse.containsKey('data')) {
        final data = driversResponse['data'];
        if (data is List) {
          driversList = data;
        } else if (data is Map) {
          // If data is a Map, it might contain a list of drivers
          // Try common keys
          if (data['drivers'] is List) {
            driversList = data['drivers'] as List;
          } else if (data['results'] is List) {
            driversList = data['results'] as List;
          }
        }
      }
      
      final activeDrivers = driversList.where((driver) {
        if (driver is Map) {
          return driver['status']?.toString().toLowerCase() == 'active';
        }
        return false;
      }).length;
      
      return {
        'total': driversList.length,
        'active': activeDrivers,
        'inactive': driversList.length - activeDrivers,
        'list': driversList.take(10).toList(),
      };
    } catch (e) {
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'list': [],
        'error': e.toString(),
      };
    }
  }

  /// Calculate analytics from combined data
  Map<String, dynamic> _calculateAnalytics(Map<String, dynamic> vehicleData, Map<String, dynamic> alertData, Map<String, dynamic> driverData) {
    final totalVehicles = vehicleData['total'] ?? 0;
    final activeVehicles = vehicleData['active'] ?? 0;
    final totalAlerts = alertData['total'] ?? 0;
    final totalDrivers = driverData['total'] ?? 0;
    
    final uptimePercentage = totalVehicles > 0 ? (activeVehicles / totalVehicles) * 100 : 0;
    
    return {
      'fleetUtilization': uptimePercentage.toStringAsFixed(1),
      'alertsPerVehicle': totalVehicles > 0 ? (totalAlerts / totalVehicles).toStringAsFixed(1) : '0',
      'driversPerVehicle': totalVehicles > 0 ? (totalDrivers / totalVehicles).toStringAsFixed(1) : '0',
      'systemHealth': uptimePercentage > 80 ? 'Good' : uptimePercentage > 60 ? 'Fair' : 'Poor',
    };
  }

  /// Gets vehicle data by type
  Map<String, dynamic>? getVehicleData() {
    return _dashboardData['vehicles'];
  }

  /// Gets alert metrics
  Map<String, dynamic>? getAlertData() {
    return _dashboardData['alerts'];
  }

  /// Gets driver data
  Map<String, dynamic>? getDriverData() {
    return _dashboardData['drivers'];
  }

  /// Gets analytics data
  Map<String, dynamic>? getAnalytics() {
    return _dashboardData['analytics'];
  }

  /// Clears error state
  void clearError() {
    _error = null;
    _loadingState = LoadingState.idle;
    notifyListeners();
  }

  /// Refreshes dashboard data
  Future<void> refreshData() async {
    await fetchDashboardData();
  }

  /// Updates vehicle status
  void updateVehicleStatus(String vehicleId, String status) {
    // TODO: Implement vehicle status update API call
    if (_dashboardData.containsKey('vehicles')) {
      final vehicles = _dashboardData['vehicles']['tracking'] as List;
      final vehicleIndex = vehicles.indexWhere((v) => v['id'] == vehicleId);
      if (vehicleIndex != -1) {
        vehicles[vehicleIndex]['status'] = status;
        notifyListeners();
      }
    }
  }

  /// Acknowledges an alert
  void acknowledgeAlert(String alertId) {
    // TODO: Implement alert acknowledgment API call
    if (_dashboardData.containsKey('alerts')) {
      final alerts = _dashboardData['alerts']['recent'] as List;
      final alertIndex = alerts.indexWhere((a) => a['id'] == alertId);
      if (alertIndex != -1) {
        alerts[alertIndex]['acknowledged'] = true;
        notifyListeners();
      }
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
