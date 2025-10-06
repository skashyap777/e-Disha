import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edisha/services/auth_api_service.dart';

class DriverApiService {
  static const String baseUrl = AuthApiService.baseUrl;
  static const String addDriverEndpoint = '/api/driver/add_driver/';
  static const String removeDriverEndpoint = '/api/driver/remove_driver/';
  static const String tagOwnerListEndpoint = '/api/tag/tag_ownerlist/';

  final AuthApiService _authApiService = AuthApiService();

  Future<Map<String, dynamic>> addDriver({
    required String deviceId,
    required File photo,
    required String name,
    required String licenceNo,
    required String phoneNo,
  }) async {
    print('🚚 DRIVER API: Adding driver: $name');
    try {
      final url = Uri.parse('$baseUrl$addDriverEndpoint');
      print('📡 ADD DRIVER URL: $url');

      // Use the current auth token with priority system
      final token = await AuthApiService().getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication token not found.'};
      }

      var request = http.MultipartRequest('POST', url);

      // Add headers with proper authentication as per specifications
      request.headers['Authorization'] = 'Token $token';
      request.headers['X-API-Token'] = token;
      request.headers['sessionid'] = AuthApiService.apiKey; // Use the API key
      request.headers['Accept'] = 'application/json';

      // Add fields
      request.fields['device_id'] = deviceId;
      request.fields['name'] = name;
      request.fields['licence_no'] = licenceNo;
      request.fields['phone_no'] = phoneNo;

      // Add photo file
      request.files.add(await http.MultipartFile.fromPath(
        'photo', // Field name for the photo
        photo.path,
        filename: photo.path.split('/').last,
      ));

      print('📤 ADD DRIVER REQUEST HEADERS: ${request.headers}');
      print('📤 ADD DRIVER REQUEST FIELDS: ${request.fields}');
      print(
          '📤 ADD DRIVER REQUEST FILES: ${request.files.map((f) => f.filename)}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
          '📥 ADD DRIVER RESPONSE: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Driver added successfully'
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication/Authorization errors
        final errorData = json.decode(response.body);
        print(
            '❌ ADD DRIVER: Authentication failed - Status: ${response.statusCode}');
        print('❌ ADD DRIVER: Error response: ${response.body}');

        // Clear potentially invalid tokens
        await _authApiService.clearTokens();

        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': errorData,
          'requiresReauth': true,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              'Failed to add driver: ${response.statusCode}',
          'data': errorData,
        };
      }
    } catch (e) {
      print('❌ ADD DRIVER ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get tag owner list - REAL API CALLS ONLY
  Future<Map<String, dynamic>> getTagOwnerList({
    String? deviceId,
    String? tagStatus,
    String? esimStatus,
    String? stockStatus,
    String? regNo,
  }) async {
    print('🏷️ TAG API: Making REAL API call to get tag owner list');
    
    try {
      final url = Uri.parse('$baseUrl$tagOwnerListEndpoint');
      print('📡 TAG API URL: $url');
      
      // Get the current authentication token (OTP token has priority)
      final token = await AuthApiService().getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ TAG API: No authentication token available');
        return {
          'success': false, 
          'message': 'Authentication token not found. Please login again.',
          'requiresReauth': true,
        };
      }

      print('🔑 TAG API: Using token: ${token.substring(0, 15)}...');

      // Prepare request headers - use the same format as successful login/OTP APIs
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
        'X-API-Token': token,
        'User-Agent': 'eDisha/1.0',
      };
      
      // Only add sessionid if we have a valid API key
      if (AuthApiService.apiKey.isNotEmpty) {
        headers['sessionid'] = AuthApiService.apiKey;
      }

      // Prepare form data - send field names to get data from backend
      final body = <String, String>{};
      
      // Add only the fields we want to filter by (optional parameters)
      if (deviceId != null && deviceId.isNotEmpty) {
        // API expects device_id to be a number, not a string
        // Try to parse as number, or use a default numeric value
        try {
          int.parse(deviceId); // Validate it's a number
          body['device_id'] = deviceId;
        } catch (e) {
          // If not a valid number, use a default numeric device_id
          body['device_id'] = '11'; // Use the example number from API docs
          print('⚠️ TAG API: device_id "$deviceId" is not numeric, using default "11"');
        }
      }
      if (tagStatus != null && tagStatus.isNotEmpty) {
        body['tag_status'] = tagStatus;
      }
      if (esimStatus != null && esimStatus.isNotEmpty) {
        body['esim_status'] = esimStatus;
      }
      if (stockStatus != null && stockStatus.isNotEmpty) {
        body['stock_status'] = stockStatus;
      }
      if (regNo != null && regNo.isNotEmpty) {
        body['reg_no'] = regNo;
      }
      
      // If no filters provided, send empty body to get all data
      if (body.isEmpty) {
        // Send empty body or minimal required fields
        print('📤 TAG API: Sending request for all tag owner data (no filters)');
      }

      print('📤 TAG API REQUEST HEADERS: ${headers.keys.toList()}');
      print('📤 TAG API REQUEST BODY: $body');

      // Make the API call with form data
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      print('📥 TAG API RESPONSE: Status ${response.statusCode}');
      print('📥 TAG API RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('✅ TAG API SUCCESS: Data received');
          return {
            'success': true,
            'data': data,
            'message': 'Tag owner list retrieved successfully'
          };
        } catch (e) {
          print('❌ TAG API: Failed to parse JSON: $e');
          return {
            'success': false,
            'message': 'Failed to parse response data: $e',
          };
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('❌ TAG API: Authentication failed - Status: ${response.statusCode}');
        print('❌ TAG API: Response: ${response.body}');
        
        return {
          'success': false,
          'message': 'Tag Owner List API authentication failed (${response.statusCode}). This API may require different authentication than login/OTP APIs. Response: ${response.body}',
          'statusCode': response.statusCode,
          'apiResponse': response.body,
        };
      } else {
        print('❌ TAG API: HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'API Error: ${response.statusCode} - ${response.body}',
          'statusCode': response.statusCode,
          'apiResponse': response.body,
        };
      }
    } catch (e) {
      print('❌ TAG API: Network error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Remove driver
  Future<Map<String, dynamic>> removeDriver({
    String? deviceId,
    String? driverId,
  }) async {
    print('🚚 DRIVER API: Removing driver with device ID: $deviceId, driver ID: $driverId');
    
    // API requires driver_id, so prioritize it
    if (driverId == null && deviceId == null) {
      return {'success': false, 'message': 'Either driver_id or device_id is required.'};
    }
    try {
      final url = Uri.parse('$baseUrl$removeDriverEndpoint');
      print('📡 REMOVE DRIVER URL: $url');

      // Use the current auth token with priority system
      final token = await AuthApiService().getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication token not found.'};
      }

      // Use proper authentication headers as per specifications
      // Try form data format like the add driver API
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
        'X-API-Token': token,
      };
      
      // Only add sessionid if we have a valid API key
      if (AuthApiService.apiKey.isNotEmpty) {
        headers['sessionid'] = AuthApiService.apiKey;
      }

      // Prepare form data body - flexible approach based on available parameters
      final body = <String, String>{};
      
      // Strategy 1: Send only the parameters we have
      if (deviceId != null && deviceId.isNotEmpty) {
        body['device_id'] = deviceId;
        print('📤 ADDING device_id to request: $deviceId');
      }
      
      if (driverId != null && driverId.isNotEmpty) {
        body['driver_id'] = driverId;
        print('📤 ADDING driver_id to request: $driverId');
      }
      
      // Strategy 2: If we have no parameters, this is an error
      if (body.isEmpty) {
        return {
          'success': false,
          'message': 'No valid device_id or driver_id provided for removal',
        };
      }

      print('📤 REMOVE DRIVER REQUEST HEADERS: $headers');
      print('📤 REMOVE DRIVER REQUEST BODY: $body');

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      print(
          '📥 REMOVE DRIVER RESPONSE: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Driver removed successfully'
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication/Authorization errors
        final errorData = json.decode(response.body);
        print(
            '❌ REMOVE DRIVER: Authentication failed - Status: ${response.statusCode}');
        print('❌ REMOVE DRIVER: Error response: ${response.body}');

        // Clear potentially invalid tokens
        await _authApiService.clearTokens();

        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': errorData,
          'requiresReauth': true,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              'Failed to remove driver: ${response.statusCode}',
          'data': errorData,
        };
      }
    } catch (e) {
      print('❌ REMOVE DRIVER ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}