import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edisha/services/auth_api_service.dart';
import 'package:edisha/services/gps_tracking_service.dart';

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal() {
    _initializeClient();
  }

  late http.Client _client;
  final AuthApiService _authService = AuthApiService();

  // Initialize the HTTP client with SSL bypass
  void _initializeClient() {
    final customClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (host.contains('gromed.in') || host.contains('api.gromed.in')) {
          debugPrint(
              '🔒 Bypassing SSL certificate for gromed API: $host:$port');
          return true;
        }
        return false;
      };

    _client = IOClient(customClient);
    debugPrint('🔧 Route Service HTTP client initialized for gromed.in APIs');
  }

  /// Set route for a device (GET request)
  Future<RouteResponse?> setRoute({required int deviceId}) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ Route API: No authentication token available');
        return null;
      }

      final url = Uri.parse('https://api.gromed.in/api/setRoute/').replace(
        queryParameters: {'device': deviceId.toString()},
      );

      debugPrint('🔄 Setting route for device: $deviceId');
      debugPrint('📡 GET request to: $url');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'eDisha/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📊 Set Route Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Route set successfully: $data');
        return RouteResponse.fromJson(data);
      } else {
        debugPrint(
            '❌ Set Route Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Set Route API Error: $e');
      return null;
    }
  }

  /// Save route (POST request) - Using Gromed API with multiple fallback approaches
  Future<bool> saveRoute({
    required dynamic deviceId, // Allow both int and String
    String? route, // Optional string format (legacy)
    List<List<double>>?
        routeCoordinates, // New array format [lng, lat, elevation]
    required List<List<double>> routePoints,
    int? id, // For updating existing route
    String? routeName, // Optional route name
    String? routeHash, // Hash from route path API (critical for compatibility)
  }) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ Save Route API: No authentication token available');
        return false;
      }

      // Try multiple API approaches for better compatibility
      return await _tryMultipleSaveApproaches(deviceId, route, routeCoordinates,
          routePoints, id, routeName, routeHash);
    } catch (e) {
      debugPrint('❌ Save Route API Error: $e');
      return false;
    }
  }

  /// Try multiple API approaches for saving routes
  Future<bool> _tryMultipleSaveApproaches(
      dynamic deviceId,
      String? route,
      List<List<double>>? routeCoordinates,
      List<List<double>> routePoints,
      int? id,
      String? routeName,
      String? routeHash) async {
    // Ensure device_id is properly formatted
    String deviceIdStr;
    if (deviceId is String) {
      deviceIdStr = deviceId;
    } else if (deviceId is int) {
      deviceIdStr = deviceId.toString();
    } else {
      deviceIdStr = deviceId.toString();
    }

    debugPrint(
        '🔍 Device ID debug: original=$deviceId, converted=$deviceIdStr');

    // Approach 1: Try with full route coordinates (React-compatible)
    debugPrint('🚀 Attempt 1: Full coordinates array with hash');
    if (await _trySaveRouteApproach1(
        deviceIdStr, routeCoordinates, routePoints, id, routeName,
        routeHash: routeHash)) {
      return true;
    }

    // Approach 2: Try with simplified format
    debugPrint('🚀 Attempt 2: Simplified format');
    if (await _trySaveRouteApproach2(
        deviceIdStr, route, routePoints, id, routeName)) {
      return true;
    }

    // Approach 3: Try with minimal required fields only
    debugPrint('🚀 Attempt 3: Minimal fields');
    if (await _trySaveRouteApproach3(deviceIdStr, routePoints, routeName)) {
      return true;
    }

    // Approach 4: Try with numeric device ID mapping
    debugPrint('🚀 Attempt 4: Numeric device ID');
    if (await _trySaveRouteApproach4(
        deviceId, routeCoordinates, routePoints, id, routeName)) {
      return true;
    }

    debugPrint('❌ All save route approaches failed');
    return false;
  }

  /// Approach 1: Match React web app structure exactly
  Future<bool> _trySaveRouteApproach1(
      String deviceId,
      List<List<double>>? routeCoordinates,
      List<List<double>> routePoints,
      int? id,
      String? routeName,
      {String? routeHash}) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null) return false;

      final url = Uri.parse('https://api.gromed.in/api/saveRoute/');

      // Use the EXACT structure from React web app
      final requestBody = {
        'device_id': deviceId,
        'route': routeCoordinates ??
            routePoints.map((point) => [point[0], point[1], 0]).toList(),
        'routepoints': routePoints,
      };

      // Add hash if available (critical for API compatibility)
      if (routeHash != null) {
        requestBody['hash'] = routeHash;
        debugPrint('🔑 Including route hash: $routeHash');
      }

      if (id != null) requestBody['id'] = id;
      if (routeName != null) requestBody['route_name'] = routeName;

      debugPrint('🎯 Using React-compatible structure');
      debugPrint('📤 Request body: ${json.encode(requestBody)}');

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Save Route Approach 1 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Route saved successfully with Approach 1');
        return true;
      } else {
        debugPrint(
            '❌ Approach 1 failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Approach 1 error: $e');
      return false;
    }
  }

  /// Approach 2: Simplified format
  Future<bool> _trySaveRouteApproach2(String deviceId, String? route,
      List<List<double>> routePoints, int? id, String? routeName) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null) return false;

      final url = Uri.parse('https://api.gromed.in/api/saveRoute/');

      final requestBody = {
        'device_id': deviceId,
        'routepoints': routePoints,
      };

      if (route != null) requestBody['route'] = route;
      if (id != null) requestBody['id'] = id;
      if (routeName != null) requestBody['route_name'] = routeName;

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Save Route Approach 2 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Route saved successfully with Approach 2');
        return true;
      } else {
        debugPrint(
            '❌ Approach 2 failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Approach 2 error: $e');
      return false;
    }
  }

  /// Approach 3: Minimal required fields only
  Future<bool> _trySaveRouteApproach3(
      String deviceId, List<List<double>> routePoints, String? routeName) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null) return false;

      final url = Uri.parse('https://api.gromed.in/api/saveRoute/');

      final requestBody = {
        'device_id': deviceId,
        'routepoints': routePoints,
      };

      if (routeName != null) requestBody['route_name'] = routeName;

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Save Route Approach 3 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Route saved successfully with Approach 3');
        return true;
      } else {
        debugPrint(
            '❌ Approach 3 failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Approach 3 error: $e');
      return false;
    }
  }

  /// Approach 4: Try with numeric device ID mapping
  Future<bool> _trySaveRouteApproach4(
      dynamic deviceId,
      List<List<double>>? routeCoordinates,
      List<List<double>> routePoints,
      int? id,
      String? routeName) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null) return false;

      // Get actual numeric device ID
      final numericDeviceId = await _getActualDeviceId(
          deviceId is int ? deviceId : int.tryParse(deviceId.toString()) ?? 1);

      final url = Uri.parse('https://api.gromed.in/api/saveRoute/');

      final requestBody = {
        'device_id': numericDeviceId.toString(),
        'route': routeCoordinates ??
            routePoints.map((point) => [point[0], point[1], 0]).toList(),
        'routepoints': routePoints,
      };

      if (id != null) requestBody['id'] = id;
      if (routeName != null) requestBody['route_name'] = routeName;

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Save Route Approach 4 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Route saved successfully with Approach 4');
        return true;
      } else {
        debugPrint(
            '❌ Approach 4 failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Approach 4 error: $e');
      return false;
    }
  }

  /// Delete route (POST request)
  Future<bool> deleteRoute({required int routeId}) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ Delete Route API: No authentication token available');
        return false;
      }

      final url = Uri.parse('https://api.gromed.in/api/deleteRoute/');

      final requestBody = {
        'id': routeId,
      };

      debugPrint('🔄 Deleting route: $routeId');
      debugPrint('📡 POST request to: $url');

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Delete Route Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Route deleted successfully');
        return true;
      } else {
        debugPrint(
            '❌ Delete Route Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Delete Route API Error: $e');
      return false;
    }
  }

  /// Get routes for a device with multiple fallback approaches
  Future<List<RouteData>> getRoutes({required dynamic deviceId}) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ Get Routes API: No authentication token available');
        return [];
      }

      // Try multiple approaches for getting routes
      return await _tryMultipleGetRoutesApproaches(deviceId, token);
    } catch (e) {
      debugPrint('❌ Get Routes API Error: $e');
      return [];
    }
  }

  /// Try multiple API approaches for getting routes
  Future<List<RouteData>> _tryMultipleGetRoutesApproaches(
      dynamic deviceId, String token) async {
    // Approach 3: Try with deviceId field name (try this first as it might be correct)
    debugPrint('🚀 GetRoutes Attempt 1: deviceId field name');
    List<RouteData> routes = await _tryGetRoutesApproach3(deviceId, token);
    if (routes.isNotEmpty) return routes;

    // Approach 1: Try with device_id field name
    debugPrint('🚀 GetRoutes Attempt 2: device_id field name');
    routes = await _tryGetRoutesApproach1(deviceId, token);
    if (routes.isNotEmpty) return routes;

    // Approach 2: Try with numeric device ID
    debugPrint('🚀 GetRoutes Attempt 3: Numeric device ID');
    routes = await _tryGetRoutesApproach2(deviceId, token);
    if (routes.isNotEmpty) return routes;

    debugPrint('❌ All get routes approaches returned empty');
    return [];
  }

  /// Approach 1: Device ID in JSON request body (server expects this format)
  Future<List<RouteData>> _tryGetRoutesApproach1(
      dynamic deviceId, String token) async {
    try {
      String deviceIdStr;
      if (deviceId is String) {
        deviceIdStr = deviceId;
      } else {
        deviceIdStr = deviceId.toString();
      }

      final url = Uri.parse('https://api.gromed.in/api/getRoute/');

      // Send device_id in request body as JSON (like other APIs)
      final requestBody = {'device_id': deviceIdStr};

      debugPrint(
          '🔍 GetRoutes Approach 1 - Device ID: $deviceIdStr (type: ${deviceId.runtimeType})');
      debugPrint('📡 POST request to: $url');
      debugPrint('📤 Request body: $requestBody');
      debugPrint('🔑 Using token: ${token.substring(0, 10)}...');

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Get Routes Response: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Approach 1: Routes retrieved successfully');
        debugPrint('📄 Raw response: ${response.body}');
        return _parseRouteData(data);
      } else {
        debugPrint('❌ Approach 1 failed with status ${response.statusCode}');
        debugPrint('📄 Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Approach 1 failed: $e');
      return [];
    }
  }

  /// Approach 2: Numeric device ID in JSON request body
  Future<List<RouteData>> _tryGetRoutesApproach2(
      dynamic originalDeviceId, String token) async {
    try {
      // Try to map IMEI to numeric ID
      int numericDeviceId;
      if (originalDeviceId is String) {
        numericDeviceId = originalDeviceId.hashCode.abs() % 10000 + 1;
        debugPrint(
            '🔄 Mapped IMEI $originalDeviceId to numeric: $numericDeviceId');
      } else {
        numericDeviceId = int.tryParse(originalDeviceId.toString()) ?? 1;
      }

      final url = Uri.parse('https://api.gromed.in/api/getRoute/');

      // Send device_id in request body
      final requestBody = {'device_id': numericDeviceId.toString()};

      debugPrint('📡 POST request to: $url');
      debugPrint('📤 Request body: $requestBody');

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Approach 2 Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Approach 2: Routes retrieved with numeric ID');
        return _parseRouteData(data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Approach 2 failed: $e');
      return [];
    }
  }

  /// Approach 3: Alternative field name in JSON request body
  Future<List<RouteData>> _tryGetRoutesApproach3(
      dynamic deviceId, String token) async {
    try {
      String deviceIdStr = deviceId is String ? deviceId : deviceId.toString();

      final url = Uri.parse('https://api.gromed.in/api/getRoute/');

      // Send device_id in request body (standard field name)
      final requestBody = {'device_id': deviceIdStr};

      debugPrint('📡 POST request to: $url');
      debugPrint('📤 Request body: $requestBody');

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Approach 3 Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Approach 3: Routes retrieved with simplified format');
        return _parseRouteData(data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Approach 3 failed: $e');
      return [];
    }
  }

  /// Parse route data from API response
  List<RouteData> _parseRouteData(dynamic data) {
    try {
      if (data is List) {
        return data.map((item) => RouteData.fromJson(item)).toList();
      } else if (data is Map && data.containsKey('routes')) {
        final routes = data['routes'] as List;
        return routes.map((item) => RouteData.fromJson(item)).toList();
      } else if (data is Map && data.containsKey('route')) {
        final routes = data['route'] as List;
        return routes.map((item) => RouteData.fromJson(item)).toList();
      } else if (data is Map && data.containsKey('data')) {
        final innerData = data['data'];
        if (innerData is List) {
          return innerData.map((item) => RouteData.fromJson(item)).toList();
        }
      }
      debugPrint('⚠️ Unknown response format for routes: $data');
      return [];
    } catch (e) {
      debugPrint('❌ Error parsing route data: $e');
      return [];
    }
  }

  /// Get route path from points (POST request)
  Future<RoutePathResponse?> getRoutePath({
    required List<List<double>> points,
  }) async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ Get Route Path API: No authentication token available');
        return null;
      }

      // Validate coordinates before sending
      if (points.length < 2) {
        debugPrint('❌ Need at least 2 points for routing');
        return null;
      }

      // Check if coordinates are reasonable (Delhi area bounds)
      for (final point in points) {
        if (point.length < 2) {
          debugPrint('❌ Invalid coordinate format: $point');
          return null;
        }
        final lng = point[0];
        final lat = point[1];
        if (lng < 76.0 || lng > 78.0 || lat < 28.0 || lat > 29.0) {
          debugPrint('⚠️ Coordinates outside Delhi area: [$lng, $lat]');
          // Don't return null, just warn - the API might handle other areas
        }
      }

      final url = Uri.parse('https://api.gromed.in/api/get_routePath/');

      final requestBody = {
        'points': points
            .map((point) => [point[0], point[1]])
            .toList(), // Keep [lng, lat] format as expected by API
      };

      debugPrint('🔄 Getting route path for ${points.length} points');
      debugPrint('📍 Route points for API (lng,lat): $requestBody');
      debugPrint('📡 POST request to: $url');

      final response = await _client
          .post(
            url,
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'eDisha/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Get Route Path Response: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Route path retrieved successfully');
        debugPrint('📄 Parsed response data: $data');
        final responseObj = RoutePathResponse.fromJson(data);
        debugPrint(
            '📄 RoutePath object: routePath=${responseObj.routePath}, coordinates=${responseObj.coordinates}');
        return responseObj;
      } else {
        debugPrint(
            '❌ Get Route Path Error: ${response.statusCode} - ${response.body}');
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['error'] ?? errorData['message'] ?? 'Unknown error';
          debugPrint('❌ Error details: $errorMessage');

          // If it's a temporary routing service issue, we should still allow the route to be saved
          // The route will just show as straight lines instead of actual driving paths
          if (errorMessage.contains('Unable to extract path') ||
              errorMessage.contains('routing service') ||
              errorMessage.contains('try again later')) {
            debugPrint(
                '⚠️ Routing service temporarily unavailable - will save route with straight lines');
          }
        } catch (e) {
          debugPrint('❌ Could not parse error response: $e');
        }
        return null;
      }
    } catch (e) {
      debugPrint('❌ Get Route Path API Error: $e');
      return null;
    }
  }

  /// Get actual device ID from GPS service vehicles
  Future<int> _getActualDeviceId(int requestedDeviceId) async {
    try {
      // Get available vehicles from GPS service
      final gpsService = GPSTrackingService();
      final vehicles = await gpsService.fetchGPSData();

      if (vehicles.isEmpty) {
        debugPrint(
            '⚠️ No vehicles available, using requested device ID: $requestedDeviceId');
        return requestedDeviceId;
      }

      // Find the vehicle with the matching device ID or IMEI
      final vehicle = vehicles.firstWhere(
        (v) =>
            v.id == requestedDeviceId.toString() ||
            int.tryParse(v.id) == requestedDeviceId,
        orElse: () => vehicles.first, // Default to first vehicle if not found
      );

      // Try to extract a numeric device ID from the vehicle
      final vehicleId = vehicle.id;
      final numericId = int.tryParse(vehicleId);

      if (numericId != null && numericId > 0) {
        debugPrint('✅ Using numeric device ID from vehicle: $numericId');
        return numericId;
      }

      // If IMEI, map to sequential device ID (1, 2, 3, etc.)
      final vehicleIndex = vehicles.indexOf(vehicle);
      final mappedDeviceId = vehicleIndex + 1; // 1-based indexing

      debugPrint('🔄 Mapped IMEI ${vehicleId} to device ID: $mappedDeviceId');
      return mappedDeviceId;
    } catch (e) {
      debugPrint('❌ Error getting actual device ID: $e');
      return requestedDeviceId; // Fallback to requested ID
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Route Response Model
class RouteResponse {
  final bool success;
  final String? message;
  final dynamic data;

  RouteResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      success: json['success'] ?? true,
      message: json['message']?.toString(),
      data: json['data'],
    );
  }
}

