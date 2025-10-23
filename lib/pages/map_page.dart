import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/saved_route_model.dart';
import '../models/crime_report_model.dart';
import '../services/route_database_helper.dart';
import '../services/crime_report/crime_report_service.dart';
import '../widgets/save_route_dialog.dart';
import '../widgets/saved_routes_dialog.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'],
      description: json['description'],
      mainText: json['structured_formatting']['main_text'],
      secondaryText: json['structured_formatting']['secondary_text'] ?? '',
    );
  }
}

class SaferRouteResponse {
  final bool success;
  final String polyline;
  final double safetyScore;
  final String routeDescription;
  final String duration;
  final String distance;
  final CrimeAnalysis crimeAnalysis;
  final List<dynamic> alternativeRoutes;
  final String apiUsed;

  SaferRouteResponse({
    required this.success,
    required this.polyline,
    required this.safetyScore,
    required this.routeDescription,
    required this.duration,
    required this.distance,
    required this.crimeAnalysis,
    required this.alternativeRoutes,
    required this.apiUsed,
  });

  factory SaferRouteResponse.fromJson(Map<String, dynamic> json) {
    return SaferRouteResponse(
      success: json['success'] ?? false,
      polyline: json['polyline'] ?? '',
      safetyScore: (json['safety_score'] as num?)?.toDouble() ?? 0.0,
      routeDescription: json['route_description'] ?? '',
      duration: json['duration'] ?? '',
      distance: json['distance'] ?? '',
      crimeAnalysis: CrimeAnalysis.fromJson(json['crime_analysis'] ?? {}),
      alternativeRoutes: json['alternative_routes'] ?? [],
      apiUsed: json['api_used'] ?? '',
    );
  }
}

class CrimeAnalysis {
  final int totalCrimesInArea;
  final int crimesNearRoute;
  final int highSeverityCrimes;

  CrimeAnalysis({
    required this.totalCrimesInArea,
    required this.crimesNearRoute,
    required this.highSeverityCrimes,
  });

  factory CrimeAnalysis.fromJson(Map<String, dynamic> json) {
    return CrimeAnalysis(
      totalCrimesInArea: json['total_crimes_in_area'] ?? 0,
      crimesNearRoute: json['crimes_near_route'] ?? 0,
      highSeverityCrimes: json['high_severity_crimes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_crimes_in_area': totalCrimesInArea,
      'crimes_near_route': crimesNearRoute,
      'high_severity_crimes': highSeverityCrimes,
    };
  }
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  SaferRouteResponse? _currentSaferRoute;
  bool _isLoadingSaferRoute = false;

  // Add these new variables for crime reports
  List<CrimeReport> _crimeReports = [];
  bool _showCrimeReports = true;
  bool _isLoadingCrimeReports = false;

  // Current route data for saving
  LatLng? _currentFromLocation;
  LatLng? _currentToLocation;
  String? _currentPolyline;
  String? _currentDuration;
  String? _currentDistance;
  bool _isCurrentRouteSafer = false;

  static const String apiKey = googleApiKey;

  // Tanauan helpers
  LatLng get _tanauanCenter =>
      LatLng(MapConstants.tanauanCenterLat, MapConstants.tanauanCenterLng);
  LatLngBounds get _tanauanBounds => LatLngBounds(
        southwest: LatLng(MapConstants.tanauanSouth, MapConstants.tanauanWest),
        northeast: LatLng(MapConstants.tanauanNorth, MapConstants.tanauanEast),
      );
  LatLng _clampToTanauan(LatLng p) {
    final lat = p.latitude
        .clamp(MapConstants.tanauanSouth, MapConstants.tanauanNorth)
        .toDouble();
    final lng = p.longitude
        .clamp(MapConstants.tanauanWest, MapConstants.tanauanEast)
        .toDouble();
    return LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    // Center map in Tanauan City by default
    _currentLocation = _tanauanCenter;
    _getCurrentLocation();
    _loadCrimeReports();
  }

  // Add method to load crime reports
  Future<void> _loadCrimeReports() async {
    setState(() {
      _isLoadingCrimeReports = true;
    });

    try {
      final result = await CrimeReportService.getReports();
      if (result['success'] == true) {
        setState(() {
          _crimeReports = result['reports'] ?? [];
          _updateMapMarkers();
        });
      } else {
        print('Failed to load crime reports: ${result['error']}');
      }
    } catch (e) {
      print('Error loading crime reports: $e');
    } finally {
      setState(() {
        _isLoadingCrimeReports = false;
      });
    }
  }

  // Add method to get marker color based on severity
  BitmapDescriptor _getCrimeMarkerIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'medium':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'low':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  // Add method to update map markers
  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};

