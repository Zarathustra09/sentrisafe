import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../constants.dart';

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

  static const String apiKey = 'AIzaSyDXaFeKPaKXgpFPp0IGlJuviW2RZCM9OtU';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<List<PlaceSuggestion>> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=${Uri.encodeComponent(query)}&'
        'key=$apiKey&'
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
      List<Location> locations = await locationFromAddress(text);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
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

        print('Route found, updating map');

        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('from'),
              position: from,
              infoWindow: const InfoWindow(title: 'Start'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
            Marker(
              markerId: const MarkerId('to'),
              position: to,
              infoWindow: const InfoWindow(title: 'Destination'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          };

          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: _decodePolyline(polylinePoints),
              color: Constants.primary,
              width: 4,
            ),
          };
        });

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

      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat - latPadding, minLng - lngPadding),
              northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
            ),
            100.0,
          ),
        );
      } catch (e) {
        print('Error fitting map to route: $e');
        LatLng center = LatLng(
          (from.latitude + to.latitude) / 2,
          (from.longitude + to.longitude) / 2,
        );
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: center, zoom: 12.0),
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
                _buildPlaceTypeAhead(
                  controller: _fromController,
                  labelText: "From",
                  prefixIcon: Icons.my_location,
                ),
                const SizedBox(height: AppConstants.spacingS),
                _buildPlaceTypeAhead(
                  controller: _toController,
                  labelText: "To",
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: AppConstants.spacingS),
                ElevatedButton(
                  onPressed: _searchAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: const Text(
                    'Get Directions',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
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
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    style: '''[
                      {
                        "featureType": "all",
                        "elementType": "geometry.fill",
                        "stylers": [{"color": "#1a1a1a"}]
                      }
                    ]''',
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}