/// Route Data Model
class RouteData {
  final int id;
  final int deviceId;
  final String? routeName;
  final String? route;
  final List<List<double>> routePoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RouteData({
    required this.id,
    required this.deviceId,
    this.routeName,
    this.route,
    required this.routePoints,
    this.createdAt,
    this.updatedAt,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    debugPrint('🔧 Parsing RouteData for route ID: ${json['id']}');
    List<List<double>> points = [];

    // First priority: routepoints field (already parsed LatLng objects from API)
    if (json['routepoints'] != null) {
      final routePointsData = json['routepoints'];
      if (routePointsData is String) {
        // The API sometimes returns routepoints as a string representation of LatLng objects
        // For now, fall back to the route field
        debugPrint(
            '⚠️ routepoints is string format, trying route field instead');
      } else if (routePointsData is List) {
        // If it's already a list of LatLng objects, we need to convert them to [lng, lat, elevation] format
        debugPrint(
            '📍 Found routepoints as List, converting to coordinate format');
        points = routePointsData
            .map((point) {
              if (point is List && point.length >= 2) {
                // Assume [lat, lng] or [lng, lat] format - try both
                return [
                  (point[1] as num).toDouble(),
                  (point[0] as num).toDouble(),
                  point.length > 2 ? (point[2] as num).toDouble() : 0.0
                ]; // [lng, lat, elevation]
              }
              return <double>[];
            })
            .cast<List<double>>()
            .toList();
      }
    }

    // Second priority: route field which contains a JSON string of coordinates
    if (points.isEmpty && json['route'] != null) {
      final routeData = json['route'];
      if (routeData is String) {
        try {
          debugPrint('📄 Parsing route field as JSON string');
          // Parse the JSON string in the route field
          final parsedRoute = jsonDecode(routeData);
          if (parsedRoute is List) {
            points = parsedRoute.map((point) {
              if (point is List) {
                return point
                    .map((coord) => double.tryParse(coord.toString()) ?? 0.0)
                    .toList();
              }
              return <double>[];
            }).toList();
            debugPrint(
                '✅ Successfully parsed ${points.length} coordinate points from route field');
          }
        } catch (e) {
          debugPrint('❌ Error parsing route string: $e');
        }
      }
    }

    final routeData = RouteData(
      id: json['id'] ?? 0,
      deviceId: json['device_id'] ?? 0,
      routeName: json['route_name']?.toString(),
      route: json['route']?.toString(),
      routePoints: points,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
    debugPrint(
        '✅ Route ${routeData.id} parsed with ${routeData.routePoints.length} points');
    return routeData;
  }
}

/// Route Path Response Model
class RoutePathResponse {
  final String? routePath;
  final List<List<double>>? coordinates;
  final double? distance;
  final double? duration;
  final String? hash; // Added hash field for API compatibility

  RoutePathResponse({
    this.routePath,
    this.coordinates,
    this.distance,
    this.duration,
    this.hash,
  });

  factory RoutePathResponse.fromJson(Map<String, dynamic> json) {
    List<List<double>>? coords;
    String? routePath;

    // Try to extract coordinates from the nested response structure
    if (json['data'] != null && json['data']['paths'] != null) {
      final paths = json['data']['paths'] as List;
      if (paths.isNotEmpty) {
        final path = paths[0];
        if (path['points'] != null && path['points']['coordinates'] != null) {
          final coordsData = path['points']['coordinates'] as List;
          coords = coordsData.map((coord) {
            if (coord is List && coord.length >= 2) {
              // Keep [lng, lat, elevation] format as returned by API, handle int/double conversion
              return [
                (coord[0] is int
                    ? (coord[0] as int).toDouble()
                    : coord[0] as double),
                (coord[1] is int
                    ? (coord[1] as int).toDouble()
                    : coord[1] as double),
                coord.length > 2
                    ? (coord[2] is int
                        ? (coord[2] as int).toDouble()
                        : coord[2] as double)
                    : 0.0
              ];
            }
            return <double>[];
          }).toList();

          // Create route path string from coordinates (lat,lng format for string)
          if (coords.isNotEmpty) {
            routePath =
                coords.map((coord) => '${coord[1]},${coord[0]}').join(';');
          }
        }
      }
    }

    return RoutePathResponse(
      routePath: routePath ??
          json['route_path']?.toString() ??
          json['path']?.toString(),
      coordinates: coords,
      distance: double.tryParse(json['distance']?.toString() ?? '0'),
      duration: double.tryParse(json['duration']?.toString() ?? '0'),
      hash: json['hash']?.toString(), // Extract hash from response
    );
  }
}