    // Add route markers if they exist
    if (_currentFromLocation != null && _currentToLocation != null) {
      newMarkers.addAll({
        Marker(
          markerId: const MarkerId('from'),
          position: _currentFromLocation!,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('to'),
          position: _currentToLocation!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      });
    }

    // Add crime report markers if enabled
    if (_showCrimeReports) {
      for (final crime in _crimeReports) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('crime_${crime.id}'),
            position: LatLng(crime.latitude, crime.longitude),
            icon: _getCrimeMarkerIcon(crime.severity),
            infoWindow: InfoWindow(
              title: crime.title,
              snippet: '${crime.severity.toUpperCase()} severity\n${crime.address ?? 'No address'}',
            ),
            onTap: () => _showCrimeDetails(crime),
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  // Add method to show crime details
  void _showCrimeDetails(CrimeReport crime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Constants.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        title: Text(
          crime.title,
          style: TextStyle(
            color: Constants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCrimeDetailRow(
              'Severity',
              crime.severity.toUpperCase(),
              _getSeverityColor(crime.severity),
            ),
            const SizedBox(height: AppConstants.spacingS),
            if (crime.description != null && crime.description!.isNotEmpty) ...[
              _buildCrimeDetailRow('Description', crime.description!, Constants.textSecondary),
              const SizedBox(height: AppConstants.spacingS),
            ],
            if (crime.address != null && crime.address!.isNotEmpty) ...[
              _buildCrimeDetailRow('Address', crime.address!, Constants.textSecondary),
              const SizedBox(height: AppConstants.spacingS),
            ],
            _buildCrimeDetailRow(
              'Date',
              _formatDate(crime.incidentDate),
              Constants.textSecondary,
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildCrimeDetailRow(
              'Location',
              '${crime.latitude.toStringAsFixed(4)}, ${crime.longitude.toStringAsFixed(4)}',
              Constants.textSecondary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: Constants.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrimeDetailRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Constants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: label == 'Severity' ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Constants.error;
      case 'medium':
        return Constants.warning;
      case 'low':
        return Constants.success;
      default:
        return Constants.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        final clamped = _clampToTanauan(
          LatLng(position.latitude, position.longitude),
        );
        setState(() {
          _currentLocation = clamped;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<List<PlaceSuggestion>> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=${Uri.encodeComponent(query)}&'
        'key=$apiKey&'
        'components=country:ph&'
        'locationbias=${Uri.encodeComponent(MapConstants.tanauanLocationBiasRect)}&'
        'types=geocode|establishment';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;

        return predictions
            .map((prediction) => PlaceSuggestion.fromJson(prediction))
            .toList();
      }
    } catch (e) {
      print('Error getting place suggestions: $e');
    }

    return [];
  }

  Future<LatLng?> _getPlaceDetails(String placeId) async {
    final String url = 'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&'
        'fields=geometry&'
        'key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];

        return LatLng(
          location['lat'].toDouble(),
          location['lng'].toDouble(),
        );
      }
    } catch (e) {
      print('Error getting place details: $e');
    }

    return null;
  }

  Future<LatLng?> _getCoordinatesFromText(String text) async {
    try {
      // Prefer Google Geocoding API restricted/bounded to Tanauan
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?'
          'address=${Uri.encodeComponent('$text, Tanauan, Batangas, Philippines')}&'
          'key=$apiKey&'
          'components=country:PH&'
          'bounds=${MapConstants.tanauanSouth},${MapConstants.tanauanWest}|'
          '${MapConstants.tanauanNorth},${MapConstants.tanauanEast}';

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['results'] != null &&
            data['results'] is List &&
            data['results'].isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          final latLng = LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          );
          return _clampToTanauan(latLng);
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }

  Future<void> _searchAndNavigate() async {
    print('_searchAndNavigate called');
    print('From: ${_fromController.text}');
    print('To: ${_toController.text}');

    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      print('One or both fields are empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both "From" and "To" locations')),
      );
      return;
    }

    try {
      print('Getting coordinates...');
      LatLng? from = await _getCoordinatesFromText(_fromController.text);
      LatLng? to = await _getCoordinatesFromText(_toController.text);

      print('From coordinates: $from');
      print('To coordinates: $to');

      if (from != null && to != null) {
        await _getDirections(from, to);
      } else {
        print('Failed to get coordinates');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find one or both locations')),
        );
      }
    } catch (e) {
      print('Error searching locations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _getSaferRoute() async {
    print('_getSaferRoute called');
    print('From: ${_fromController.text}');
    print('To: ${_toController.text}');

    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      print('One or both fields are empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both "From" and "To" locations')),
      );
      return;
    }

