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

  // Keys for local storage
  static const String _fcmTokenKey = 'fcm_token';
  static const String _tokenTimestampKey = 'fcm_token_timestamp';
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  // Helper method for consistent logging
  static void _log(String message) {
    print('[AuthService] $message');
  }

  static void _logError(String operation, dynamic error) {
    print('[AuthService ERROR] $operation: $error');
  }

  // Auth data management
  static Future<void> _saveAuthData(String token, int userId) async {
    try {
      _log('Saving auth data - UserId: $userId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, token);
      await prefs.setInt(_userIdKey, userId);
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
      await prefs.remove(_authTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_fcmTokenKey);
      await prefs.remove(_tokenTimestampKey);
      _log('Auth data cleared successfully');
    } catch (e) {
      _logError('_clearAuthData', e);
      rethrow;
    }
  }

  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
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
      final userId = prefs.getInt(_userIdKey);
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

  // FCM Token management with best practices
  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      await prefs.setString(
          _tokenTimestampKey, DateTime.now().toIso8601String());
      _log('FCM token saved locally with timestamp');
    } catch (e) {
      _logError('_saveFCMToken', e);
    }
  }

  static Future<String?> _getStoredFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      _logError('_getStoredFCMToken', e);
      return null;
    }
  }

  static Future<bool> _isTokenStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_tokenTimestampKey);

      if (timestampString == null) {
        _log('No token timestamp found, considering token stale');
        return true;
      }

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final daysDifference = now.difference(timestamp).inDays;

      _log('Token age: $daysDifference days');

      // Consider token stale if older than 30 days
      return daysDifference > 30;
    } catch (e) {
      _logError('_isTokenStale', e);
      return true; // Consider stale on error
    }
  }

  static Future<String> _getDeviceType() async {
    try {
      String deviceType;
      if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      } else {
        deviceType = 'web';
      }
      _log('Device type detected: $deviceType');
      return deviceType;
    } catch (e) {
      _logError('_getDeviceType', e);
      return 'unknown';
    }
  }

