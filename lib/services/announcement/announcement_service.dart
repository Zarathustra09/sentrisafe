import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sentrisafe/constants.dart';
import 'package:sentrisafe/models/announcement_model.dart';
import 'package:sentrisafe/services/auth/auth_service.dart';

class AnnouncementService {
  static Future<Map<String, dynamic>> getAnnouncements({int page = 1}) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/announcements?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Announcements response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final announcementResponse = AnnouncementResponse.fromJson(data);

        return {
          'success': true,
          'announcements': announcementResponse.data.data,
          'pagination': {
            'current_page': announcementResponse.data.currentPage,
            'last_page': announcementResponse.data.lastPage,
            'total': announcementResponse.data.total,
            'per_page': announcementResponse.data.perPage,
          }
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to fetch announcements'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> getAnnouncementById(int id) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final announcement = Announcement.fromJson(data['data']);

        return {
          'success': true,
          'announcement': announcement,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to fetch announcement'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}'
      };
    }
  }
}