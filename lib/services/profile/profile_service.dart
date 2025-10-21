import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sentrisafe/constants.dart';
import 'package:sentrisafe/services/auth/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfileService {
  static Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getAuthToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> getProfile() async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'error': 'No internet connection',
      };
    }
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to load profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? password,
    required String address,
    File? profilePicture,
  }) async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'error': 'No internet connection',
      };
    }
    try {
      final token = await AuthService.getAuthToken();
      var uri = Uri.parse('$baseUrl/profile');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Laravel workaround for PUT with multipart data
      request.fields['_method'] = 'PUT';
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['address'] = address;

      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (profilePicture != null) {
        String fileExtension =
            profilePicture.path.split('.').last.toLowerCase();
        String mimeType = fileExtension == 'png' ? 'png' : 'jpeg';

        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicture.path,
            contentType: MediaType('image', mimeType),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> uploadProfileImage(File image) async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'error': 'No internet connection',
      };
    }
    try {
      final token = await AuthService.getAuthToken();
      var uri = Uri.parse('$baseUrl/profile/upload-image');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      String fileExtension = image.path.split('.').last.toLowerCase();
      String mimeType = fileExtension == 'png' ? 'png' : 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          image.path,
          contentType: MediaType('image', mimeType),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'image_url': data['image_url'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to upload image',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> resetProfileImage() async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'error': 'No internet connection',
      };
    }
    try {
      final headers = await _getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/profile/reset-image'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to reset profile image',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'error': 'No internet connection',
      };
    }
    try {
      final headers = await _getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Clear auth data after successful deletion
        await AuthService.logout();
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to delete account',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
