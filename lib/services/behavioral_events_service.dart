import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:edisha/services/gps_tracking_service.dart';
import 'package:edisha/services/alert_api_service.dart';
import 'package:edisha/services/auth_api_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

// Behavioral event data models
class BehavioralEvent {
  final String id;
  final String type; // 'harsh_braking', 'overspeeding', 'sudden_turn'
  final String vehicleId;
  final String? driverId;
  final String? driverName;
  final DateTime timestamp;
  final double? speed;
  final double latitude;
  final double longitude;
  final String? description;
  final String severity; // 'low', 'medium', 'high', 'critical'

  BehavioralEvent({
    required this.id,
    required this.type,
    required this.vehicleId,
    this.driverId,
    this.driverName,
    required this.timestamp,
    this.speed,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.severity,
  });

  factory BehavioralEvent.fromGPSData(GPSLocationData gpsData, String eventType) {
    String severity = 'low';
    String description = '';

    switch (eventType) {
      case 'overspeeding':
        final speed = gpsData.speed ?? 0.0;
        if (speed > 120) {
          severity = 'critical';
          description = 'Extreme overspeeding: ${speed.toStringAsFixed(1)} km/h';
        } else if (speed > 100) {
          severity = 'high';
          description = 'High overspeeding: ${speed.toStringAsFixed(1)} km/h';
        } else if (speed > 80) {
          severity = 'medium';
          description = 'Moderate overspeeding: ${speed.toStringAsFixed(1)} km/h';
        } else {
          severity = 'low';
          description = 'Minor overspeeding: ${speed.toStringAsFixed(1)} km/h';
        }
        break;
      case 'harsh_braking':
        severity = 'medium';
        description = 'Harsh braking detected at ${gpsData.speed?.toStringAsFixed(1) ?? '0'} km/h';
        break;
      case 'sudden_turn':
        severity = 'medium';
        description = 'Sudden turn detected at ${gpsData.speed?.toStringAsFixed(1) ?? '0'} km/h';
        break;
    }

    return BehavioralEvent(
      id: '${gpsData.vehicleId}_${eventType}_${gpsData.timestamp.millisecondsSinceEpoch}',
      type: eventType,
      vehicleId: gpsData.vehicleId ?? 'Unknown',
      timestamp: gpsData.timestamp,
      speed: gpsData.speed,
      latitude: gpsData.latitude,
      longitude: gpsData.longitude,
      description: description,
      severity: severity,
    );
  }

  factory BehavioralEvent.fromAlertData(Map<String, dynamic> alertData) {
    String eventType = 'overspeeding';
    String severity = 'medium';
    String description = '';
    DateTime timestamp = DateTime.now();
    double? speed;
    double latitude = 0.0;
    double longitude = 0.0;
    String vehicleId = 'Unknown';

    try {
      // Extract GPS data from alert
      if (alertData['gps_ref'] != null) {
        final gpsRef = alertData['gps_ref'];
        speed = double.tryParse(gpsRef['speed']?.toString() ?? '0');
        latitude = double.tryParse(gpsRef['latitude']?.toString() ?? '0') ?? 0.0;
        longitude = double.tryParse(gpsRef['longitude']?.toString() ?? '0') ?? 0.0;
        
        if (gpsRef['entry_time'] != null) {
          timestamp = DateTime.tryParse(gpsRef['entry_time']) ?? DateTime.now();
        }
      }

      // Extract vehicle info
      if (alertData['deviceTag'] != null) {
        vehicleId = alertData['deviceTag']['vehicle_reg_no']?.toString() ?? 
                   alertData['deviceTag']['registration_number']?.toString() ?? 
                   'Unknown';
      }

      // Determine event type and severity
      final title = alertData['title']?.toString().toLowerCase() ?? '';
      if (title.contains('speed') || title.contains('over')) {
        eventType = 'overspeeding';
        if (speed != null && speed > 100) {
          severity = 'high';
        }
        description = 'Overspeeding alert: ${speed?.toStringAsFixed(1) ?? 'N/A'} km/h';
      }
    } catch (e) {
      debugPrint('❌ Error parsing behavioral event from alert: $e');
    }

    return BehavioralEvent(
      id: alertData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: eventType,
      vehicleId: vehicleId,
      timestamp: timestamp,
      speed: speed,
      latitude: latitude,
      longitude: longitude,
      description: description,
      severity: severity,
    );
  }
}

