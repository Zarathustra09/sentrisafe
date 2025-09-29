import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/saved_route_model.dart';
import '../../constants.dart';
import '../auth/auth_service.dart';

class SavedRouteService {
  static Future<Map<String, String>> get _headers async {
    final token = await AuthService.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get all saved routes for the authenticated user
  static Future<SavedRouteResponse> getSavedRoutes({
    int page = 1,
    String? type,
    String? search,
  }) async {
    if (!await _isConnected()) {
      return SavedRouteResponse(
        success: false,
        data: [],
        message: 'No internet connection',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/saved-routes').replace(
        queryParameters: {
          'page': page.toString(),
          if (type != null) 'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final response = await http.get(uri, headers: await _headers);
      print('Get saved routes response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SavedRouteResponse.fromJson(data);
      } else {
        throw Exception('Failed to load saved routes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting saved routes: $e');
      return SavedRouteResponse(
        success: false,
        data: [],
        message: 'Failed to load saved routes: $e',
      );
    }
  }

  /// Save a new route
  static Future<Map<String, dynamic>> saveRoute(SavedRoute route) async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/saved-routes'),
        headers: await _headers,
        body: json.encode(route.toJson()),
      );

      print('Save route response: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Route saved successfully',
          'data': data['data'] != null ? SavedRoute.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save route',
        };
      }
    } catch (e) {
      print('Error saving route: $e');
      return {
        'success': false,
        'message': 'Failed to save route: $e',
      };
    }
  }

  /// Get a specific saved route by ID
  static Future<Map<String, dynamic>> getSavedRoute(int id) async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/saved-routes/$id'),
        headers: await _headers,
      );

      print('Get saved route response: ${response.statusCode}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': SavedRoute.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Route not found',
        };
      }
    } catch (e) {
      print('Error getting saved route: $e');
      return {
        'success': false,
        'message': 'Failed to load route: $e',
      };
    }
  }

  /// Update a saved route
  static Future<Map<String, dynamic>> updateRoute(int id, {
    String? name,
    String? description,
  }) async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      final response = await http.put(
        Uri.parse('$baseUrl/saved-routes/$id'),
        headers: await _headers,
        body: json.encode(updateData),
      );

      print('Update route response: ${response.statusCode}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Route updated successfully',
          'data': data['data'] != null ? SavedRoute.fromJson(data['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update route',
        };
      }
    } catch (e) {
      print('Error updating route: $e');
      return {
        'success': false,
        'message': 'Failed to update route: $e',
      };
    }
  }

  /// Delete a saved route
  static Future<Map<String, dynamic>> deleteRoute(int id) async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/saved-routes/$id'),
        headers: await _headers,
      );

      print('Delete route response: ${response.statusCode}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Route deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete route',
        };
      }
    } catch (e) {
      print('Error deleting route: $e');
      return {
        'success': false,
        'message': 'Failed to delete route: $e',
      };
    }
  }

  /// Get route statistics
  static Future<Map<String, dynamic>> getRouteStats() async {
    if (!await _isConnected()) {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/saved-routes-stats'),
        headers: await _headers,
      );

      print('Get route stats response: ${response.statusCode}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': SavedRouteStats.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load stats',
        };
      }
    } catch (e) {
      print('Error getting route stats: $e');
      return {
        'success': false,
        'message': 'Failed to load stats: $e',
      };
    }
  }
}