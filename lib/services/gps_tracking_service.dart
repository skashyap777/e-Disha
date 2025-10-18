import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edisha/services/auth_api_service.dart';

class GPSTrackingService {
  final Logger _logger = Logger();
  Timer? _trackingTimer;
  Timer? _realTimeTimer;
  late http.Client _client;
  late AuthApiService _authService;

  GPSTrackingService() {
    _initializeClient();
    _authService = AuthApiService();
  }
  
  // Callback functions for location updates
  Function(List<GPSLocationData>)? _onLocationUpdate;
  Function(String)? _onError;

  String get _apiUrl =>
      dotenv.env['GPS_TRACKING_API_URL'] ??
      'https://api.gromed.in/api/gps_track_data_api/';

  // Initialize the HTTP client with SSL bypass (like e-Disha)
  void _initializeClient() {
    // Create a custom HTTP client that bypasses SSL verification
    // This is needed because the gromed API has SSL certificate issues
    final customClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Only bypass SSL for the gromed API domain
        if (host.contains('gromed.in') || host.contains('api.gromed.in')) {
          debugPrint(
              '🔒 Bypassing SSL certificate for gromed API: $host:$port');
          return true; // Accept certificates for gromed API
        }
        return false; // Reject certificates for other domains
      };

    _client = IOClient(customClient);
    debugPrint(
        '🔧 SSL-bypass HTTP client initialized for gromed API (${kDebugMode ? "debug" : "release"} mode)');
  }

  /// Helper method to fetch data and update listeners
  void _fetchAndUpdate() async {
    try {
      final locations = await fetchGPSData();
      _onLocationUpdate?.call(locations);
    } catch (e) {
      debugPrint('❌ Real-time update error: $e');
      _onError?.call(e.toString());
    }
  }

  /// Fetch GPS history data from gromed API
  Future<List<GPSLocationData>> fetchGPSHistoryData({
    required String startDateTime,
    required String endDateTime,
    required String vehicleRegistrationNumber,
    String? deviceId,
    String? tagStatus,
    String? simStatus,
    String? stockStatus,
  }) async {
    try {
      // Get the OTP token specifically for GPS API
      final prefs = await SharedPreferences.getInstance();
      final otpToken = prefs.getString('otp_token');
      final currentToken = await _authService.getCurrentAuthToken();
      final token = otpToken ?? currentToken;

      debugPrint(
          '🔑 GPS History TOKEN DEBUG: OTP=${otpToken?.substring(0, 10)}..., Current=${currentToken?.substring(0, 10)}..., Using=${token?.substring(0, 10)}...');

      if (token == null || token.isEmpty) {
        _logger.e('GPS history API: No authentication token available');
        debugPrint('❌ GPS History API: No authentication token found');
        return [];
      }

      // Build the history API URL with query parameters
      final historyApiUrl = 'https://api.gromed.in/api/gps_history_map_data/';
      final uri = Uri.parse(historyApiUrl).replace(queryParameters: {
        'start_datetime': startDateTime,
        'end_datetime': endDateTime,
        'vehicle_registration_number': vehicleRegistrationNumber,
      });

      debugPrint('🔄 Starting GPS History API request to: $uri');
      debugPrint('🔑 Using auth token: ${token.substring(0, 8)}...');
      debugPrint('📅 Date range: $startDateTime to $endDateTime');
      debugPrint('🚗 Vehicle: $vehicleRegistrationNumber');

      // Prepare request body if additional parameters are provided
      Map<String, dynamic>? requestBody;
      if (deviceId != null ||
          tagStatus != null ||
          simStatus != null ||
          stockStatus != null) {
        requestBody = {};
        if (deviceId != null) requestBody['device_id'] = deviceId;
        if (tagStatus != null) requestBody['tag_status'] = tagStatus;
        if (simStatus != null) requestBody['sim_status'] = simStatus;
        if (stockStatus != null) requestBody['stock_status'] = stockStatus;
      }

      final response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: requestBody != null ? json.encode(requestBody) : null,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 History API Response received: ${response.statusCode}');
      debugPrint('📋 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        debugPrint('✅ HTTP 200 OK - Parsing JSON response...');
        final dynamic responseData = json.decode(response.body);

        List<dynamic> data = [];
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'] ?? [];
        } else if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        }

        debugPrint('🔍 JSON structure: ${responseData.runtimeType}');
        debugPrint('📍 Found ${data.length} history points in response');

        // Log first item structure if available for debugging
        if (data.isNotEmpty) {
          debugPrint('🔍 SAMPLE HISTORY ITEM STRUCTURE:');
          debugPrint('   Full item: ${json.encode(data.first)}');
          if (data.first is Map) {
            final sample = data.first as Map;
            debugPrint('   Keys: ${sample.keys.toList()}');
            
            // Check both full and abbreviated field names
            debugPrint('   lat field: ${sample['lat']} (abbreviated)');
            debugPrint('   lon field: ${sample['lon']} (abbreviated)');
            debugPrint('   latitude field: ${sample['latitude']} (full)');
            debugPrint('   longitude field: ${sample['longitude']} (full)');
            debugPrint('   et field: ${sample['et']} (entry_time abbreviated)');
            debugPrint('   entry_time field: ${sample['entry_time']}');
            debugPrint('   no field: ${sample['no']} (vehicle number abbreviated)');
            debugPrint('   vehicle_registration_number: ${sample['vehicle_registration_number']}');
            
            // Check if coordinates are nested
            if (sample.containsKey('gps_ref')) {
              debugPrint('   ⚠️ FOUND gps_ref nested object: ${sample['gps_ref']}');
            }
            if (sample.containsKey('location')) {
              debugPrint('   ⚠️ FOUND location nested object: ${sample['location']}');
            }
          }
        }

        if (data.isEmpty) {
          debugPrint(
              '⚠️ No history data in API response for vehicle $vehicleRegistrationNumber');
          _logger.w('No GPS history data available from API');
          return [];
        }

        final historyPoints = data.map((item) {
          // Use abbreviated field names from history API
          final lat = item['lat'] ?? item['latitude'];
          final lon = item['lon'] ?? item['longitude'];
          final time = item['et'] ?? item['entry_time'] ?? item['timestamp'];
          final vehicle = item['no'] ?? item['vehicle_registration_number'] ?? vehicleRegistrationNumber;
          
          debugPrint(
              '📍 Processing history point: $vehicle at $lat, $lon - $time');
          return GPSLocationData.fromgromedJson(item);
        }).toList();

        // Filter out invalid points with null/zero coordinates
        final validHistoryPoints = historyPoints.where((point) {
          final hasValidCoords = point.latitude != 0.0 && point.longitude != 0.0;
          if (!hasValidCoords) {
            debugPrint('⚠️ Skipping invalid history point: ${point.vehicleId} at (${point.latitude}, ${point.longitude})');
          }
          return hasValidCoords;
        }).toList();

        if (validHistoryPoints.isEmpty && historyPoints.isNotEmpty) {
          debugPrint('❌ All ${historyPoints.length} history points have invalid coordinates (0.0, 0.0)');
          _logger.e('History data contains no valid GPS coordinates');
          return [];
        }

        // Sort by timestamp to ensure chronological order
        validHistoryPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        debugPrint(
            '✅ Successfully parsed ${validHistoryPoints.length} valid GPS history points (filtered from ${historyPoints.length} total)');
        return validHistoryPoints;
      } else {
        debugPrint(
            '❌ GPS History API Error: ${response.statusCode} - ${response.body}');
        _logger.e('HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ GPS History API Error: $e');
      debugPrint('🔍 Stack trace: $stackTrace');
      _logger.e('Error fetching GPS history data: $e');
      return [];
    }
  }

  /// Fetch GPS tracking data from gromed API
  Future<List<GPSLocationData>> fetchGPSData() async {
    try {
      // Get the OTP token specifically for GPS API
      final prefs = await SharedPreferences.getInstance();
      final otpToken = prefs.getString('otp_token');
      final currentToken = await _authService.getCurrentAuthToken();
      final token = otpToken ?? currentToken;

      debugPrint(
          '🔑 GPS TOKEN DEBUG: OTP=${otpToken?.substring(0, 10)}..., Current=${currentToken?.substring(0, 10)}..., Using=${token?.substring(0, 10)}...');

      if (token == null || token.isEmpty) {
        _logger.e('GPS tracking API: No authentication token available');
        debugPrint('❌ GPS API: No authentication token found');
        return _getMockGPSData();
      }

      if (_apiUrl.isEmpty) {
        _logger.e('GPS tracking API URL is missing');
        return _getMockGPSData();
      }

      debugPrint('🔄 Starting GPS API request to: $_apiUrl');
      debugPrint('🔑 Using auth token: ${token.substring(0, 8)}...');
      final url = Uri.parse(_apiUrl);

      // Use the same authentication format as other APIs
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'eDisha/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📊 Response received: ${response.statusCode}');
      debugPrint('📋 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        debugPrint('✅ HTTP 200 OK - Parsing JSON response...');
        final Map<String, dynamic> responseData = json.decode(response.body);
        debugPrint('🔍 JSON keys: ${responseData.keys.toList()}');

        final List<dynamic> data = responseData['data'] ?? [];
        debugPrint('🚗 Found ${data.length} vehicles in response');

        if (data.isEmpty) {
          debugPrint('⚠️ No vehicle data in API response');
          _logger.w('No GPS tracking data available from API');
          return _getMockGPSData();
        }

        final trackingPoints = data.map((item) {
          debugPrint(
              '📍 Processing vehicle: ${item['vehicle_registration_number']} at ${item['latitude']}, ${item['longitude']}');
          return GPSLocationData.fromgromedJson(item);
        }).toList();

        debugPrint(
            '✅ Successfully parsed ${trackingPoints.length} GPS tracking points');
        return trackingPoints;
      } else {
        debugPrint(
            '❌ GPS API Error: ${response.statusCode} - ${response.body}');
        _logger.e('HTTP ${response.statusCode}: ${response.body}');
        return _getMockGPSData();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ GPS Tracking API Error: $e');
      debugPrint('🔍 Stack trace: $stackTrace');
      _logger.e('Error fetching GPS data: $e');
      return _getMockGPSData();
    }
  }

  /// Start real-time GPS tracking with periodic updates
  void startRealTimeTracking({
    required Function(List<GPSLocationData>) onLocationUpdate,
    required Function(String) onError,
    Duration interval = const Duration(seconds: 5),
  }) {
    stopRealTimeTracking();
    
    debugPrint('▶️ Starting real-time GPS tracking (interval: ${interval.inSeconds}s)');
    _onLocationUpdate = onLocationUpdate;
    _onError = onError;
    
    // Fetch immediately for first update
    _fetchAndUpdate();
    
    // Then start periodic updates
    _realTimeTimer = Timer.periodic(interval, (timer) {
      _fetchAndUpdate();
    });
  }

  /// Stop real-time GPS tracking
  void stopRealTimeTracking() {
    debugPrint('⏹️ Stopping real-time GPS tracking');
    _trackingTimer?.cancel();
    _realTimeTimer?.cancel();
    _trackingTimer = null;
    _realTimeTimer = null;
    _onLocationUpdate = null;
    _onError = null;
  }

  /// Check if tracking is currently active
  bool get isTracking => (_trackingTimer?.isActive ?? false) || (_realTimeTimer?.isActive ?? false);

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      debugPrint('🔧 Testing API connection...');
      final locations = await fetchGPSData();
      debugPrint('✅ API connection test successful - ${locations.length} locations received');
      return true;
    } catch (e) {
      debugPrint('❌ API connection test failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopRealTimeTracking();
    _client.close();
    debugPrint('🗑️ GPS tracking service disposed and HTTP client closed');
  }

  /// Provide mock GPS data for testing when API is unavailable
  List<GPSLocationData> _getMockGPSData() {
    final now = DateTime.now();
    return [
      GPSLocationData(
        id: 'vehicle_001',
        latitude: 28.6139,
        longitude: 77.2090,
        speed: 45.5,
        heading: 180,
        timestamp: now,
        vehicleId: 'DL01AB1234',
        address: 'Connaught Place, New Delhi',
        packetType: 'moving', // Moving status
        isOnline: true,
      ),
      GPSLocationData(
        id: 'vehicle_002',
        latitude: 28.6129,
        longitude: 77.2295,
        speed: 32.0,
        heading: 90,
        timestamp: now.subtract(const Duration(minutes: 2)),
        vehicleId: 'DL02CD5678',
        address: 'India Gate, New Delhi',
        packetType: 'idle', // Idle status
        isOnline: true,
      ),
      GPSLocationData(
        id: 'vehicle_003',
        latitude: 28.5244,
        longitude: 77.1855,
        speed: 0,
        heading: 0,
        timestamp: now.subtract(const Duration(minutes: 15)),
        vehicleId: 'DL03EF9012',
        address: 'Qutub Minar, New Delhi',
        packetType: 'stopped', // Stopped status
        isOnline: true,
      ),
    ];
  }
}

