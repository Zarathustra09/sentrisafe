import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math'; // added for bounds calculation

import '../constants.dart';
import '../models/crime_report_model.dart';
import '../services/crime_report/crime_report_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};

  List<CrimeReport> _crimeReports = [];
  bool _isLoadingReports = false;
  bool _showCrimeReports = true;
  String? _selectedSeverity;

  final List<String> _severityOptions = ['All', 'High', 'Medium', 'Low'];

  // Search controller and state
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCrimeReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadCrimeReports({String? search}) async {
    setState(() {
      _isLoadingReports = true;
    });

    try {
      // derive severity param (api expects severity values, skip 'All')
      String? severityParam;
      if (_selectedSeverity != null && _selectedSeverity != 'All') {
        severityParam = _selectedSeverity;
      }

      // Include current location if available
      double? lat = _currentLocation?.latitude;
      double? lng = _currentLocation?.longitude;

      final result = await CrimeReportService.getReportsWithFilters(
        severity: severityParam,
        lat: lat,
        lng: lng,
        search: search,
      );

      if (result['success'] == true) {
        setState(() {
          _crimeReports = result['reports'] ?? [];
          _updateMapMarkers();
        });
      } else {
        print('Failed to load crime reports: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: ${result['error']}'),
            backgroundColor: Constants.error,
          ),
        );
      }
    } catch (e) {
      print('Error loading crime reports: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reports: $e'),
          backgroundColor: Constants.error,
        ),
      );
    } finally {
      setState(() {
        _isLoadingReports = false;
      });
    }
  }

  void _updateMapMarkers() {
    Set<Marker> newMarkers = {};

    // Add crime report markers - no local filtering since API handles all filters
    if (_showCrimeReports) {
      // Add crime report markers (already filtered by API)
      for (final crime in _crimeReports) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('crime_${crime.id}'),
            position: LatLng(crime.latitude, crime.longitude),
            icon: _getCrimeMarkerIcon(crime.severity),
            infoWindow: InfoWindow(
              title: crime.title,
              snippet: '${crime.severity.toUpperCase()} severity\n${_formatDate(crime.incidentDate)}',
            ),
            onTap: () => _showCrimeDetails(crime),
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
    });

    // Animate camera to fit markers when they change (supports search results)
    if (_mapController != null && newMarkers.isNotEmpty) {
      try {
        final positions = newMarkers.map((m) => m.position).toList();
        double south = positions.map((p) => p.latitude).reduce(min);
        double north = positions.map((p) => p.latitude).reduce(max);
        double west = positions.map((p) => p.longitude).reduce(min);
        double east = positions.map((p) => p.longitude).reduce(max);

        // If single point, expand bounds a little
        if (south == north && west == east) {
          const double delta = 0.01; // ~1km depending on lat
          south = south - delta;
          north = north + delta;
          west = west - delta;
          east = east + delta;
        }

        final bounds = LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        );

        // add some padding
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      } catch (e) {
        // Fallback: move to first marker if bounds calculation/animation fails
        try {
          final first = newMarkers.first.position;
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(first, 14.0));
        } catch (_) {
          // ignore
        }
      }
    } else if (_mapController != null && newMarkers.isEmpty && _currentLocation != null) {
      // If no markers (e.g., search returned nothing), reset to user's location
      try {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 12.0));
      } catch (_) {
        // ignore
      }
    }
  }

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
            _buildDetailRow(
              'Severity',
              crime.severity.toUpperCase(),
              _getSeverityColor(crime.severity),
            ),
            const SizedBox(height: AppConstants.spacingS),
            if (crime.description != null && crime.description!.isNotEmpty) ...[
              _buildDetailRow('Description', crime.description!, Constants.textSecondary),
              const SizedBox(height: AppConstants.spacingS),
            ],
            if (crime.address != null && crime.address!.isNotEmpty) ...[
              _buildDetailRow('Address', crime.address!, Constants.textSecondary),
              const SizedBox(height: AppConstants.spacingS),
            ],
            _buildDetailRow(
              'Date',
              _formatDate(crime.incidentDate),
              Constants.textSecondary,
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildDetailRow(
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

  Widget _buildDetailRow(String label, String value, Color valueColor) {
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
          // Controls panel
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              children: [
                // Header with report count and refresh
                Row(
                  children: [
                    Icon(
                      Icons.report_problem,
                      color: Constants.error,
                      size: 24,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      'AI Crime Map (${_crimeReports.length})',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Toggle switch for showing/hiding crime reports
                    Switch(
                      value: _showCrimeReports,
                      onChanged: (value) {
                        setState(() {
                          _showCrimeReports = value;
                          _updateMapMarkers();
                        });
                      },
                      activeColor: Constants.primary,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    if (_isLoadingReports)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        onPressed: () => _loadCrimeReports(search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim()),
                        icon: Icon(
                          Icons.refresh,
                          color: Constants.primary,
                        ),
                        tooltip: 'Refresh reports',
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),

                // Search bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: Constants.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search reports by title, description, address or reporter',
                          hintStyle: TextStyle(color: Constants.textSecondary),
                          filled: true,
                          fillColor: Constants.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                            borderSide: BorderSide(color: Constants.greyDark),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.clear, color: Constants.textSecondary),
                                onPressed: () {
                                  if (_searchController.text.isNotEmpty) {
                                    _searchController.clear();
                                    _loadCrimeReports(); // refresh without search
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.search, color: Constants.primary),
                                onPressed: () {
                                  final q = _searchController.text.trim();
                                  _loadCrimeReports(search: q.isEmpty ? null : q);
                                },
                              ),
                            ],
                          ),
                        ),
                        onSubmitted: (value) {
                          final q = value.trim();
                          _loadCrimeReports(search: q.isEmpty ? null : q);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),

                // Severity filter dropdown
                Row(
                  children: [
                    Text(
                      'Filter by severity:',
                      style: TextStyle(
                        color: Constants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSeverity,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Constants.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                            borderSide: BorderSide(color: Constants.greyDark),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                            borderSide: BorderSide(color: Constants.greyDark),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        dropdownColor: Constants.surface,
                        style: TextStyle(color: Constants.textPrimary),
                        items: _severityOptions.map((severity) {
                          return DropdownMenuItem<String>(
                            value: severity,
                            child: Text(
                              severity,
                              style: TextStyle(
                                color: severity == 'All'
                                    ? Constants.textPrimary
                                    : _getSeverityColor(severity),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSeverity = value;
                            // reload with current search if any
                            final q = _searchController.text.trim();
                            _loadCrimeReports(search: q.isEmpty ? null : q);
                          });
                        },
                        hint: Text(
                          'All severities',
                          style: TextStyle(color: Constants.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),

                // Legend
                if (_crimeReports.isNotEmpty && _showCrimeReports) ...[
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

          // Map
          Expanded(
            child: _currentLocation != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 12.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading map...'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

