import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edisha/services/auth_api_service.dart';
import 'package:edisha/services/alert_api_service.dart';
import 'package:edisha/core/service_locator.dart';
import 'package:flutter/foundation.dart';

// Notification data model
class NotificationData {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'success', 'error'
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  NotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.actionUrl,
    this.metadata,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? json['subject']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? json['body']?.toString() ?? json['content']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? json['priority']?.toString().toLowerCase() ?? 'info',
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true || json['read_status'] == true || json['status']?.toString() == 'read',
      actionUrl: json['action_url']?.toString() ?? json['url']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Create notifications from various app events
  factory NotificationData.fromDeviceEvent(String deviceId, String eventType, Map<String, dynamic> data) {
    String title = 'Device Event';
    String message = 'Device event occurred';
    String type = 'info';

    switch (eventType) {
      case 'device_online':
        title = 'Device Online';
        message = 'Device $deviceId is now online';
        type = 'success';
        break;
      case 'device_offline':
        title = 'Device Offline';
        message = 'Device $deviceId has gone offline';
        type = 'warning';
        break;
      case 'low_battery':
        title = 'Low Battery';
        message = 'Device $deviceId has low battery (${data['battery_level'] ?? 'N/A'}%)';
        type = 'warning';
        break;
      case 'maintenance_due':
        title = 'Maintenance Due';
        message = 'Vehicle ${data['vehicle_id'] ?? deviceId} is due for maintenance';
        type = 'info';
        break;
    }

    return NotificationData(
      id: '${deviceId}_${eventType}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      metadata: data,
    );
  }

