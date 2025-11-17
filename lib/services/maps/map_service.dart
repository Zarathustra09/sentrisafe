import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants.dart';

class MapService {
  static const String _baseUrl = baseUrl;

  /// Get directions from your Laravel API
  static Future<Map<String, dynamic>> getDirections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String travelMode = 'DRIVE',
    String routingPreference = 'TRAFFIC_AWARE',
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
    String units = 'IMPERIAL',
  }) async {
    final url = Uri.parse('$_baseUrl/directions');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'from_lat': fromLat,
          'from_lng': fromLng,
          'to_lat': toLat,
          'to_lng': toLng,
          'travel_mode': travelMode,
          'routing_preference': routingPreference,
          'avoid_tolls': avoidTolls,
          'avoid_highways': avoidHighways,
          'avoid_ferries': avoidFerries,
          'units': units,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        // Handle validation errors (bounds check)
        final error = json.decode(response.body);
        final errorType = error['error_type'];
        final message = error['message'] ?? 'Location out of bounds';

        return {
          'success': false,
          'message': message,
          'error_type': errorType,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get directions');
      }
    } catch (e) {
      throw Exception('Error getting directions: $e');
    }
  }

  /// Geocode text to coordinates using your Laravel API
  static Future<LatLng?> getCoordinatesFromText(String text) async {
    final url = Uri.parse('$_baseUrl/geocode-text');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return LatLng(
            data['latitude'].toDouble(),
            data['longitude'].toDouble(),
          );
        }
      } else if (response.statusCode == 404) {
        return null;
      }

      throw Exception('Failed to geocode text');
    } catch (e) {
      print('Error geocoding text: $e');
      return null;
    }
  }
}