/// GPS Location Data Model
class GPSLocationData {
  final String id;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? vehicleId;
  final String? address;
  final bool isOnline;
  final String? packetType; // Added for emergency/alert status
  final String? ignitionStatus; // "1" = on, "0" = off
  final int? satellites;
  final String? mainPowerStatus;

  GPSLocationData({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.timestamp,
    this.vehicleId,
    this.address,
    this.isOnline = true,
    this.packetType,
    this.ignitionStatus,
    this.satellites,
    this.mainPowerStatus,
  });

  /// Check if ignition is on
  bool get isIgnitionOn => ignitionStatus == '1';

  /// Check if vehicle is active (recent data + ignition on/moving)
  bool get isActive {
    final now = DateTime.now();
    final timeDiff = now.difference(timestamp);
    return timeDiff.inMinutes <= 30 && (isIgnitionOn || (speed ?? 0) > 0);
  }

  factory GPSLocationData.fromJson(Map<String, dynamic> json) {
    return GPSLocationData(
      id: json['id']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      speed: double.tryParse(json['speed']?.toString() ?? '0'),
      heading: double.tryParse(json['heading']?.toString() ?? '0'),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      vehicleId: json['vehicle_id']?.toString(),
      address: json['address']?.toString(),
      isOnline: json['is_online'] == true || json['status'] == 'online',
      packetType: json['packet_type']?.toString(),
      ignitionStatus: json['ignition_status']?.toString(),
      satellites: int.tryParse(json['satellites']?.toString() ?? '0'),
      mainPowerStatus: json['main_power_status']?.toString(),
    );
  }

