import 'package:flutter/material.dart';
import '../services/alert_api_service.dart';
import '../helpers/service_integration_helper.dart';
import '../theme/app_colors.dart';
import '../services/cache_service.dart';

class AlertData {
  final String id;
  final String title;
  final String description;
  final String severity;
  final DateTime timestamp;
  final String? deviceId;
  final String? vehicleId;
  final bool isRead;
  final String status;

  AlertData({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.deviceId,
    this.vehicleId,
    required this.isRead,
    required this.status,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    // Extract device and vehicle info from nested structure
    String? deviceId;
    String? vehicleId;
    String alertTitle = 'Alert';
    String alertDescription = '';
    DateTime timestamp = DateTime.now();
    
    try {
      // Get device info from deviceTag > device > id
      if (json['deviceTag'] != null && json['deviceTag']['device'] != null) {
        deviceId = json['deviceTag']['device']['id']?.toString();
        
        // Get vehicle registration number from deviceTag
        vehicleId = json['deviceTag']['vehicle_reg_no']?.toString() ??
            json['deviceTag']['registration_number']?.toString();
      }
      
      // Get GPS data for timestamp
      if (json['gps_ref'] != null && json['gps_ref']['entry_time'] != null) {
        timestamp = DateTime.tryParse(json['gps_ref']['entry_time']) ?? DateTime.now();
      }
      
      // Determine alert type and description based on GPS data
      if (json['gps_ref'] != null) {
        final gpsData = json['gps_ref'];
        
        // Check for various alert conditions
        if (gpsData['emergency_status'] == '1') {
          alertTitle = 'Emergency Alert';
          alertDescription = 'Emergency button pressed';
        } else if (gpsData['box_tamper_alert'] == 'C') {
          alertTitle = 'Tamper Alert';
          alertDescription = 'Device tamper detected';
        } else if (gpsData['main_power_status'] == '0') {
          alertTitle = 'Power Disconnected';
          alertDescription = 'Main power supply disconnected';
        } else if (gpsData['ignition_status'] != null) {
          final speed = double.tryParse(gpsData['speed']?.toString() ?? '0') ?? 0;
          if (speed > 80) {
            alertTitle = 'Over Speed Alert';
            alertDescription = 'Vehicle speed: ${speed.toStringAsFixed(1)} km/h';
          } else {
            alertTitle = 'Location Update';
            alertDescription = 'Speed: ${speed.toStringAsFixed(1)} km/h, Location: ${gpsData['latitude']}, ${gpsData['longitude']}';
          }
        }
      }
    } catch (e) {
      print('❌ Error extracting alert details: $e');
    }
    
    return AlertData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['alert_type']?.toString() ?? alertTitle,
      description: json['description']?.toString() ?? json['message']?.toString() ?? alertDescription,
      severity: json['severity']?.toString() ?? json['priority']?.toString() ?? _determineSeverity(alertTitle),
      timestamp: timestamp,
      deviceId: deviceId ?? json['device_id']?.toString(),
      vehicleId: vehicleId ?? json['vehicle_id']?.toString() ?? json['vehicle_registration_number']?.toString(),
      isRead: json['is_read'] == true || json['read_status'] == true,
      status: json['status']?.toString() ?? 'active',
    );
  }
  
  static String _determineSeverity(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('emergency')) return 'critical';
    if (titleLower.contains('tamper')) return 'high';
    if (titleLower.contains('power') || titleLower.contains('speed')) return 'medium';
    return 'low';
  }
}

class AlertManagementScreen extends StatefulWidget {
  const AlertManagementScreen({super.key});

  @override
  State<AlertManagementScreen> createState() => _AlertManagementScreenState();
}