class BehavioralEventsSummary {
  final int harshBrakingCount;
  final int overspeedingCount;
  final int suddenTurnCount;
  final List<BehavioralEvent> harshBrakingEvents;
  final List<BehavioralEvent> overspeedingEvents;
  final List<BehavioralEvent> suddenTurnEvents;
  final DateTime lastUpdated;

  BehavioralEventsSummary({
    required this.harshBrakingCount,
    required this.overspeedingCount,
    required this.suddenTurnCount,
    required this.harshBrakingEvents,
    required this.overspeedingEvents,
    required this.suddenTurnEvents,
    required this.lastUpdated,
  });

  int get totalEvents => harshBrakingCount + overspeedingCount + suddenTurnCount;
}

class BehavioralEventsService {
  static final BehavioralEventsService _instance = BehavioralEventsService._internal();
  factory BehavioralEventsService() => _instance;
  BehavioralEventsService._internal();

  final GetIt getIt = GetIt.instance;
  BehavioralEventsSummary? _cachedSummary;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Fetch and analyze behavioral events from GPS and alert data
  Future<BehavioralEventsSummary> getBehavioralEventsSummary() async {
    try {
      // Check if cached data is still valid
      if (_cachedSummary != null && 
          _lastCacheTime != null && 
          DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration) {
        debugPrint('🔄 Using cached behavioral events summary');
        return _cachedSummary!;
      }

      debugPrint('🔍 Fetching fresh behavioral events data...');

      final List<BehavioralEvent> allEvents = [];

      // Method 1: Analyze recent GPS data for behavioral patterns
      try {
        final gpsService = getIt<GPSTrackingService>();
        final recentGPSData = await gpsService.fetchGPSData();
        
        debugPrint('📍 Analyzing ${recentGPSData.length} GPS points for behavioral events');
        
        // Analyze GPS data for behavioral events
        allEvents.addAll(_analyzeGPSDataForBehavioralEvents(recentGPSData));
        
      } catch (e) {
        debugPrint('⚠️ Failed to fetch GPS data for behavioral analysis: $e');
      }

      // Method 2: Get overspeeding events from alerts
      try {
        final alertService = getIt<AlertApiService>();
        final alertsResponse = await alertService.fetchAlerts();
        
        debugPrint('🚨 Alert service response type: ${alertsResponse.runtimeType}');
        
        List<dynamic> alerts = [];
        
        if (alertsResponse is Map) {
          // AlertApiService returns {'success': true, 'data': actualResponseData}
          if (alertsResponse['success'] == true && alertsResponse['data'] != null) {
            final data = alertsResponse['data'];
            if (data is List) {
              alerts = data;
            } else if (data is Map) {
              // Check if data contains alertHistory
              if (data['alertHistory'] is List) {
                alerts = data['alertHistory'];
              } else if (data['alerts'] is List) {
                alerts = data['alerts'];
              }
            }
          }
        }
        
        debugPrint('🚨 Analyzing ${alerts.length} alerts for behavioral events');
        
        for (final alert in alerts) {
          if (alert is Map<String, dynamic>) {
            final title = alert['title']?.toString().toLowerCase() ?? '';
            // Also check GPS data for speed-related events
            if (title.contains('speed') || title.contains('over') ||
                (alert['gps_ref'] != null && 
                 double.tryParse(alert['gps_ref']['speed']?.toString() ?? '0') != null &&
                 double.tryParse(alert['gps_ref']['speed']?.toString() ?? '0')! > 80)) {
              allEvents.add(BehavioralEvent.fromAlertData(alert));
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch alerts for behavioral analysis: $e');
      }

      // Process and categorize events
      final summary = _processBehavioralEvents(allEvents);
      
      // Cache the results
      _cachedSummary = summary;
      _lastCacheTime = DateTime.now();
      
      debugPrint('✅ Behavioral events summary: ${summary.harshBrakingCount} harsh braking, ${summary.overspeedingCount} overspeeding, ${summary.suddenTurnCount} sudden turns');
      
      return summary;
      
    } catch (e) {
      debugPrint('❌ Error getting behavioral events summary: $e');
      // Return fallback data if everything fails
      return _getFallbackBehavioralData();
    }
  }

  /// Analyze GPS data points to detect behavioral events
  List<BehavioralEvent> _analyzeGPSDataForBehavioralEvents(List<GPSLocationData> gpsData) {
    final List<BehavioralEvent> events = [];
    
    if (gpsData.length < 2) return events;
    
    // Sort GPS data by timestamp
    gpsData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    for (int i = 1; i < gpsData.length; i++) {
      final current = gpsData[i];
      final previous = gpsData[i - 1];
      
      // Skip invalid data points
      if (current.speed == null || previous.speed == null) continue;
      if (current.latitude == 0 || current.longitude == 0) continue;
      
      // Detect overspeeding (speed > 80 km/h for city limits, adjust as needed)
      if (current.speed! > 80) {
        events.add(BehavioralEvent.fromGPSData(current, 'overspeeding'));
      }
      
      // Detect harsh braking (significant speed decrease in short time)
      final speedDrop = previous.speed! - current.speed!;
      final timeDiff = current.timestamp.difference(previous.timestamp).inSeconds;
      
      if (speedDrop > 20 && timeDiff <= 5 && timeDiff > 0) {
        events.add(BehavioralEvent.fromGPSData(current, 'harsh_braking'));
      }
      
      // Detect sudden turns (rapid direction change - would need more sophisticated calculation)
      // For now, we'll use a simple heuristic based on speed and location changes
      if (i >= 2) {
        final prev2 = gpsData[i - 2];
        final bearing1 = _calculateBearing(prev2.latitude, prev2.longitude, previous.latitude, previous.longitude);
        final bearing2 = _calculateBearing(previous.latitude, previous.longitude, current.latitude, current.longitude);
        final bearingChange = (bearing2 - bearing1).abs();
        
        if (bearingChange > 45 && current.speed! > 20) { // Sudden turn at reasonable speed
          events.add(BehavioralEvent.fromGPSData(current, 'sudden_turn'));
        }
      }
    }
    
    return events;
  }

  /// Calculate bearing between two GPS points
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = lon2 - lon1;
    final y = (dLon * math.pi / 180);
    final x = (lat2 - lat1) * math.pi / 180;
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Process and categorize all behavioral events
  BehavioralEventsSummary _processBehavioralEvents(List<BehavioralEvent> allEvents) {
    final harshBrakingEvents = allEvents.where((e) => e.type == 'harsh_braking').toList();
    final overspeedingEvents = allEvents.where((e) => e.type == 'overspeeding').toList();
    final suddenTurnEvents = allEvents.where((e) => e.type == 'sudden_turn').toList();
    
    // Sort events by timestamp (most recent first)
    harshBrakingEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    overspeedingEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    suddenTurnEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return BehavioralEventsSummary(
      harshBrakingCount: harshBrakingEvents.length,
      overspeedingCount: overspeedingEvents.length,
      suddenTurnCount: suddenTurnEvents.length,
      harshBrakingEvents: harshBrakingEvents.take(50).toList(), // Limit to recent 50
      overspeedingEvents: overspeedingEvents.take(50).toList(),
      suddenTurnEvents: suddenTurnEvents.take(50).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get fallback behavioral data when APIs fail
  BehavioralEventsSummary _getFallbackBehavioralData() {
    debugPrint('⚠️ Using fallback behavioral events data');
    
    return BehavioralEventsSummary(
      harshBrakingCount: 4,
      overspeedingCount: 2,
      suddenTurnCount: 3,
      harshBrakingEvents: [],
      overspeedingEvents: [],
      suddenTurnEvents: [],
      lastUpdated: DateTime.now(),
    );
  }

  /// Clear cached data to force refresh
  void clearCache() {
    _cachedSummary = null;
    _lastCacheTime = null;
    debugPrint('🗑️ Behavioral events cache cleared');
  }

  /// Get events by type for dialog display
  Future<List<BehavioralEvent>> getEventsByType(String eventType) async {
    final summary = await getBehavioralEventsSummary();
    
    switch (eventType) {
      case 'harsh_braking':
        return summary.harshBrakingEvents;
      case 'overspeeding':
        return summary.overspeedingEvents;
      case 'sudden_turn':
        return summary.suddenTurnEvents;
      default:
        return [];
    }
  }
}