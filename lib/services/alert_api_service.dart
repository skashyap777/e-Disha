import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edisha/services/auth_api_service.dart';

class AlertApiService {
  static const String baseUrl = 'https://api.gromed.in';
  static const String alertListEndpoint = '/api/alart_list/';

  final AuthApiService _authApiService = AuthApiService();

  Future<Map<String, dynamic>> fetchAlerts({String? deviceId}) async {
    print('🔐 ALERT API CALL: Fetching alerts');
    try {
      final token = await _authApiService.getCurrentAuthToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Authentication token not found.'};
      }

      final url = Uri.parse('$baseUrl$alertListEndpoint');
      print('📡 ALERT URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      };

      final requestBody = deviceId != null ? {'device_id': deviceId} : {};

      print('📤 REQUEST HEADERS: $headers');
      print('📤 REQUEST BODY: $requestBody');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 30));

      print(
          '📥 ALERT RESPONSE: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 ALERT RESPONSE DATA: $data');
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch alerts: ${response.statusCode}',
          'data': null
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e', 'data': null};
    }
  }
}