class _AlertManagementScreenState extends State<AlertManagementScreen> 
    with TickerProviderStateMixin {
  final AlertApiService _alertApiService = AlertApiService();
  final ServiceIntegrationHelper _serviceHelper = ServiceIntegrationHelper();
  final CacheService _cacheService = CacheService();
  
  late AnimationController _animationController;
  late AnimationController _refreshController;
  
  List<AlertData> _alerts = [];
  List<AlertData> _filteredAlerts = [];
  String _searchQuery = '';
  String _severityFilter = 'all';
  String _statusFilter = 'all';
  bool _showOnlyUnread = false;

  static const String serviceName = 'alerts';

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _loadAlerts();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    _serviceHelper.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _loadAlerts() async {
    _refreshController.reset();
    _refreshController.forward();
    final result = await _serviceHelper.handleServiceCall<List<AlertData>>(
      serviceName,
      () => _alertApiService.fetchAlerts(),
      (data) {
        try {
          print('🔵 Alert parser called with data type: ${data.runtimeType}');
          List<dynamic> alertsList = [];
          
          if (data is List) {
            alertsList = data as List<dynamic>;
            print('✅ Data is a direct List with ${alertsList.length} items');
          } else if (data is Map) {
            print('📝 Data is a Map, checking for alert keys...');
            final dataMap = data as Map<String, dynamic>;
            
            // Priority 1: Check for 'alertHistory' (what the API actually returns)
            if (dataMap.containsKey('alertHistory') && dataMap['alertHistory'] is List) {
              alertsList = dataMap['alertHistory'] as List<dynamic>;
              print('✅ Found alertHistory with ${alertsList.length} items');
            }
            // Priority 2: Check for 'alerts'
            else if (dataMap.containsKey('alerts') && dataMap['alerts'] is List) {
              alertsList = dataMap['alerts'] as List<dynamic>;
              print('✅ Found alerts with ${alertsList.length} items');
            }
            // Priority 3: Check for 'data'
            else if (dataMap.containsKey('data') && dataMap['data'] is List) {
              alertsList = dataMap['data'] as List<dynamic>;
              print('✅ Found data with ${alertsList.length} items');
            } else {
              // If data is a Map with individual entries, convert to list
              alertsList = dataMap.values.whereType<Map<String, dynamic>>().toList();
              print('⚠️ No standard key found, converted map values: ${alertsList.length} items');
            }
          }
          
          print('📋 Processing ${alertsList.length} alert items...');
          final parsedAlerts = alertsList
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return AlertData.fromJson(item);
                } catch (e) {
                  print('❌ Error parsing individual alert: $e');
                  print('❌ Alert data: $item');
                  return null;
                }
              })
              .whereType<AlertData>()
              .toList();
          
          print('✅ Successfully parsed ${parsedAlerts.length} alerts');
          return parsedAlerts;
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing alert data: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          return <AlertData>[];
        }
      },
    );

    if (result.success && result.data != null) {
      setState(() {
        _alerts = result.data!;
        _applyFilters();
      });
    } else if (result.requiresReauth) {
      // Handle re-authentication
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _applyFilters() {
    _filteredAlerts = _alerts.where((alert) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!alert.title.toLowerCase().contains(query) &&
            !alert.description.toLowerCase().contains(query) &&
            !(alert.vehicleId?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Severity filter
      if (_severityFilter != 'all' && alert.severity != _severityFilter) {
        return false;
      }

      // Status filter
      if (_statusFilter != 'all' && alert.status != _statusFilter) {
        return false;
      }

      // Unread filter
      if (_showOnlyUnread && alert.isRead) {
        return false;
      }

      return true;
    }).toList();

    // Sort by timestamp (newest first)
    _filteredAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Severity Filter
            DropdownButtonFormField<String>(
              initialValue: _severityFilter,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Severities')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) {
                setState(() {
                  _severityFilter = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Status Filter
            DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Unread Filter
            CheckboxListTile(
              title: const Text('Show only unread'),
              value: _showOnlyUnread,
              onChanged: (value) {
                setState(() {
                  _showOnlyUnread = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _severityFilter = 'all';
                _statusFilter = 'all';
                _showOnlyUnread = false;
              });
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(AlertData alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${alert.description}'),
            const SizedBox(height: 8),
            Text('Severity: ${alert.severity.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Status: ${alert.status.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Time: ${alert.timestamp}'),
            if (alert.vehicleId != null) ...[
              const SizedBox(height: 8),
              Text('Vehicle: ${alert.vehicleId}'),
            ],
            if (alert.deviceId != null) ...[
              const SizedBox(height: 8),
              Text('Device: ${alert.deviceId}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.errorValue;
      case 'high':
        return AppColors.warningValue;
      case 'medium':
        return const Color(0xFFFF8F00);
      case 'low':
        return AppColors.infoValue;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.notification_important;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Alerts',
          ),
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _loadAlerts();
                _animationController.reset();
                _animationController.forward();
              },
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search alerts...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.primaryValue.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Filter Summary
          if (_severityFilter != 'all' || _statusFilter != 'all' || _showOnlyUnread)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withOpacity(0.1),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_severityFilter != 'all')
                    Chip(
                      label: Text('Severity: $_severityFilter'),
                      onDeleted: () {
                        setState(() {
                          _severityFilter = 'all';
                          _applyFilters();
                        });
                      },
                    ),
                  if (_statusFilter != 'all')
                    Chip(
                      label: Text('Status: $_statusFilter'),
                      onDeleted: () {
                        setState(() {
                          _statusFilter = 'all';
                          _applyFilters();
                        });
                      },
                    ),
                  if (_showOnlyUnread)
                    Chip(
                      label: const Text('Unread only'),
                      onDeleted: () {
                        setState(() {
                          _showOnlyUnread = false;
                          _applyFilters();
                        });
                      },
                    ),
                ],
              ),
            ),
          
          // Alerts List
          Expanded(
            child: _serviceHelper.isServiceLoading(serviceName)
                ? ServiceIntegrationHelper.buildLoadingWidget('Loading alerts...')
                : _serviceHelper.hasServiceError(serviceName)
                    ? ServiceIntegrationHelper.buildErrorWidget(
                        _serviceHelper.getServiceError(serviceName) ?? 'Unknown error',
                        onRetry: _loadAlerts,
                      )
                    : _filteredAlerts.isEmpty
                        ? ServiceIntegrationHelper.buildEmptyStateWidget(
                            'No alerts found',
                            Icons.notifications_none,
                          )
                        : ListView.builder(
                            itemCount: _filteredAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = _filteredAlerts[index];
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0,
                                      curve: Curves.easeOutCubic),
                                )),
                                child: FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval((index * 0.1).clamp(0.0, 1.0), 1.0,
                                        curve: Curves.easeOut),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade50,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _showAlertDetails(alert),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                // Severity Indicator
                                                Container(
                                                  width: 4,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: _getSeverityColor(alert.severity),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                // Alert Icon
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: _getSeverityColor(alert.severity).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    _getSeverityIcon(alert.severity),
                                                    color: _getSeverityColor(alert.severity),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Content
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Title with status indicator
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              alert.title,
                                                              style: TextStyle(
                                                                fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.bold,
                                                                fontSize: 16,
                                                                color: Colors.grey.shade800,
                                                              ),
                                                            ),
                                                          ),
                                                          if (!alert.isRead)
                                                            Container(
                                                              width: 8,
                                                              height: 8,
                                                              decoration: BoxDecoration(
                                                                color: AppColors.errorValue,
                                                                borderRadius: BorderRadius.circular(4),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      
                                                      if (alert.description.isNotEmpty) ...[
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          alert.description,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                      
                                                      const SizedBox(height: 8),
                                                      
                                                      // Metadata Row
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.access_time,
                                                            size: 14,
                                                            color: Colors.grey.shade500,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _formatTimestamp(alert.timestamp),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade500,
                                                            ),
                                                          ),
                                                          if (alert.vehicleId != null) ...[
                                                            const SizedBox(width: 12),
                                                            Icon(
                                                              Icons.directions_car,
                                                              size: 14,
                                                              color: Colors.grey.shade500,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              alert.vehicleId!,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey.shade500,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                const SizedBox(width: 12),
                                                
                                                // Severity Badge
                                                Column(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            _getSeverityColor(alert.severity),
                                                            _getSeverityColor(alert.severity).withOpacity(0.8),
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(20),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: _getSeverityColor(alert.severity).withOpacity(0.3),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        alert.severity.toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 12,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
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
    );
  }
}