  factory NotificationData.fromSystemEvent(String eventType, String details) {
    String title = 'System Event';
    String type = 'info';

    switch (eventType) {
      case 'login_success':
        title = 'Login Successful';
        type = 'success';
        break;
      case 'data_sync':
        title = 'Data Synchronized';
        type = 'success';
        break;
      case 'connection_error':
        title = 'Connection Error';
        type = 'error';
        break;
      case 'update_available':
        title = 'Update Available';
        type = 'info';
        break;
    }

    return NotificationData(
      id: '${eventType}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: details,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  // Create notification from alert data
  factory NotificationData.fromAlertData(Map<String, dynamic> alert) {
    String title = 'Alert Notification';
    String message = 'Alert received';
    String type = 'warning';
    DateTime timestamp = DateTime.now();
    String vehicleId = 'Unknown Vehicle';

    try {
      // Extract vehicle information
      if (alert['deviceTag'] != null) {
        vehicleId = alert['deviceTag']['vehicle_reg_no']?.toString() ?? 
                   alert['deviceTag']['registration_number']?.toString() ?? 
                   'Unknown Vehicle';
      }

      // Extract GPS information for context
      if (alert['gps_ref'] != null) {
        final gpsRef = alert['gps_ref'];
        timestamp = DateTime.tryParse(gpsRef['entry_time']?.toString() ?? '') ?? DateTime.now();
        final speed = double.tryParse(gpsRef['speed']?.toString() ?? '0') ?? 0.0;
        final emergencyStatus = gpsRef['emergency_status']?.toString();
        final boxTamperAlert = gpsRef['box_tamper_alert']?.toString();
        final mainPowerStatus = gpsRef['main_power_status']?.toString();
        final ignitionStatus = gpsRef['ignition_status']?.toString();

        // Determine notification type and message based on alert conditions
        if (emergencyStatus == '1') {
          title = '🚨 Emergency Alert';
          message = 'Emergency button pressed on vehicle $vehicleId';
          type = 'error';
        } else if (boxTamperAlert != 'O') {
          title = '🔓 Tamper Alert';
          message = 'Device tamper detected on vehicle $vehicleId';
          type = 'error';
        } else if (mainPowerStatus == '0') {
          title = '🔌 Power Alert';
          message = 'Main power disconnected on vehicle $vehicleId';
          type = 'warning';
        } else if (speed > 80) {
          title = '⚡ Speed Alert';
          message = 'Vehicle $vehicleId is overspeeding at ${speed.toStringAsFixed(1)} km/h';
          type = 'warning';
        } else if (ignitionStatus == '1' && speed > 0) {
          title = '🚗 Vehicle Update';
          message = 'Vehicle $vehicleId is moving at ${speed.toStringAsFixed(1)} km/h';
          type = 'info';
        } else {
          title = '📍 Location Update';
          message = 'Location update received for vehicle $vehicleId';
          type = 'info';
        }
      } else {
        // Fallback for alerts without GPS data
        title = alert['title']?.toString() ?? 'Alert Notification';
        message = alert['message']?.toString() ?? 'Alert notification for vehicle $vehicleId';
        type = 'info';
      }
    } catch (e) {
      debugPrint('❌ Error creating notification from alert: $e');
    }

    return NotificationData(
      id: alert['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: false,
      metadata: alert,
    );
  }
}

class NotificationApiService {
  static const String baseUrl = 'https://api.gromed.in';
  static const String notificationEndpoint = '/api/notifications/';
  
  final AuthApiService _authApiService = AuthApiService();
  
  // Local storage for notifications (in real app, use SQLite or SharedPreferences)
  final List<NotificationData> _localNotifications = [];

  /// Fetch notifications from the Alert API (converted to notifications)
  Future<Map<String, dynamic>> fetchNotifications({int limit = 50}) async {
    try {
      debugPrint('📲 NOTIFICATION API: Fetching notifications from Alert API');
      
      // Get alert data from Alert API Service
      AlertApiService alertService;
      if (isEDishaServiceRegistered<AlertApiService>()) {
        alertService = getEDishaService<AlertApiService>();
      } else {
        alertService = AlertApiService();
      }
      
      final alertResponse = await alertService.fetchAlerts();
      
      if (alertResponse['success'] == true) {
        final alertData = alertResponse['data'];
        final notifications = _convertAlertsToNotifications(alertData);
        
        // Add some sample system notifications
        _generateSampleNotifications();
        
        // Merge alert-based notifications with local notifications
        final allNotifications = [...notifications, ..._localNotifications];
        allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        debugPrint('✅ Successfully converted ${notifications.length} alerts to notifications');
        debugPrint('📲 Total notifications: ${allNotifications.length}');
        
        return {
          'success': true, 
          'data': allNotifications,
          'total': allNotifications.length,
          'message': 'Notifications loaded from Alert API',
        };
      } else {
        // Fallback to local notifications only
        debugPrint('⚠️ Alert API failed, using local notifications only');
        _generateSampleNotifications();
        return {
          'success': true, 
          'data': _localNotifications,
          'total': _localNotifications.length,
          'message': 'Using local notifications - Alert API unavailable',
        };
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATION API ERROR: $e');
      // Fallback to local notifications and generate some sample data
      _generateSampleNotifications();
      return {
        'success': true, 
        'data': _localNotifications,
        'total': _localNotifications.length,
        'message': 'Using local notifications due to API error',
      };
    }
  }

  /// Convert alert data to notification format
  List<NotificationData> _convertAlertsToNotifications(dynamic alertData) {
    final List<NotificationData> notifications = [];
    
    try {
      List<dynamic> alerts = [];
      
      if (alertData is List) {
        alerts = alertData;
      } else if (alertData is Map) {
        if (alertData['alertHistory'] is List) {
          alerts = alertData['alertHistory'];
        } else if (alertData['alerts'] is List) {
          alerts = alertData['alerts'];
        } else if (alertData['data'] is List) {
          alerts = alertData['data'];
        }
      }
      
      debugPrint('📲 Converting ${alerts.length} alerts to notifications');
      
      for (var alert in alerts) {
        if (alert is Map<String, dynamic>) {
          try {
            final notification = NotificationData.fromAlertData(alert);
            notifications.add(notification);
          } catch (e) {
            debugPrint('⚠️ Error converting alert to notification: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _convertAlertsToNotifications: $e');
    }
    
    return notifications;
  }

  /// Parse notifications from API response
  List<NotificationData> _parseNotifications(dynamic data) {
    final List<NotificationData> notifications = [];
    
    if (data is List) {
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          notifications.add(NotificationData.fromJson(item));
        }
      }
    } else if (data is Map) {
      if (data['notifications'] is List) {
        for (var item in data['notifications']) {
          if (item is Map<String, dynamic>) {
            notifications.add(NotificationData.fromJson(item));
          }
        }
      } else if (data['data'] is List) {
        for (var item in data['data']) {
          if (item is Map<String, dynamic>) {
            notifications.add(NotificationData.fromJson(item));
          }
        }
      }
    }
    
    return notifications;
  }

  /// Add a local notification
  void addLocalNotification(NotificationData notification) {
    _localNotifications.add(notification);
    _localNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    debugPrint('📲 Added local notification: ${notification.title}');
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      // Update local notification
      final index = _localNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _localNotifications[index];
        _localNotifications[index] = NotificationData(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          timestamp: notification.timestamp,
          isRead: true,
          actionUrl: notification.actionUrl,
          metadata: notification.metadata,
        );
      }

      // TODO: Also update on server if API is available
      return true;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Get unread notification count
  int getUnreadCount() {
    return _localNotifications.where((n) => !n.isRead).length;
  }

  /// Generate sample notifications for demo
  void _generateSampleNotifications() {
    if (_localNotifications.isEmpty) {
      final sampleNotifications = [
        NotificationData.fromSystemEvent('login_success', 'You have successfully logged into e-Disha'),
        NotificationData.fromSystemEvent('data_sync', 'Vehicle data synchronized successfully'),
        NotificationData.fromDeviceEvent('AS01AC0139', 'device_online', {'vehicle_id': 'AS01AC0139'}),
        NotificationData.fromDeviceEvent('AS01AC0145', 'low_battery', {'battery_level': 15, 'vehicle_id': 'AS01AC0145'}),
        NotificationData.fromDeviceEvent('AS01AC0146', 'maintenance_due', {'vehicle_id': 'AS01AC0146', 'due_date': '2025-10-15'}),
        NotificationData.fromSystemEvent('update_available', 'A new version of e-Disha is available for download'),
      ];

      for (var notification in sampleNotifications) {
        addLocalNotification(notification);
      }
    }
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _localNotifications.clear();
    debugPrint('📲 All notifications cleared');
  }

  /// Get notifications by type
  List<NotificationData> getNotificationsByType(String type) {
    return _localNotifications.where((n) => n.type == type).toList();
  }
}