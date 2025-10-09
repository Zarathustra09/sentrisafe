import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sentrisafe/constants.dart';

class AuthService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Helper method for consistent logging
  static void _log(String message) {
    print('[AuthService] $message');
  }

  static void _logError(String operation, dynamic error) {
    print('[AuthService ERROR] $operation: $error');
  }

  static Future<void> _saveAuthData(String token, int userId) async {
    try {
      _log('Saving auth data - UserId: $userId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt('user_id', userId);
      _log('Auth data saved successfully');
    } catch (e) {
      _logError('_saveAuthData', e);
      rethrow;
    }
  }

  static Future<void> _clearAuthData() async {
    try {
      _log('Clearing auth data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      _log('Auth data cleared successfully');
    } catch (e) {
      _logError('_clearAuthData', e);
      rethrow;
    }
  }

  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      _log('Retrieved auth token: ${token != null ? 'Found' : 'Not found'}');
      return token;
    } catch (e) {
      _logError('getAuthToken', e);
      return null;
    }
  }

  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      _log('Retrieved user ID: ${userId ?? 'Not found'}');
      return userId;
    } catch (e) {
      _logError('getUserId', e);
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final token = await getAuthToken();
      final loggedIn = token != null;
      _log('Login status check: $loggedIn');
      return loggedIn;
    } catch (e) {
      _logError('isLoggedIn', e);
      return false;
    }
  }

  static Future<String> _getDeviceType() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceType;
      if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      } else {
        deviceType = 'unknown';
      }
      _log('Device type detected: $deviceType');
      return deviceType;
    } catch (e) {
      _logError('_getDeviceType', e);
      return 'unknown';
    }
  }

  static Future<void> _registerFCMToken() async {
    try {
      _log('Starting FCM token registration');

      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _log('FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _log('FCM permission granted, getting token');

        // Get FCM token
        String? fcmToken = await _messaging.getToken();
        _log('FCM token retrieved: ${fcmToken != null ? 'Success' : 'Failed'}');

        if (fcmToken != null) {
          _log('Registering FCM token with server: ${fcmToken.substring(0, 20)}...');
          final result = await registerDeviceToken(fcmToken);
          _log('FCM token registration result: $result');
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _log('FCM token refreshed, registering new token: ${newToken.substring(0, 20)}...');
          registerDeviceToken(newToken);
        });
      } else {
        _log('FCM permission denied');
      }
    } catch (e) {
      _logError('_registerFCMToken', e);
    }
  }

  static Future<Map<String, dynamic>> registerDeviceToken(String token) async {
    try {
      _log('Starting device token registration');

      final authToken = await getAuthToken();
      if (authToken == null) {
        _log('No auth token found for device token registration');
        return {'success': false, 'error': 'No auth token found'};
      }

      final deviceType = await _getDeviceType();
      _log('Registering device token with type: $deviceType');

      final requestBody = {
        'token': token,
        'device_type': deviceType,
      };
      _log('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      _log('Device token registration - Status: ${response.statusCode}');
      _log('Device token registration - Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _log('Device token registered successfully');
        return {'success': true, 'message': data['message']};
      } else {
        _logError('Device token registration failed', 'Status: ${response.statusCode}, Response: ${response.body}');
        return {
          'success': false,
          'error': data['error'] ?? 'Device token registration failed'
        };
      }
    } catch (e) {
      _logError('registerDeviceToken', e);
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> removeDeviceToken() async {
    try {
      _log('Starting device token removal');

      final authToken = await getAuthToken();
      if (authToken == null) {
        _log('No auth token found for device token removal');
        return {'success': false, 'error': 'No auth token found'};
      }

      String? fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        _log('No FCM token found for removal');
        return {'success': false, 'error': 'No FCM token found'};
      }

      _log('Removing FCM token: ${fcmToken.substring(0, 20)}...');

      final response = await http.delete(
        Uri.parse('$baseUrl/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      _log('Device token removal - Status: ${response.statusCode}');
      _log('Device token removal - Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _log('Device token removed successfully');
        return {'success': true, 'message': data['message']};
      } else {
        _logError('Device token removal failed', 'Status: ${response.statusCode}, Response: ${response.body}');
        return {
          'success': false,
          'error': data['error'] ?? 'Device token removal failed'
        };
      }
    } catch (e) {
      _logError('removeDeviceToken', e);
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required File idImage,
  }) async {
    try {
      _log('Starting user registration');
      _log('Registration data - Name: $name, Email: $email');
      _log('ID Image path: ${idImage.path}');

      var uri = Uri.parse('$baseUrl/register');
      _log('Registration URL: $uri');

      var request = http.MultipartRequest('POST', uri);

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation;

      String fileExtension = idImage.path.split('.').last.toLowerCase();
      String mimeType = fileExtension == 'png' ? 'png' : 'jpeg';
      _log('Image file extension: $fileExtension, MIME type: $mimeType');

      request.files.add(
        await http.MultipartFile.fromPath(
          'valid_id_image',
          idImage.path,
          contentType: MediaType('image', mimeType),
        ),
      );

      _log('Sending registration request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      _log('Registration - Status: ${response.statusCode}');
      _log('Registration - Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _log('Registration successful');
        int userId = int.parse(data['user']['id'].toString());
        await _saveAuthData(data['token'], userId);

        // Register FCM token after successful registration
        _log('Starting FCM token registration after registration');
        await _registerFCMToken();

        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
        _logError('Registration failed', 'Status: ${response.statusCode}, Response: ${response.body}');
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': 'Registration failed'},
        };
      }
    } catch (e) {
      _logError('register', e);
      return {
        'success': false,
        'errors': {'general': 'Network error: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      _log('Starting login process');
      _log('Login attempt for email: $email');

      final loginData = {'email': email, 'password': password};
      _log('Login request data: $loginData');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(loginData),
      );

      _log('Login - Status: ${response.statusCode}');
      _log('Login - Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _log('Login successful');
        int userId = int.parse(data['user_id'].toString());
        await _saveAuthData(data['token'], userId);

        // Register FCM token after successful login
        _log('Starting FCM token registration after login');
        await _registerFCMToken();

        return {
          'success': true,
          'token': data['token'],
          'user_id': userId,
        };
      } else {
        _logError('Login failed', 'Status: ${response.statusCode}, Response: ${response.body}');
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      _logError('login', e);
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      _log('Starting logout process');

      final token = await getAuthToken();
      if (token == null) {
        _log('No token found for logout');
        return {'success': false, 'error': 'No token found'};
      }

      // Remove FCM token before logout
      _log('Removing FCM token before logout');
      final tokenRemovalResult = await removeDeviceToken();
      _log('FCM token removal result: $tokenRemovalResult');

      _log('Sending logout request to server');
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      _log('Logout - Status: ${response.statusCode}');
      _log('Logout - Response: ${response.body}');

      await _clearAuthData();

      if (response.statusCode == 200) {
        _log('Logout successful');
        return {'success': true, 'message': 'Logged out successfully'};
      } else {
        _log('Logout request failed, but cleared local data');
        return {'success': true, 'message': 'Logged out locally'};
      }
    } catch (e) {
      _logError('logout', e);
      await _clearAuthData();
      return {'success': true, 'message': 'Logged out locally'};
    }
  }
}