    setState(() {
      _isLoadingSaferRoute = true;
    });

    try {
      print('Getting coordinates for safer route...');
      LatLng? from = await _getCoordinatesFromText(_fromController.text);
      LatLng? to = await _getCoordinatesFromText(_toController.text);

      print('From coordinates: $from');
      print('To coordinates: $to');

      if (from != null && to != null) {
        await _getSaferRouteFromAPI(from, to);
      } else {
        print('Failed to get coordinates');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find one or both locations')),
        );
      }
    } catch (e) {
      print('Error getting safer route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoadingSaferRoute = false;
      });
    }
  }

  Future<void> _getSaferRouteFromAPI(LatLng from, LatLng to) async {
    print('Getting safer route from $from to $to');

    final String url = '$baseUrl/safer-route';

    final Map<String, dynamic> requestBody = {
      "start_lat": from.latitude.toString(),
      "start_lng": from.longitude.toString(),
      "end_lat": to.latitude.toString(),
      "end_lng": to.longitude.toString(),
      "radius": 5,
      "avoid_recent_crimes": true,
      "time_sensitivity_days": 30
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Safer route response status: ${response.statusCode}');
      print('Safer route response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final saferRouteResponse = SaferRouteResponse.fromJson(data);

        if (saferRouteResponse.success && saferRouteResponse.polyline.isNotEmpty) {
          print('Safer route found, updating map');

          setState(() {
            _currentSaferRoute = saferRouteResponse;
            _isCurrentRouteSafer = true;
            _currentFromLocation = from;
            _currentToLocation = to;
            _currentPolyline = saferRouteResponse.polyline;
            _currentDuration = saferRouteResponse.duration;
            _currentDistance = saferRouteResponse.distance;

            _polylines = {
              Polyline(
                polylineId: const PolylineId('safer_route'),
                points: _decodePolyline(saferRouteResponse.polyline),
                color: Constants.success,
                width: 4,
              ),
            };
          });

          _updateMapMarkers();
          _fitMapToRoute(from, to);
          _showSaferRouteInfo(saferRouteResponse);
          print('Safer route map updated successfully');
        } else {
          print('No safer route found');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No safer route found')),
          );
        }
      } else if (response.statusCode == 404) {
        // Handle 404 with message from response
        String message = 'No safer route found';
        try {
          final data = json.decode(response.body);
          if (data is Map && data['message'] != null) {
            message = data['message'];
          }
        } catch (_) {}
        print('HTTP 404: $message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        print('HTTP error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error getting safer route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting safer route: $e')),
      );
    }
  }

  void _showSaferRouteInfo(SaferRouteResponse saferRoute) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Constants.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Constants.success, size: 24),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    'Safer Route Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              if (saferRoute.safetyScore != null) ...[
                Row(
                  children: [
                    Icon(Icons.star, color: Constants.warning, size: 20),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Safety Score: ${saferRoute.safetyScore.toStringAsFixed(1)}/5.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
              ],
              if (saferRoute.routeDescription.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.route, color: Constants.primary, size: 20),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        saferRoute.routeDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Constants.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
              ],
              if (saferRoute.duration.isNotEmpty && saferRoute.distance.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, color: Constants.accent, size: 20),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      '${saferRoute.duration} • ${saferRoute.distance}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Constants.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
              ],
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: Constants.background,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crime Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Constants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'Total crimes in area: ${saferRoute.crimeAnalysis.totalCrimesInArea}',
                      style: TextStyle(color: Constants.textSecondary),
                    ),
                    Text(
                      'Crimes near route: ${saferRoute.crimeAnalysis.crimesNearRoute}',
                      style: TextStyle(color: Constants.textSecondary),
                    ),
                    Text(
                      'High severity crimes: ${saferRoute.crimeAnalysis.highSeverityCrimes}',
                      style: TextStyle(color: Constants.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getDirections(LatLng from, LatLng to) async {
    print('Getting directions from $from to $to');

    // Use the Roads API or Routes API instead of the legacy Directions API
    final String url = 'https://routes.googleapis.com/directions/v2:computeRoutes';

    final Map<String, dynamic> requestBody = {
      "origin": {
        "location": {
          "latLng": {
            "latitude": from.latitude,
            "longitude": from.longitude
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": to.latitude,
            "longitude": to.longitude
          }
        }
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "computeAlternativeRoutes": false,
      "routeModifiers": {
        "avoidTolls": false,
        "avoidHighways": false,
        "avoidFerries": false
      },
      "languageCode": "en-US",
      "units": "IMPERIAL"
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['polyline']['encodedPolyline'];
          final duration = route['duration'] ?? '';
          final distanceMeters = route['distanceMeters'] ?? 0;
          final distance = '${(distanceMeters / 1609.34).toStringAsFixed(1)} mi'; // Convert meters to miles

          print('Route found, updating map');

          setState(() {
            _currentSaferRoute = null; // Clear safer route info when showing regular route
            _isCurrentRouteSafer = false;
            _currentFromLocation = from;
            _currentToLocation = to;
            _currentPolyline = polylinePoints;
            _currentDuration = duration;
            _currentDistance = distance;

            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: _decodePolyline(polylinePoints),
                color: Constants.primary,
                width: 4,
              ),
            };
          });

          _updateMapMarkers();
          _fitMapToRoute(from, to);
          print('Map updated successfully');
        } else {
          print('No routes found');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No route found')),
          );
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error getting directions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting directions: $e')),
      );
    }
  }

  Future<void> _saveCurrentRoute() async {
    if (_currentFromLocation == null || _currentToLocation == null || _currentPolyline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No route available to save')),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => SaveRouteDialog(),
    );

    if (result != null) {
      final now = DateTime.now();
      final routeToSave = RouteModel(
        name: result['name']!,
        description: result['description'],
        startLat: _currentFromLocation!.latitude,
        startLng: _currentFromLocation!.longitude,
        endLat: _currentToLocation!.latitude,
        endLng: _currentToLocation!.longitude,
        startAddress: _fromController.text,
        endAddress: _toController.text,
        polyline: _currentPolyline!,
        safetyScore: _currentSaferRoute?.safetyScore,
        duration: _currentDuration,
        distance: _currentDistance,
        crimeAnalysisJson: _currentSaferRoute?.crimeAnalysis != null ? jsonEncode(_currentSaferRoute!.crimeAnalysis.toJson()) : null,
        isSaferRoute: _isCurrentRouteSafer,
        routeType: _isCurrentRouteSafer ? 'safer' : 'regular',
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      try {
        await RouteDatabaseHelper().insertRoute(routeToSave);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route saved locally for offline use!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save route: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSavedRoutes() async {
    showDialog(
      context: context,
      builder: (context) => SavedRoutesDialog(
        onRouteSelected: _loadSavedRoute,
      ),
    );
  }

  Future<void> _loadSavedRoute(SavedRoute savedRoute) async {
    setState(() {
      _fromController.text = savedRoute.startAddress;
      _toController.text = savedRoute.endAddress;

      _currentFromLocation = LatLng(savedRoute.startLat, savedRoute.startLng);
      _currentToLocation = LatLng(savedRoute.endLat, savedRoute.endLng);
      _currentPolyline = savedRoute.polyline;
      _currentDuration = savedRoute.duration;
      _currentDistance = savedRoute.distance;
      _isCurrentRouteSafer = savedRoute.isSaferRoute;

      if (savedRoute.isSaferRoute && savedRoute.crimeAnalysis != null) {
        _currentSaferRoute = SaferRouteResponse(
          success: true,
          polyline: savedRoute.polyline,
          safetyScore: savedRoute.safetyScore ?? 0.0,
          routeDescription: savedRoute.description ?? '',
          duration: savedRoute.duration ?? '',
          distance: savedRoute.distance ?? '',
          crimeAnalysis: savedRoute.crimeAnalysis!,
          alternativeRoutes: [],
          apiUsed: 'saved',
        );
      } else {
        _currentSaferRoute = null;
      }

      _polylines = {
        Polyline(
          polylineId: const PolylineId('saved_route'),
          points: _decodePolyline(savedRoute.polyline),
          color: savedRoute.isSaferRoute ? Constants.success : Constants.primary,
          width: 4,
        ),
      };
    });

    _updateMapMarkers();
    _fitMapToRoute(_currentFromLocation!, _currentToLocation!);
    Navigator.of(context).pop(); // Close the saved routes dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved route: ${savedRoute.name}'),
        backgroundColor: Constants.success,
      ),
    );
  }

  Future<String?> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=${coordinates.latitude},${coordinates.longitude}&'
          'key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
    }
    return null;
  }

  Future<void> _useCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        final currentPos = LatLng(position.latitude, position.longitude);
        final clampedPos = _clampToTanauan(currentPos);

        // Get readable address
        final address = await _getAddressFromCoordinates(clampedPos);

        setState(() {
          _currentLocation = clampedPos;
          _fromController.text = address ??
              'Current Location (${clampedPos.latitude.toStringAsFixed(4)}, ${clampedPos.longitude.toStringAsFixed(4)})';
        });

        // Move map to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: clampedPos, zoom: 16.0),
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Current location set as starting point'),
            backgroundColor: Constants.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error using current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting current location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _fitMapToRoute(LatLng from, LatLng to) {
    if (_mapController != null) {
      double minLat = from.latitude < to.latitude ? from.latitude : to.latitude;
      double maxLat = from.latitude > to.latitude ? from.latitude : to.latitude;
      double minLng = from.longitude < to.longitude ? from.longitude : to.longitude;
      double maxLng = from.longitude > to.longitude ? from.longitude : to.longitude;

      double latPadding = (maxLat - minLat) * 0.1;
      double lngPadding = (maxLng - minLng) * 0.1;

      // Clamp to Tanauan bounds
      double south = (minLat - latPadding)
          .clamp(MapConstants.tanauanSouth, MapConstants.tanauanNorth)
          .toDouble();
      double north = (maxLat + latPadding)
          .clamp(MapConstants.tanauanSouth, MapConstants.tanauanNorth)
          .toDouble();
      double west = (minLng - lngPadding)
          .clamp(MapConstants.tanauanWest, MapConstants.tanauanEast)
          .toDouble();
      double east = (maxLng + lngPadding)
          .clamp(MapConstants.tanauanWest, MapConstants.tanauanEast)
          .toDouble();

      try {
        if (south >= north || west >= east) {
          throw Exception('Invalid bounds after clamping');
        }
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(south, west),
              northeast: LatLng(north, east),
            ),
            100.0,
          ),
        );
      } catch (e) {
        print('Error fitting map to route: $e');
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _tanauanCenter, zoom: 13.0),
          ),
        );
      }
    }
  }

  Widget _buildPlaceTypeAhead({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
  }) {
    return TypeAheadField<PlaceSuggestion>(
      controller: controller,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: Constants.textSecondary),
            prefixIcon: Icon(prefixIcon, color: Constants.primary),
            filled: true,
            fillColor: Constants.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(color: Constants.greyDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(color: Constants.greyDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(color: Constants.primary),
            ),
          ),
          style: TextStyle(color: Constants.textPrimary),
        );
      },
      suggestionsCallback: (pattern) async {
        return await _getPlaceSuggestions(pattern);
      },
      itemBuilder: (context, PlaceSuggestion suggestion) {
        return ListTile(
          leading: Icon(Icons.location_on, color: Constants.primary),
          title: Text(
            suggestion.mainText,
            style: TextStyle(color: Constants.textPrimary),
          ),
          subtitle: Text(
            suggestion.secondaryText,
            style: TextStyle(color: Constants.textSecondary),
          ),
        );
      },
      onSelected: (PlaceSuggestion suggestion) async {
        controller.text = suggestion.description;
        LatLng? coordinates = await _getPlaceDetails(suggestion.placeId);
        if (coordinates != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: coordinates, zoom: 15.0),
            ),
          );
        }
      },
      decorationBuilder: (context, child) {
        return Material(
          type: MaterialType.card,
          elevation: AppConstants.elevationL,
          color: Constants.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: child,
        );
      },
      emptyBuilder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Text(
          'No places found',
          style: TextStyle(color: Constants.textSecondary),
        ),
      ),
    );
  }

  bool _hasCurrentRoute() {
    return _currentFromLocation != null &&
        _currentToLocation != null &&
        _currentPolyline != null;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Constants.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              children: [
                // From field with current location button
                Row(
                  children: [
                    Expanded(
                      child: _buildPlaceTypeAhead(
                        controller: _fromController,
                        labelText: "From",
                        prefixIcon: Icons.my_location,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Container(
                      height: 56, // Match TextField height
                      child: ElevatedButton(
                        onPressed: _useCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Icon(
                          Icons.gps_fixed,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                _buildPlaceTypeAhead(
                  controller: _toController,
                  labelText: "To",
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: AppConstants.spacingS),

                // Add crime reports toggle
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: _showCrimeReports ? Constants.error : Constants.greyDark,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Show Crime Reports',
                      style: TextStyle(
                        color: _showCrimeReports ? Constants.textPrimary : Constants.greyDark,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _showCrimeReports,
                      onChanged: (value) {
                        setState(() {
                          _showCrimeReports = value;
                          _updateMapMarkers();
                        });
                      },
                      activeColor: Constants.error,
                    ),
                    const SizedBox(width: 8),
                    if (_isLoadingCrimeReports)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        onPressed: _loadCrimeReports,
                        icon: Icon(
                          Icons.refresh,
                          color: Constants.primary,
                          size: 20,
                        ),
                        tooltip: 'Refresh crime data',
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),

                // Main action buttons row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _searchAndNavigate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primary,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                        ),
                        child: const Text(
                          'Get Directions',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoadingSaferRoute ? null : _getSaferRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.success,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                        ),
                        child: _isLoadingSaferRoute
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.security, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Safer Route',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingS),

                // Secondary buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hasCurrentRoute() ? _saveCurrentRoute : null,
                        icon: Icon(
                          Icons.bookmark_add,
                          color: _hasCurrentRoute() ? Constants.primary : Constants.greyDark,
                          size: 18,
                        ),
                        label: Text(
                          'Save Route',
                          style: TextStyle(
                            color: _hasCurrentRoute() ? Constants.primary : Constants.greyDark,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          side: BorderSide(
                            color: _hasCurrentRoute() ? Constants.primary : Constants.greyDark,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showSavedRoutes,
                        icon: Icon(
                          Icons.bookmark,
                          color: Constants.accent,
                          size: 18,
                        ),
                        label: Text(
                          'Saved Routes',
                          style: TextStyle(
                            color: Constants.accent,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          side: BorderSide(color: Constants.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Crime reports legend
                if (_showCrimeReports && _crimeReports.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem('High', Colors.red),
                        _buildLegendItem('Medium', Colors.orange),
                        _buildLegendItem('Low', Colors.yellow),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _currentLocation != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 14.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    cameraTargetBounds: CameraTargetBounds(_tanauanBounds),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

