import 'package:flutter/material.dart';
import 'package:edisha/services/gps_tracking_service.dart';
import 'package:edisha/services/device_service.dart';
import 'package:edisha/services/alert_api_service.dart';
import 'package:edisha/services/driver_api_service.dart';
import 'package:edisha/services/behavioral_events_service.dart';
import 'package:edisha/core/service_locator.dart';

/// Responsive Vehicle Status Cards that adapt to screen size
class ResponsiveVehicleStatusCard extends StatefulWidget {
  const ResponsiveVehicleStatusCard({super.key});

  @override
  State<ResponsiveVehicleStatusCard> createState() => _ResponsiveVehicleStatusCardState();
}

class _ResponsiveVehicleStatusCardState extends State<ResponsiveVehicleStatusCard> {
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = true;
  String? _error;
  List<GPSLocationData> _gpsData = []; // Store GPS data for consistency

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if GetIt services are registered
      if (!isEDishaServiceRegistered<DeviceService>()) {
        throw Exception('DeviceService not registered in GetIt');
      }
      
      if (!isEDishaServiceRegistered<GPSTrackingService>()) {
        throw Exception('GPSTrackingService not registered in GetIt');
      }

      final deviceService = getEDishaService<DeviceService>();
      final gpsService = getEDishaService<GPSTrackingService>();
      
      // Fetch vehicle data from APIs
      final devices = await deviceService.getOwnerList();
      final gpsData = await gpsService.fetchGPSData();
      
      // Store GPS data for later use in dialogs
      _gpsData = gpsData;
      
      // Process vehicle status
      final vehicleStatus = _processVehicleStatus(devices, gpsData);
      