  /// Create GPSLocationData from gromed API JSON format
  factory GPSLocationData.fromgromedJson(Map<String, dynamic> json) {
    // Check if GPS data is nested in gps_ref object (common in history/alert APIs)
    final gpsData = json.containsKey('gps_ref') && json['gps_ref'] != null
        ? json['gps_ref'] as Map<String, dynamic>
        : json;

    // Extract latitude - check for both 'lat' (history API) and 'latitude' (tracking API)
    double parseLatitude() {
      final latValue = gpsData['lat']?.toString() ?? 
                       gpsData['latitude']?.toString() ?? 
                       '0';
      return double.tryParse(latValue) ?? 0.0;
    }

    // Extract longitude - check for both 'lon' (history API) and 'longitude' (tracking API)
    double parseLongitude() {
      final lonValue = gpsData['lon']?.toString() ?? 
                       gpsData['longitude']?.toString() ?? 
                       '0';
      return double.tryParse(lonValue) ?? 0.0;
    }

    // Extract speed - check 's' (history API) and 'speed' (tracking API)
    double? parseSpeed() {
      final speedValue = gpsData['s']?.toString() ?? 
                         gpsData['speed']?.toString();
      return speedValue != null ? double.tryParse(speedValue) : null;
    }

    // Extract heading - check 'h' (history API) and 'heading' (tracking API)
    double? parseHeading() {
      final headingValue = gpsData['h']?.toString() ?? 
                           gpsData['heading']?.toString();
      return headingValue != null ? double.tryParse(headingValue) : null;
    }

    // Extract timestamp - check 'et' (entry_time in history) and other formats
    DateTime parseTimestamp() {
      return DateTime.tryParse(gpsData['et']?.toString() ??
                  gpsData['entry_time']?.toString() ??
                  gpsData['timestamp']?.toString() ??
                  json['et']?.toString() ??
                  json['entry_time']?.toString() ??
                  json['timestamp']?.toString() ??
                  json['created_at']?.toString() ??
                  '') ??
              DateTime.now();
    }

    // Extract satellites - check 'sat' (history API) and 'satellites' (tracking API)
    int? parseSatellites() {
      final satValue = gpsData['sat']?.toString() ?? 
                       gpsData['satellites']?.toString();
      return satValue != null ? int.tryParse(satValue) : null;
    }

    return GPSLocationData(
      id: json['imei']?.toString() ?? json['id']?.toString() ?? '',
      vehicleId: json['vehicle_registration_number']?.toString() ??
          json['no']?.toString() ??  // 'no' field in history API
          json['imei']?.toString() ??
          json['vehicle_id']?.toString() ??
          json['vehicleId']?.toString() ??
          '',
      latitude: parseLatitude(),
      longitude: parseLongitude(),
      speed: parseSpeed(),
      heading: parseHeading(),
      timestamp: parseTimestamp().toLocal(),
      address: json['address']?.toString(),
      isOnline: true, // Assume online if data is recent
      packetType: gpsData['ps']?.toString() ?? gpsData['packet_type']?.toString(),  // 'ps' in history API
      ignitionStatus: gpsData['igs']?.toString() ?? gpsData['ignition_status']?.toString(),  // 'igs' in history API
      satellites: parseSatellites(),
      mainPowerStatus: gpsData['mps']?.toString() ?? gpsData['main_power_status']?.toString(),  // 'mps' in history API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'vehicle_id': vehicleId,
      'address': address,
      'is_online': isOnline,
      'packet_type': packetType,
      'ignition_status': ignitionStatus,
      'satellites': satellites,
      'main_power_status': mainPowerStatus,
    };
  }

  @override
  String toString() {
    return 'GPSLocationData(id: $id, lat: $latitude, lng: $longitude, speed: $speed, vehicleId: $vehicleId, ignition: $ignitionStatus)';
  }
}