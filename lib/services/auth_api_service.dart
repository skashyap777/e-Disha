import 'dart:convert';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

/// Authentication API service for e-Disha with full backend integration
class AuthApiService {
  static const String baseUrl = 'https://api.gromed.in';
  static const String loginEndpoint = '/api/user_login_app/';
  static const String validateOtpEndpoint = '/api/validate_otp/';
  static const String resendOtpEndpoint = '/api/send_sms_otp/';
  static const String logoutEndpoint = '/api/user_logout/';

  // Network configuration - Increased timeout for server issues
  static const Duration _defaultTimeout = Duration(seconds: 45);
  static const Duration _retryDelay = Duration(seconds: 3);
  static const int _maxRetries = 3;
  static const Duration _connectionCheckTimeout = Duration(seconds: 5);

  // RSA Public Key for OTP & password encryption
  static const String publicKeyPem = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6hUN7F1LHsJu7fCYMd2S
BOot3n++YPA4I19PJxVvPmNbv2Smm8orCnlp5daNAKy8HtuLHXclSmVSVL6M9J8f
2E2mUl0zlfs34KycxNs6JBV8+6MZSlsW6SltwKTuhWCcAVA5sK9nL358MclDwKZv
3Ya4TcNVwDyZlnT/SMJvRwBi/eHtYep4giKB7mnrMeCSL3QdRMoSPX/ohcQBIRsD
Q/rPeb4epepHB6yy3iQ7d9+jBlxCSv5Kkigu07kcCKzDNKtuO9WbNkg/46cStGLD
mlnScYUaN7TJLBpzqBHkliMoexKcYlPRG/+ApqiGoB9hztb1gfwBdTlOUhJtnN0y
UwIDAQAB
-----END PUBLIC KEY-----''';

  // OTP token (updated based on working logs)
  static const String otpToken = '473051cc58';

  // API Key for sessionid header - REMOVED (unknown origin)
  static const String apiKey = '';

  // Authorization token for API calls - Updated based on actual usage
  static const String authorizationToken =
      '2383117992c9b5bcfd8864ab109ad0c77b716cb0';

  // Tokens for authentication (persisted in shared preferences)
  static const String _loginTokenKey = 'login_token';
  static const String _otpTokenKey = 'otp_token';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _userMobileKey = 'user_mobile';
  String? _loginToken;
  String? _otpToken;

  /// Load tokens from shared preferences
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _loginToken = prefs.getString(_loginTokenKey);
    _otpToken = prefs.getString(_otpTokenKey);
    print(
        '🔄 TOKENS LOADED: login=${_loginToken?.substring(0, 10)}, otp=${_otpToken?.substring(0, 10)}');
  }

  /// Save login token to shared preferences
  Future<void> _saveLoginToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTokenKey, token);
    _loginToken = token;
    print('💾 LOGIN TOKEN SAVED: ${token.substring(0, 10)}...');
  }

  /// Save OTP token to shared preferences
  Future<void> _saveOtpToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_otpTokenKey, token);
    _otpToken = token;
    print('💾 OTP TOKEN SAVED: ${token.substring(0, 10)}...');
  }

  /// Clear all tokens and authentication state
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginTokenKey);
    await prefs.remove(_otpTokenKey);
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_userMobileKey);
    _loginToken = null;
    _otpToken = null;
    print('🗑️ ALL TOKENS AND AUTH STATE CLEARED');
  }

  /// Mark user as authenticated (called after successful OTP verification)
  Future<void> setAuthenticated(String mobileNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, true);
    await prefs.setString(_userMobileKey, mobileNumber);
    print('✅ USER MARKED AS AUTHENTICATED: $mobileNumber');
  }

  /// Get stored mobile number
  Future<String?> getStoredMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userMobileKey);
  }

  /// Get current authentication token for use in other APIs
  /// Returns OTP token if available, otherwise login token, otherwise authorization token
  Future<String?> getCurrentAuthToken() async {
    await _loadTokens();
    final token = _otpToken ?? _loginToken ?? authorizationToken;
    print('🔑 CURRENT AUTH TOKEN: ${token?.substring(0, 10)}...');
    print(
        '🔍 TOKEN DEBUG: OTP=${_otpToken?.substring(0, 10)}..., Login=${_loginToken?.substring(0, 10)}..., Auth=${authorizationToken.substring(0, 10)}...');
    return token;
  }

  /// Check network connectivity with multiple fallbacks
  Future<bool> _checkConnectivity() async {
    try {
      // First try Google DNS
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(_connectionCheckTimeout);
      if (result.isNotEmpty) return true;
      
      // Fallback to Cloudflare DNS
      final result2 = await InternetAddress.lookup('1.1.1.1')
          .timeout(_connectionCheckTimeout);
      if (result2.isNotEmpty) return true;
      
      // Final fallback to Google
      final result3 = await InternetAddress.lookup('google.com')
          .timeout(_connectionCheckTimeout);
      return result3.isNotEmpty && result3[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('🌐 CONNECTIVITY CHECK FAILED: $e');
      return false;
    }
  }

  /// Enhanced HTTP client with retry logic
  Future<http.Response> _makeHttpRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    String? body, {
    int retryCount = 0,
  }) async {
    try {
      late http.Response response;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body,
          ).timeout(_defaultTimeout);
          break;
        case 'GET':
          response = await http.get(
            url,
            headers: headers,
          ).timeout(_defaultTimeout);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      // Check if we got a server error that might be temporary
      if (response.statusCode >= 500 && retryCount < _maxRetries) {
        print('⚠️ SERVER ERROR ${response.statusCode}, retrying in ${_retryDelay.inSeconds}s... (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(_retryDelay);
        return _makeHttpRequest(method, url, headers, body, retryCount: retryCount + 1);
      }

      return response;
    } on SocketException catch (e) {
      print('🌐 SOCKET EXCEPTION: $e');
      if (retryCount < _maxRetries) {
        print('🔄 RETRYING in ${_retryDelay.inSeconds}s... (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(_retryDelay);
        return _makeHttpRequest(method, url, headers, body, retryCount: retryCount + 1);
      }
      throw Exception('Network connection failed after $_maxRetries attempts');
    } on TimeoutException catch (e) {
      print('⏱️ TIMEOUT EXCEPTION: $e');
      if (retryCount < _maxRetries) {
        print('🔄 RETRYING in ${_retryDelay.inSeconds}s... (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(_retryDelay);
        return _makeHttpRequest(method, url, headers, body, retryCount: retryCount + 1);
      }
      throw Exception('Request timed out after $_maxRetries attempts');
    } catch (e) {
      print('❌ HTTP REQUEST ERROR: $e');
      if (retryCount < _maxRetries && _isRetryableError(e)) {
        print('🔄 RETRYING in ${_retryDelay.inSeconds}s... (attempt ${retryCount + 1}/$_maxRetries)');
        await Future.delayed(_retryDelay);
        return _makeHttpRequest(method, url, headers, body, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  /// Check if user is authenticated (has valid auth state AND tokens)
  Future<bool> isAuthenticated() async {
    await _loadTokens();
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticatedFlag = prefs.getBool(_isAuthenticatedKey) ?? false;
    final token = _otpToken ?? _loginToken;
    final hasValidAuth = isAuthenticatedFlag && token != null && token.isNotEmpty;
    print('🔍 AUTH CHECK: authenticated=$isAuthenticatedFlag, hasToken=${token != null}, result=$hasValidAuth');
    return hasValidAuth;
  }

  /// Check if an error is retryable
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('network') ||
           errorString.contains('socket');
  }

  /// Encrypt text using RSA public key (OAEP padding)
  String _encryptRsa(String text) {
    try {
      final parsedPublicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
      final encrypter = encrypt.Encrypter(
        encrypt.RSA(
          publicKey: parsedPublicKey,
          encoding:
              encrypt.RSAEncoding.OAEP, // ✅ OAEP padding for better security
        ),
      );

      final encrypted = encrypter.encrypt(text);
      return encrypted.base64; // ✅ Base64-encoded string for API
    } catch (e) {
      print("❌ RSA encryption error: $e");
      rethrow;
    }
  }

  /// Send login request to initiate OTP
  Future<Map<String, dynamic>> login(
      String mobileNumber, String password) async {
    print('🔐 LOGIN API CALL: Sending login request for mobile: $mobileNumber');
    
    // Check connectivity first
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network settings.',
        'data': null
      };
    }
    
    try {
      final url = Uri.parse('$baseUrl$loginEndpoint');
      print('📡 LOGIN URL: $url');

      final encryptedPassword = _encryptRsa(password);
      print('🔒 ENCRYPTED PASSWORD: $encryptedPassword');

      // Build headers conditionally
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'eDisha/1.0',
      };

      // Add sessionid header with the provided API key
      if (apiKey.isNotEmpty) {
        headers['sessionid'] = apiKey;
      }

      // Debug: Show request details
      print('📤 REQUEST HEADERS: $headers');
      final requestBody = jsonEncode({
        'username': mobileNumber,
        'password': encryptedPassword,
      });
      print('📤 REQUEST BODY: $requestBody');

      final response = await _makeHttpRequest(
        'POST',
        url,
        headers,
        requestBody,
      );

      print(
          '📥 LOGIN RESPONSE: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 LOGIN RESPONSE DATA: $data');

        // Check for token in various possible fields
        final token = data['token'] ??
            data['session_token'] ??
            data['auth_token'] ??
            data['access_token'];
        print('🔑 EXTRACTED TOKEN: $token');

        if (token != null && token.toString().isNotEmpty) {
          await _saveLoginToken(token);
          print(
              '✅ LOGIN SUCCESS: Token received: ${token.substring(0, 10)}...');
          return {
            'success': true,
            'data': data,
            'message': data['status'] ?? data['message'] ?? 'Login successful'
          };
        }

        String message =
            (data['message'] ?? data['status'] ?? '').toLowerCase();
        if (message.contains('success') ||
            message.contains('otp sent') ||
            message.contains('verification')) {
          print('✅ LOGIN SUCCESS: Success message detected');
          return {
            'success': true,
            'data': data,
            'message': data['status'] ?? data['message'] ?? 'Login successful'
          };
        }

        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Login failed',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
          'data': null
        };
      }
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      String errorMessage = 'Network error occurred';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Server is taking too long to respond. Please try again.';
      } else if (e.toString().contains('connection')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      }
      
      return {
        'success': false, 
        'message': errorMessage, 
        'data': null
      };
    }
  }

  /// Validate OTP
  Future<Map<String, dynamic>> validateOtp(String otp, String mobileNumber) async {
    print('🔐 OTP VALIDATION API CALL: Validating OTP: $otp for mobile: $mobileNumber');
    try {
      // Load tokens from shared preferences
      await _loadTokens();

      final url = Uri.parse('$baseUrl$validateOtpEndpoint');
      print('📡 OTP URL: $url');

      final encryptedOtp = _encryptRsa(otp);
      print('🔒 ENCRYPTED OTP: $encryptedOtp');

      // Use the login token from successful login, fallback to hardcoded token
      final tokenToUse = _loginToken ?? otpToken;
      print('🔑 OTP TOKEN TO USE: $tokenToUse (login_token: $_loginToken)');

      // Build headers with proper authentication
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $tokenToUse', // Use Token format (same as other APIs)
        'X-API-Token': tokenToUse,
        'sessionid': apiKey, // Use the API key for sessionid
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'token': tokenToUse, // Send token in body
          'otp': encryptedOtp, // Send OTP in body
        }),
      );

      print(
          '📥 OTP RESPONSE: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] ?? data['status'] ?? '';
        final isSuccess = !message.toLowerCase().contains('invalid');

        if (isSuccess) {
          // Save OTP token if provided
          if (data['token'] != null && data['token'].toString().isNotEmpty) {
            await _saveOtpToken(data['token']);
          }
          // Mark user as authenticated after successful OTP verification
          await setAuthenticated(mobileNumber);
          print('✅ OTP VERIFIED & USER AUTHENTICATED');
          return {
            'success': true,
            'data': data,
            'message': data['status'] ?? 'Login Successful'
          };
        } else {
          return {'success': false, 'message': message, 'data': data};
        }
      } else {
        return {
          'success': false,
          'message': 'Invalid OTP: ${response.statusCode}',
          'data': null
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e', 'data': null};
    }
  }

  /// Resend OTP to user's mobile number
  Future<Map<String, dynamic>> resendOtp(String mobileNumber) async {
    print('📱 RESEND OTP API CALL: Resending OTP to mobile: $mobileNumber');
    try {
      // Load tokens from shared preferences
      await _loadTokens();

      final url = Uri.parse('$baseUrl$resendOtpEndpoint');
      print('📡 RESEND OTP URL: $url');

      // Use the login token from successful login
      final tokenToUse = _loginToken;
      if (tokenToUse == null || tokenToUse.isEmpty) {
        return {
          'success': false,
          'message': 'No login token available. Please login first.'
        };
      }

      print('🔑 RESEND OTP TOKEN: ${tokenToUse.substring(0, 10)}...');

      // Build headers with proper authentication
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $tokenToUse', // Use Token format (same as other APIs)
        'X-API-Token': tokenToUse,
        'sessionid': apiKey, // Use the API key for sessionid
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'token': tokenToUse,
          'mobile': mobileNumber,
        }),
      );

      print(
          '📥 RESEND OTP RESPONSE: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['message'] ?? data['status'] ?? '';
        final isSuccess = !message.toLowerCase().contains('invalid') &&
            !message.toLowerCase().contains('error');

        if (isSuccess) {
          print('✅ RESEND OTP SUCCESS: OTP resent successfully');
          return {
            'success': true,
            'data': data,
            'message':
                data['message'] ?? data['status'] ?? 'OTP resent successfully'
          };
        } else {
          return {
            'success': false,
            'message':
                data['message'] ?? data['status'] ?? 'Failed to resend OTP',
            'data': data
          };
        }
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              'Failed to resend OTP: ${response.statusCode}',
          'data': errorData
        };
      }
    } catch (e) {
      print('❌ RESEND OTP ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logout() async {
    print('🔐 LOGOUT API CALL: Logging out user');
    try {
      // Load tokens from shared preferences
      await _loadTokens();

      final url = Uri.parse('$baseUrl$logoutEndpoint');
      print('📡 LOGOUT URL: $url');

      // Use the current auth token with priority system
      final tokenToUse = await getCurrentAuthToken();
      if (tokenToUse == null || tokenToUse.isEmpty) {
        print('❌ LOGOUT: No authentication token available');
        return {'success': false, 'message': 'Authentication token not found.'};
      }
      print('🔑 LOGOUT TOKEN: ${tokenToUse.substring(0, 10)}...');

      // Build headers with proper authentication
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $tokenToUse', // Use Token format (same as other APIs)
        'X-API-Token': tokenToUse, // Also try custom header
        'sessionid': apiKey, // Use the API key for sessionid
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'token': tokenToUse}),
      );

      print(
          '📥 LOGOUT RESPONSE: Status ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Clear tokens after successful logout
        await clearTokens();
        return {
          'success': true,
          'data': data,
          'message': 'Logged out successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Logout failed: ${response.statusCode}',
          'data': null
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e', 'data': null};
    }
  }
}