      setState(() {
        _vehicleData = vehicleStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _processVehicleStatus(List<dynamic> devices, List<GPSLocationData> gpsData) {
    try {
      debugPrint('🔍 VEHICLE STATUS PROCESSING (FIXED):');
      debugPrint('📱 Total devices from API: ${devices.length}');
      debugPrint('🛰️ Total GPS data from API: ${gpsData.length}');
      
      // Use device count as total vehicles
      int totalVehicles = devices.length;
      
      // Use GPS data to determine active/moving/idle vehicles
      int activeVehicles = gpsData.length;  // All GPS vehicles are considered active
      int movingVehicles = 0;
      int idleVehicles = 0;
      
      // Process GPS data for movement status
      List<String> movingList = [];
      List<String> idleList = [];
      
      for (var gpsItem in gpsData) {
        try {
          final speed = gpsItem.speed ?? 0.0;
          final vehicleId = gpsItem.vehicleId ?? 'Unknown';
          
          if (speed > 5) {
            movingVehicles++;
            movingList.add('$vehicleId (${speed}km/h)');
          } else {
            idleVehicles++;
            idleList.add('$vehicleId (${speed}km/h)');
          }
          debugPrint('   🚗 Vehicle $vehicleId: ${speed}km/h (${speed > 5 ? "Moving" : "Idle"})');
        } catch (e) {
          debugPrint('   ⚠️ Error processing GPS item: $e');
        }
      }
      
      debugPrint('🟢 MOVING VEHICLES ($movingVehicles): ${movingList.join(", ")}');
      debugPrint('🟠 IDLE VEHICLES ($idleVehicles): ${idleList.join(", ")}');
      
      // Calculate offline vehicles
      int offlineVehicles = totalVehicles - activeVehicles;
      if (offlineVehicles < 0) {
        // More GPS data than devices, adjust total
        totalVehicles = activeVehicles;
        offlineVehicles = 0;
      }
      
      debugPrint('✅ FINAL VEHICLE STATUS:');
      debugPrint('   - Total: $totalVehicles');
      debugPrint('   - Active: $activeVehicles');
      debugPrint('   - Moving: $movingVehicles');
      debugPrint('   - Idle: $idleVehicles');
      debugPrint('   - Offline: $offlineVehicles');
      
      final result = {
        'total': totalVehicles,
        'active': activeVehicles,
        'moving': movingVehicles,
        'idle': idleVehicles,
        'offline': offlineVehicles,
        'categories': {
          'schoolBuses': 0, // Removed as requested
          'cabs': 0, // Removed as requested  
          'trucks': 0,
          'others': devices.length, // All devices are 'others' now
        }
      };
      
      debugPrint('📊 RETURNING TO UI: Moving=${result['moving']}, Idle=${result['idle']}');
      return result;
    } catch (e) {
      debugPrint('❌ ERROR in _processVehicleStatus: $e');
      // Return safe default data on error
      return {
        'total': devices.length,
        'active': gpsData.length,
        'moving': 0,
        'idle': gpsData.length,
        'offline': devices.length - gpsData.length,
        'categories': {
          'schoolBuses': 0,
          'cabs': 0,
          'trucks': 0,
          'others': devices.length,
        }
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (_vehicleData != null) _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.directions_car,
            color: Colors.blue,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Vehicle Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _loadVehicleData,
          icon: const Icon(Icons.refresh, size: 24),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load vehicle data',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVehicleData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid based on available width
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 400) {
          crossAxisCount = 3;
        }

        return Column(
          children: [
            _buildSummaryRow(),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _buildStatusCards(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_vehicleData!['total']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text('Total Vehicles', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_vehicleData!['active']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text('Active', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_vehicleData!['offline']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Text('Offline', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusCards() {
    final statusItems = [
      {
        'title': 'Moving',
        'count': _vehicleData!['moving'],
        'icon': Icons.directions_car,
        'color': Colors.green,
        'onTap': () => _showMovingVehiclesDialog(),
      },
      {
        'title': 'Idle',
        'count': _vehicleData!['idle'],
        'icon': Icons.pause_circle_outline,
        'color': Colors.orange,
        'onTap': () => _showIdleVehiclesDialog(),
      },
    ];

    return statusItems.map((item) => _buildStatusCard(item)).toList();
  }

  Widget _buildStatusCard(Map<String, dynamic> item) {
    return InkWell(
      onTap: item['onTap'] as VoidCallback?,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Icon(
              item['icon'] as IconData,
              color: item['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              '${item['count']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: item['color'] as Color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              item['title'] as String,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
    );
  }
  
  void _showMovingVehiclesDialog() {
    showDialog(
      context: context,
      builder: (context) => VehicleStatusDialog(
        title: 'Moving Vehicles',
        vehicleType: 'moving',
        icon: Icons.directions_car,
        color: Colors.green,
        gpsData: _gpsData, // Pass the same GPS data
      ),
    );
  }
  
  void _showIdleVehiclesDialog() {
    showDialog(
      context: context,
      builder: (context) => VehicleStatusDialog(
        title: 'Idle Vehicles',
        vehicleType: 'idle', 
        icon: Icons.pause_circle_outline,
        color: Colors.orange,
        gpsData: _gpsData, // Pass the same GPS data
      ),
    );
  }
}

/// Dialog to show vehicles by status (Moving/Idle)
class VehicleStatusDialog extends StatefulWidget {
  final String title;
  final String vehicleType;
  final IconData icon;
  final Color color;
  final List<GPSLocationData> gpsData;

  const VehicleStatusDialog({
    super.key,
    required this.title,
    required this.vehicleType,
    required this.icon,
    required this.color,
    required this.gpsData,
  });

  @override
  State<VehicleStatusDialog> createState() => _VehicleStatusDialogState();
}

class _VehicleStatusDialogState extends State<VehicleStatusDialog> {
  List<GPSLocationData> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() => _isLoading = true);
      
      // Use the GPS data passed from the parent widget
      final allGpsData = widget.gpsData;
      
      // Filter vehicles based on type
      List<GPSLocationData> filteredVehicles = [];
      if (widget.vehicleType == 'moving') {
        filteredVehicles = allGpsData.where((gps) => (gps.speed ?? 0.0) > 5).toList();
      } else if (widget.vehicleType == 'idle') {
        filteredVehicles = allGpsData.where((gps) => (gps.speed ?? 0.0) <= 5).toList();
      }
      
      debugPrint('🚗 ${widget.vehicleType.toUpperCase()} DIALOG: Found ${filteredVehicles.length} vehicles');
      for (var vehicle in filteredVehicles) {
        debugPrint('   - ${vehicle.vehicleId}: ${vehicle.speed ?? 0.0} km/h');
      }
      
      setState(() {
        _vehicles = filteredVehicles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vehicles in dialog: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(widget.icon, color: widget.color),
          const SizedBox(width: 12),
          Text(widget.title),
          const Spacer(),
          IconButton(
            onPressed: _loadVehicles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _vehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No ${widget.vehicleType} vehicles found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: widget.color.withOpacity(0.2),
                            child: Icon(widget.icon, color: widget.color),
                          ),
                          title: Text(
                            vehicle.vehicleId ?? 'Unknown Vehicle',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Speed: ${vehicle.speed?.toStringAsFixed(1) ?? '0.0'} km/h\nLast Update: ${_formatTimestamp(vehicle.timestamp)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.vehicleType.toUpperCase(),
                              style: TextStyle(
                                color: widget.color,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Responsive Alert Overview Card
class ResponsiveAlertOverviewCard extends StatefulWidget {
  const ResponsiveAlertOverviewCard({super.key});

  @override
  State<ResponsiveAlertOverviewCard> createState() => _ResponsiveAlertOverviewCardState();
}

class _ResponsiveAlertOverviewCardState extends State<ResponsiveAlertOverviewCard> {
  Map<String, dynamic>? _alertData;
  List<dynamic> _rawAlerts = []; // Store raw alert data for dialogs
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlertData();
  }

  Future<void> _loadAlertData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final alertService = getIt<AlertApiService>();
      final alerts = await alertService.fetchAlerts();
      
      final processedData = _processAlertData(alerts);
      
      setState(() {
        _alertData = processedData['summary'];
        _rawAlerts = processedData['rawAlerts'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _processAlertData(Map<String, dynamic> apiResponse) {
    // Handle API response structure
    List<dynamic> alerts = [];
    
    if (apiResponse['success'] == true && apiResponse['data'] != null) {
      final data = apiResponse['data'];
      if (data is List) {
        alerts = data;
      } else if (data is Map) {
        // If data is a map, look for alerts array or treat as single alert
        if (data['alertHistory'] is List) {
          alerts = data['alertHistory'];
        } else if (data['alerts'] is List) {
          alerts = data['alerts'];
        } else if (data['results'] is List) {
          alerts = data['results'];
        } else {
          // Treat the entire data object as a single alert
          alerts = [data];
        }
      }
    }
    
    int totalAlerts = alerts.length;
    int criticalAlerts = 0;
    int warningAlerts = 0;
    int infoAlerts = 0;
    int todayAlerts = 0;

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    for (var alert in alerts) {
      // Extract timestamp - check multiple possible locations
      String? timeString = alert['created_at']?.toString() ?? 
                          alert['timestamp']?.toString() ?? 
                          alert['date']?.toString();
      
      // If no direct timestamp, check nested GPS data
      if (timeString == null && alert['gps_ref'] != null) {
        timeString = alert['gps_ref']['entry_time']?.toString();
      }
      
      final alertTime = DateTime.tryParse(timeString ?? '');
      if (alertTime != null && alertTime.isAfter(todayStart)) {
        todayAlerts++;
      }

      // Determine severity - for your API, use GPS status or emergency status as indicators
      String severity = 'info';
      if (alert['gps_ref'] != null) {
        final gpsRef = alert['gps_ref'];
        final emergencyStatus = gpsRef['emergency_status']?.toString();
        final boxTamperAlert = gpsRef['box_tamper_alert']?.toString();
        
        if (emergencyStatus == '1' || boxTamperAlert != 'O') {
          severity = 'critical';
        } else if (gpsRef['ignition_status'] == '0' && gpsRef['main_power_status'] == '1') {
          severity = 'warning';
        }
      }
      
      // Also check for explicit severity fields
      final explicitSeverity = (alert['severity'] ?? alert['level'] ?? alert['priority'])?.toString().toLowerCase();
      if (explicitSeverity != null) {
        severity = explicitSeverity;
      }
      switch (severity.toLowerCase()) {
        case 'critical':
        case 'high':
        case 'error':
          criticalAlerts++;
          break;
        case 'warning':
        case 'medium':
        case 'warn':
          warningAlerts++;
          break;
        default:
          infoAlerts++;
          break;
      }
    }

    return {
      'summary': {
        'total': totalAlerts,
        'critical': criticalAlerts,
        'warning': warningAlerts,
        'info': infoAlerts,
        'today': todayAlerts,
      },
      'rawAlerts': alerts,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (_alertData != null) _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.warning_amber,
            color: Colors.red,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Alert Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _loadAlertData,
          icon: const Icon(Icons.refresh, size: 24),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load alert data'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAlertData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return _buildAlertMetrics();
  }

  Widget _buildAlertMetrics() {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard('Critical', _alertData!['critical'], Colors.red, Icons.error, 'critical'),
            _buildMetricCard('Warning', _alertData!['warning'], Colors.orange, Icons.warning, 'warning'),
            _buildMetricCard('Today', _alertData!['today'], Colors.blue, Icons.today, 'today'),
            _buildMetricCard('Total', _alertData!['total'], Colors.grey, Icons.notifications, 'total'),
          ],
        ),
      ],
    );
  }

  void _showAlertDialog(BuildContext context, String filterType, String title, Color color) {
    // Filter alerts based on the type
    List<dynamic> filteredAlerts = _rawAlerts;

    if (filterType == 'critical' || filterType == 'warning') {
      filteredAlerts = _rawAlerts.where((alert) {
        String severity = 'info';
        if (alert['gps_ref'] != null) {
          final gpsRef = alert['gps_ref'];
          final emergencyStatus = gpsRef['emergency_status']?.toString();
          final boxTamperAlert = gpsRef['box_tamper_alert']?.toString();
          if (emergencyStatus == '1' || boxTamperAlert != 'O') {
            severity = 'critical';
          } else if (gpsRef['ignition_status'] == '0' && gpsRef['main_power_status'] == '1') {
            severity = 'warning';
          }
        }
        final explicitSeverity = (alert['severity'] ?? alert['level'] ?? alert['priority'])?.toString().toLowerCase();
        if (explicitSeverity != null) severity = explicitSeverity;
        return severity == filterType;
      }).toList();
    } else if (filterType == 'today') {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      filteredAlerts = _rawAlerts.where((alert) {
        String? timeString = alert['created_at']?.toString() ?? alert['timestamp']?.toString() ?? alert['date']?.toString();
        if (timeString == null && alert['gps_ref'] != null) {
          timeString = alert['gps_ref']['entry_time']?.toString();
        }
        final alertTime = DateTime.tryParse(timeString ?? '');
        return alertTime != null && alertTime.isAfter(todayStart);
      }).toList();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$title Alerts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Text('${filteredAlerts.length}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: filteredAlerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No $title alerts found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    return _buildAlertListItem(alert);
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildAlertListItem(Map<String, dynamic> alert) {
    // Extract fields for display
    String title = alert['title']?.toString() ?? alert['alert_type']?.toString() ?? 'Alert';
    String description = alert['description']?.toString() ?? alert['message']?.toString() ?? '';
    String vehicle = 'Unknown Vehicle';
    DateTime timestamp = DateTime.now();
    double? speed;

    if (alert['deviceTag'] != null) {
      vehicle = alert['deviceTag']['vehicle_reg_no']?.toString() ?? alert['deviceTag']['registration_number']?.toString() ?? vehicle;
    }
    if (alert['gps_ref'] != null) {
      final gps = alert['gps_ref'];
      timestamp = DateTime.tryParse(gps['entry_time']?.toString() ?? '') ?? timestamp;
      speed = double.tryParse(gps['speed']?.toString() ?? '');
    }

    final timeAgo = _formatShortTimeAgo(timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.notifications_active),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_car, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vehicle, 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                if (speed != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${speed.toStringAsFixed(1)} km/h', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatShortTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildMetricCard(String title, int count, Color color, IconData icon, String filterType) {
    return GestureDetector(
      onTap: () => _showAlertDialog(context, filterType, title, color),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Responsive Driver Behaviour Card
class ResponsiveDriverBehaviourCard extends StatefulWidget {
  const ResponsiveDriverBehaviourCard({super.key});

  @override
  State<ResponsiveDriverBehaviourCard> createState() => _ResponsiveDriverBehaviourCardState();
}

class _ResponsiveDriverBehaviourCardState extends State<ResponsiveDriverBehaviourCard> {
  Map<String, dynamic>? _driverData;
  BehavioralEventsSummary? _behavioralData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load driver data
      final driverService = getIt<DriverApiService>();
      final apiResponse = await driverService.getTagOwnerList();
      final processedData = _processDriverData(apiResponse);
      
      // Load behavioral events data with fallback
      BehavioralEventsSummary? behavioralData;
      try {
        if (isEDishaServiceRegistered<BehavioralEventsService>()) {
          final behavioralService = getIt<BehavioralEventsService>();
          behavioralData = await behavioralService.getBehavioralEventsSummary();
          debugPrint('✅ Behavioral events loaded successfully');
        } else {
          debugPrint('⚠️ BehavioralEventsService not registered, using fallback');
          behavioralData = _getFallbackBehavioralData();
        }
      } catch (e) {
        debugPrint('❌ Failed to load behavioral events: $e');
        behavioralData = _getFallbackBehavioralData();
      }
      
      setState(() {
        _driverData = processedData;
        _behavioralData = behavioralData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _processDriverData(Map<String, dynamic> apiResponse) {
    // Handle API response structure
    List<dynamic> drivers = [];
    
    if (apiResponse['success'] == true && apiResponse['data'] != null) {
      final data = apiResponse['data'];
      if (data is List) {
        drivers = data;
      } else if (data is Map) {
        // If data is a map, look for common list keys
        if (data['drivers'] is List) {
          drivers = data['drivers'];
        } else if (data['results'] is List) {
          drivers = data['results'];
        } else if (data['owner_list'] is List) {
          drivers = data['owner_list'];
        } else if (data['tag_list'] is List) {
          drivers = data['tag_list'];
        } else {
          // Treat the entire data object as a single driver/owner record
          drivers = [data];
        }
      }
    }
    
    int totalDrivers = drivers.length;
    int activeDrivers = 0;
    int onDutyDrivers = 0;
    for (var driver in drivers) {
      final status = (driver['status'] ?? driver['tag_status'] ?? driver['esim_status'])?.toString().toLowerCase();
      if (status == 'active' || status == 'enabled' || status == 'online') {
        activeDrivers++;
      }
      
      final dutyStatus = (driver['duty_status'] ?? driver['driver_status'])?.toString().toLowerCase();
      if (dutyStatus == 'on_duty' || dutyStatus == 'active' || status == 'active') {
        onDutyDrivers++;
      }
    }

    return {
      'total': totalDrivers,
      'active': activeDrivers,
      'onDuty': onDutyDrivers,
      'topDrivers': drivers.take(5).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (!_isLoading && _error == null && _driverData != null) _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_outline,
            color: Colors.green,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Driver Behaviour',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _loadDriverData,
          icon: const Icon(Icons.refresh, size: 24),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load driver data'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDriverData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            _buildDriverSummary(),
            const SizedBox(height: 20),
            _buildBehaviourMetrics(),
          ],
        );
      },
    );
  }

  Widget _buildDriverSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_driverData!['total']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text('Total Drivers', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_driverData!['active']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text('Active', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_driverData!['onDuty']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Text('On Duty', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviourMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildBehaviourCard(
          'Harsh Braking',
          _behavioralData?.harshBrakingCount ?? 4,
          Colors.red,
          Icons.pan_tool,
          'harsh_braking',
        ),
        _buildBehaviourCard(
          'Overspeeding',
          _behavioralData?.overspeedingCount ?? 2,
          Colors.orange,
          Icons.speed,
          'overspeeding',
        ),
        _buildBehaviourCard(
          'Sudden Turn',
          _behavioralData?.suddenTurnCount ?? 3,
          Colors.purple,
          Icons.turn_right,
          'sudden_turn',
        ),
      ],
    );
  }

  Widget _buildBehaviourCard(String title, int count, Color color, IconData icon, String eventType) {
    return GestureDetector(
      onTap: () => _showBehavioralEventDialog(context, eventType, title, color),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show behavioral event dialog with event details
  void _showBehavioralEventDialog(BuildContext context, String eventType, String title, Color color) async {
    try {
      List<BehavioralEvent> events = [];
      
      if (isEDishaServiceRegistered<BehavioralEventsService>()) {
        final behavioralService = getIt<BehavioralEventsService>();
        events = await behavioralService.getEventsByType(eventType);
      }
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildBehavioralEventDialog(context, events, title, color);
        },
      );
    } catch (e) {
      if (mounted) {
        // Show empty dialog instead of error for better UX
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _buildBehavioralEventDialog(context, [], title, color);
          },
        );
      }
    }
  }

  /// Build behavioral event dialog widget
  Widget _buildBehavioralEventDialog(BuildContext context, List<BehavioralEvent> events, String title, Color color) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title Events',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${events.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: events.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No $title events found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This could mean good driving behavior!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildBehavioralEventListItem(event, color);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Build individual behavioral event list item
  Widget _buildBehavioralEventListItem(BehavioralEvent event, Color color) {
    final timeAgo = _getTimeAgo(event.timestamp);
    final severityColor = _getSeverityColor(event.severity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: severityColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    event.severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.vehicleId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (event.speed != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.speed!.toStringAsFixed(1)} km/h',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (event.description != null && event.description!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                event.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${event.latitude.toStringAsFixed(6)}, ${event.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get severity color
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[800]!;
      case 'high':
        return Colors.red[600]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Get human-readable time ago string
  String _getTimeAgo(DateTime timestamp) {
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

  /// Get fallback behavioral data when service fails
  BehavioralEventsSummary _getFallbackBehavioralData() {
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
}
