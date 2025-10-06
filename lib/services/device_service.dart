import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:edisha/services/auth_api_service.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal() {
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
    debugPrint('🔧 Device Service HTTP client initialized for gromed.in APIs');
  }

  /// Get owner/device list from API (matching React TaggingService.getOwnerList)
  Future<List<DeviceOwnerData>> getOwnerList() async {
    try {
      final token = await _authService.getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ Owner List API: No authentication token available');
        return [];
      }

      final url = Uri.parse('https://api.gromed.in/api/tag/tag_ownerlist/');

      debugPrint('🔄 Getting owner list from API');
      debugPrint('📡 POST request to: $url');
      debugPrint('🔑 Using auth token: ${token.substring(0, 8)}...');

      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'eDisha/1.0',
        },
        body: json.encode({}), // Empty body for POST request
      ).timeout(const Duration(seconds: 30));

      debugPrint('📊 Owner List Response: ${response.statusCode}');
      debugPrint('📄 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        List<dynamic> data = [];
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'] ?? [];
        }

        debugPrint('✅ Found ${data.length} devices in owner list');

        final devices = data.map((item) {
          debugPrint('🚗 Processing device: ${item['vehicle_reg_no']} (ID: ${item['device']?['id']})');
          return DeviceOwnerData.fromJson(item);
        }).toList();

        debugPrint('✅ Successfully parsed ${devices.length} device owners');
        return devices;
      } else {
        debugPrint('❌ Owner List Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Owner List API Error: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Device Owner Data Model (matching React structure)
class DeviceOwnerData {
  final String id;
  final String vehicleRegNo;
  final DeviceInfo device;
  final String? ownerName;
  final String? contactNumber;

  DeviceOwnerData({
    required this.id,
    required this.vehicleRegNo,
    required this.device,
    this.ownerName,
    this.contactNumber,
  });

  factory DeviceOwnerData.fromJson(Map<String, dynamic> json) {
    return DeviceOwnerData(
      id: json['id']?.toString() ?? '',
      vehicleRegNo: json['vehicle_reg_no']?.toString() ?? '',
      device: DeviceInfo.fromJson(json['device'] ?? {}),
      ownerName: json['owner_name']?.toString(),
      contactNumber: json['contact_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_reg_no': vehicleRegNo,
      'device': device.toJson(),
      'owner_name': ownerName,
      'contact_number': contactNumber,
    };
  }

  @override
  String toString() {
    return 'DeviceOwnerData(id: $id, vehicleRegNo: $vehicleRegNo, deviceId: ${device.id})';
  }
}

/// Device Info Model (nested device object)
class DeviceInfo {
  final String id;
  final String? imei;
  final String? simNumber;
  final String? deviceModel;
  final String? status;

  DeviceInfo({
    required this.id,
    this.imei,
    this.simNumber,
    this.deviceModel,
    this.status,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id']?.toString() ?? '',
      imei: json['imei']?.toString(),
      simNumber: json['sim_number']?.toString(),
      deviceModel: json['device_model']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'sim_number': simNumber,
      'device_model': deviceModel,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'DeviceInfo(id: $id, imei: $imei)';
  }
}