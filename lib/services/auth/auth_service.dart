import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sentrisafe/constants.dart';

class AuthService {
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
        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
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
        return {
          'success': true,
          'token': data['token'],
          'user_id': data['user_id'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
