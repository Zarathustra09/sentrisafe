import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentrisafe/constants.dart';

class AuthService {
  static Future<void> _saveAuthData(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
  }

  static Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required File idImage,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/register');
      var request = http.MultipartRequest('POST', uri);

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation;

      // Get file extension and determine MIME type
      String fileExtension = idImage.path.split('.').last.toLowerCase();
      String mimeType = fileExtension == 'png' ? 'png' : 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'valid_id_image',
          idImage.path,
          contentType: MediaType('image', mimeType),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Server response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Convert user id to int safely
        int userId = int.parse(data['user']['id'].toString());

        // Save auth data to SharedPreferences
        await _saveAuthData(data['token'], userId);

        return {'success': true, 'token': data['token'], 'user': data['user']};
      }else {
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': 'Registration failed'},
        };
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Convert user_id to int safely
        int userId = int.parse(data['user_id'].toString());

        // Save auth data to SharedPreferences
        await _saveAuthData(data['token'], userId);

        return {
          'success': true,
          'token': data['token'],
          'user_id': userId,
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Clear auth data regardless of response
      await _clearAuthData();

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Logged out successfully'};
      } else {
        return {'success': true, 'message': 'Logged out locally'};
      }
    } catch (e) {
      // Clear auth data even if network fails
      await _clearAuthData();
      return {'success': true, 'message': 'Logged out locally'};
    }
  }
}