// Update the initializeFCM method
  static Future<void> initializeFCM() async {
    try {
      _log('Initializing FCM');

      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _log('FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _handleTokenRefresh();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_handleTokenRefresh);

        // Set up message handling
        await setupForegroundMessageHandling();
        await setupMessageInteractionHandling();
      } else {
        _log('FCM permission denied');
      }
    } catch (e) {
      _logError('initializeFCM', e);
    }
  }

  static Future<void> _handleTokenRefresh([String? newToken]) async {
    try {
      _log('Handling FCM token refresh');

      String? currentToken = newToken ?? await _messaging.getToken();

      if (currentToken == null) {
        _log('No FCM token available');
        return;
      }

      String? storedToken = await _getStoredFCMToken();
      bool isTokenStale = await _isTokenStale();

      // Update token if it's new, different, or stale
      if (storedToken != currentToken || isTokenStale) {
        _log(
            'Token needs update - New: ${storedToken != currentToken}, Stale: $isTokenStale');
        await _saveFCMToken(currentToken);

        // Only register with server if user is logged in
        if (await isLoggedIn()) {
          await _updateTokenOnServer(currentToken);
        }
      } else {
        _log('Token is current and fresh');
      }
    } catch (e) {
      _logError('_handleTokenRefresh', e);
    }
  }

  static Future<void> _registerFCMToken() async {
    try {
      _log('Starting FCM token registration process');

      if (!await isLoggedIn()) {
        _log('User not logged in, skipping FCM registration');
        return;
      }

      String? fcmToken = await _messaging.getToken();

      if (fcmToken != null) {
        await _saveFCMToken(fcmToken);
        await _updateTokenOnServer(fcmToken);
      } else {
        _log('No FCM token available for registration');
      }
    } catch (e) {
      _logError('_registerFCMToken', e);
    }
  }

  static Future<void> _updateTokenOnServer(String token) async {
    try {
      _log('Updating token on server: ${token.substring(0, 20)}...');

      final authToken = await getAuthToken();
      if (authToken == null) {
        _log('No auth token found, cannot update FCM token on server');
        return;
      }

      final deviceType = await _getDeviceType();
      final timestamp = DateTime.now().toIso8601String();

      final requestBody = {
        'token': token,
        'device_type': deviceType,
        'timestamp': timestamp,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      _log('Server token update - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _log('Token updated on server successfully');
      } else {
        _logError('Server token update failed', response.body);
      }
    } catch (e) {
      _logError('_updateTokenOnServer', e);
    }
  }

  // Refresh stale tokens - call periodically or on app resume
  static Future<void> refreshTokenIfNeeded() async {
    try {
      _log('Checking if token refresh is needed');

      if (!await isLoggedIn()) {
        _log('User not logged in, skipping token refresh');
        return;
      }

      bool isStale = await _isTokenStale();

      if (isStale) {
        _log('Token is stale, refreshing');
        await _handleTokenRefresh();

        // Also refresh stale tokens on server
        final authToken = await getAuthToken();
        if (authToken != null) {
          try {
            final response = await http.post(
              Uri.parse('$baseUrl/device-token/refresh'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
            );

            _log('Server token refresh - Status: ${response.statusCode}');
          } catch (e) {
            _logError('Server token refresh', e);
          }
        }
      } else {
        _log('Token is fresh, no refresh needed');
      }
    } catch (e) {
      _logError('refreshTokenIfNeeded', e);
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
      final timestamp = DateTime.now().toIso8601String();

      final requestBody = {
        'token': token,
        'device_type': deviceType,
        'timestamp': timestamp,
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
        await _saveFCMToken(token);
        return {'success': true, 'message': data['message']};
      } else {
        _logError('Device token registration failed',
            'Status: ${response.statusCode}, Response: ${response.body}');
        return {
          'success': false,
          'error': data['error'] ?? 'Device token registration failed'
        };
      }
    } catch (e) {
      _logError('registerDeviceToken', e);
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
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

      String? fcmToken =
          await _getStoredFCMToken() ?? await _messaging.getToken();
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
        // Clear local token storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_fcmTokenKey);
        await prefs.remove(_tokenTimestampKey);

        return {'success': true, 'message': data['message']};
      } else {
        _logError('Device token removal failed',
            'Status: ${response.statusCode}, Response: ${response.body}');
        return {
          'success': false,
          'error': data['error'] ?? 'Device token removal failed'
        };
      }
    } catch (e) {
      _logError('removeDeviceToken', e);
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required File idImage,
    required String address,
  }) async {
    try {
      _log('Starting user registration');
      _log('Registration data - Name: $name, Email: $email');
      _log('ID Image path: ${idImage.path}');

      // Get FCM token before registration
      String? fcmToken = await _messaging.getToken();
      String deviceType = await _getDeviceType();
      String timestamp = DateTime.now().toIso8601String();

      var uri = Uri.parse('$baseUrl/register');
      _log('Registration URL: $uri');

      var request = http.MultipartRequest('POST', uri);

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation;
      request.fields['address'] = address;

      if (fcmToken != null) {
        request.fields['fcm_token'] = fcmToken;
        request.fields['device_type'] = deviceType;
        request.fields['timestamp'] = timestamp;
      }

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

        // Save FCM token locally if available
        if (fcmToken != null) {
          await _saveFCMToken(fcmToken);
        }

        // Initialize FCM after successful registration
        await initializeFCM();

        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
        _logError('Registration failed',
            'Status: ${response.statusCode}, Response: ${response.body}');
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

      // Get FCM token before login
      String? fcmToken = await _messaging.getToken();
      String deviceType = await _getDeviceType();
      String timestamp = DateTime.now().toIso8601String();

      final loginData = {
        'email': email,
        'password': password,
      };

      if (fcmToken != null) {
        loginData['fcm_token'] = fcmToken;
        loginData['device_type'] = deviceType;
        loginData['timestamp'] = timestamp;
      }

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

        // Debug: Print the entire user object
        _log('User data: ${data['user']}');

        int userId = int.parse(data['user_id'].toString());
        String token = data['token'];

        // Check if user is verified
        if (data['user'] != null && data['user']['is_verified'] == 0) {
          _log('User not verified');
          return {'success': false, 'error': 'User is not yet verified'};
        }

        // Check if user is restricted (check both int and bool values)
        if (data['user'] != null) {
          var isRestricted = data['user']['is_restricted'];
          _log(
              'is_restricted value: $isRestricted (type: ${isRestricted.runtimeType})');

          if (isRestricted == 1 ||
              isRestricted == true ||
              isRestricted == '1') {
            _log('User is restricted');
            return {
              'success': false,
              'error':
                  'Your account has been restricted. Please contact support for assistance.'
            };
          }
        }

        // Check if user is blocked (check both int and bool values)
        if (data['user'] != null) {
          var isBlocked = data['user']['is_blocked'];
          _log('is_blocked value: $isBlocked (type: ${isBlocked.runtimeType})');

          if (isBlocked == 1 || isBlocked == true || isBlocked == '1') {
            _log('User is blocked');
            return {
              'success': false,
              'error':
                  'Your account has been blocked. Please contact support for more information.'
            };
          }
        }

        await _saveAuthData(token, userId);

        // Save FCM token locally if available
        if (fcmToken != null) {
          await _saveFCMToken(fcmToken);
        }

        // Initialize FCM after successful login
        await initializeFCM();

        return {
          'success': true,
          'token': token,
          'user_id': userId,
        };
      } else {
        _logError('Login failed',
            'Status: ${response.statusCode}, Response: ${response.body}');
        String errorMessage = data['error'] ?? 'Login failed';
        // Map specific errors
        if (errorMessage.toLowerCase().contains('credential') ||
            errorMessage.toLowerCase().contains('password') ||
            errorMessage.toLowerCase().contains('invalid') ||
            errorMessage.toLowerCase().contains('unauthorized')) {
          errorMessage = 'These credentials do not match our records';
        }
        return {'success': false, 'error': errorMessage};
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
        await _clearAuthData();
        return {'success': true, 'message': 'Already logged out'};
      }

      // Get FCM token for removal
      String? fcmToken =
          await _getStoredFCMToken() ?? await _messaging.getToken();

      _log('Sending logout request to server');
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (fcmToken != null) 'fcm_token': fcmToken,
        }),
      );

      _log('Logout - Status: ${response.statusCode}');
      _log('Logout - Response: ${response.body}');

      // Always clear local data regardless of server response
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

// Add these methods to your AuthService class

  static Future<void> setupForegroundMessageHandling() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log('Got a message whilst in the foreground!');
      _log('Message data: ${message.data}');

      if (message.notification != null) {
        _log('Message also contained a notification: ${message.notification}');

        // Handle the notification based on type
        _handleNotificationReceived(message);
      }
    });
  }

  static Future<void> setupMessageInteractionHandling() async {
    // Handle notification tap when app is terminated
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _log('App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log('App opened from background via notification');
      _handleNotificationTap(message);
    });
  }

  static void _handleNotificationReceived(RemoteMessage message) {
    // Handle different notification types
    final notificationType = message.data['type'];

    switch (notificationType) {
      case 'announcement':
        _log('Received announcement notification: ${message.data['title']}');
        // You can show a local notification or update UI here
        break;
      default:
        _log('Received unknown notification type: $notificationType');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final notificationType = message.data['type'];

    switch (notificationType) {
      case 'announcement':
        _log('User tapped announcement notification');
        // Navigate to announcement details
        // You'll need to implement navigation logic here
        break;
      default:
        _log('User tapped unknown notification type: $notificationType');
    }
  }
}
