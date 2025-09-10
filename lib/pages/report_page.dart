import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants.dart';
import '../services/crime_report/crime_report_service.dart';
import '../models/crime_report_model.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with SingleTickerProviderStateMixin {
  List<CrimeReport> _reports = [];
  bool _isLoadingReports = false;
  String? _filterSeverity;
  String? _filterStatus;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  late TabController _tabController;

  // Tinurik, Tanauan City, Batangas coordinates
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(14.0865, 121.1497), // Tinurik, Tanauan City, Batangas
    zoom: 15,
  );

  // Boundaries for Tinurik, Tanauan City, Batangas (approximate)
  static final LatLngBounds _tinurikBounds = LatLngBounds(
    southwest: LatLng(14.0800, 121.1400), // Southwest boundary
    northeast: LatLng(14.0930, 121.1594), // Northeast boundary
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoadingReports = true;
    });

    try {
      final result = await CrimeReportService.getReports();
      if (result['success']) {
        setState(() {
          _reports = result['reports'];
          _createMapMarkers();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to load reports'),
            backgroundColor: Constants.error,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _refreshReports() async {
    await _loadReports();

    // Show success message after refresh
    if (mounted && !_isLoadingReports) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reports refreshed'),
          backgroundColor: Constants.success,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _createMapMarkers() {
    _markers.clear();

    for (int i = 0; i < _reports.length; i++) {
      final report = _reports[i];

      // Only add markers for reports within Tinurik bounds
      if (_isWithinTinurikBounds(report.latitude, report.longitude)) {
        Color markerColor;
        switch (report.severity.toLowerCase()) {
          case 'critical':
            markerColor = Constants.error;
            break;
          case 'high':
            markerColor = Constants.warning;
            break;
          case 'medium':
            markerColor = Constants.info;
            break;
          default:
            markerColor = Constants.success;
        }

        _markers.add(
          Marker(
            markerId: MarkerId('report_$i'),
            position: LatLng(report.latitude, report.longitude),
            infoWindow: InfoWindow(
              title: report.title,
              snippet: '${report.severity} - ${report.incidentDate.day}/${report.incidentDate.month}/${report.incidentDate.year}',
            ),
            onTap: () => _showReportDetails(report),
          ),
        );
      }
    }
  }

  bool _isWithinTinurikBounds(double lat, double lng) {
    return lat >= _tinurikBounds.southwest.latitude &&
           lat <= _tinurikBounds.northeast.latitude &&
           lng >= _tinurikBounds.southwest.longitude &&
           lng <= _tinurikBounds.northeast.longitude;
  }

  void _showReportDetails(CrimeReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Constants.surface,
        title: Text(
          report.title,
          style: TextStyle(color: Constants.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description: ${report.description ?? "No description provided"}', // Handle null description
              style: TextStyle(color: Constants.textSecondary),
            ),
            SizedBox(height: AppConstants.spacingS),
            Text(
              'Severity: ${report.severity}',
              style: TextStyle(color: Constants.textSecondary),
            ),
            SizedBox(height: AppConstants.spacingS),
            Text(
              'Date: ${report.incidentDate.day}/${report.incidentDate.month}/${report.incidentDate.year}',
              style: TextStyle(color: Constants.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: Constants.primary)),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Constants.error;
      case 'high':
        return Constants.warning;
      case 'medium':
        return Constants.info;
      default:
        return Constants.success;
    }
  }

  Widget _buildReportItem(CrimeReport report) {
    Color severityColor = _getSeverityColor(report.severity);
    IconData severityIcon;

    switch (report.severity.toLowerCase()) {
      case 'critical':
        severityIcon = Icons.crisis_alert;
        break;
      case 'high':
        severityIcon = Icons.warning;
        break;
      case 'medium':
        severityIcon = Icons.info;
        break;
      default:
        severityIcon = Icons.info_outline;
    }

    return Card(
      color: Constants.surface,
      margin: EdgeInsets.only(bottom: AppConstants.spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(severityIcon, color: severityColor, size: 20),
                  SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      report.title,
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Text(
                      report.severity.toUpperCase(),
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingS),
              Text(
                report.description ?? "No description provided", // Handle null description
                style: TextStyle(
                  color: Constants.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppConstants.spacingS),
              Row(
                children: [
                  Icon(Icons.location_on, color: Constants.textSecondary, size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.address ?? "Location: ${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}",
                      style: TextStyle(
                        color: Constants.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${report.incidentDate.day}/${report.incidentDate.month}/${report.incidentDate.year}',
                    style: TextStyle(
                      color: Constants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Constants.background,
      child: Column(
        children: [
          Container(
            color: Constants.surface,
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            child: TabBar(
              controller: _tabController,
              labelColor: Constants.primary,
              unselectedLabelColor: Constants.textSecondary,
              indicatorColor: Constants.primary,
              tabs: [
                Tab(
                  icon: Icon(Icons.map),
                  text: 'Map View',
                ),
                Tab(
                  icon: Icon(Icons.list),
                  text: 'List View',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapView(),
                _buildListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return RefreshIndicator(
      onRefresh: _refreshReports,
      color: Constants.primary,
      backgroundColor: Constants.surface,
      strokeWidth: 3,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultLocation,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            cameraTargetBounds: CameraTargetBounds(_tinurikBounds),
            minMaxZoomPreference: MinMaxZoomPreference(13.0, 18.0),
          ),
          Positioned(
            top: AppConstants.spacingM,
            left: AppConstants.spacingM,
            right: AppConstants.spacingM,
            child: Container(
              padding: EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: Constants.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Constants.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Constants.primary),
                  SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      'Tinurik, Tanauan City, Batangas - ${_reports.length} reports',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingReports)
            Container(
              color: Constants.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(color: Constants.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Icon(Icons.report, color: Constants.primary),
              SizedBox(width: AppConstants.spacingS),
              Text(
                'Crime Reports',
                style: TextStyle(
                  color: Constants.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                '${_reports.length} item${_reports.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Constants.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshReports,
            color: Constants.primary,
            backgroundColor: Constants.surface,
            strokeWidth: 3,
            child: _isLoadingReports
                ? ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Constants.primary),
                            SizedBox(height: AppConstants.spacingM),
                            Text(
                              'Loading reports...',
                              style: TextStyle(color: Constants.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _reports.isEmpty
                    ? ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 64, color: Constants.textSecondary),
                                SizedBox(height: AppConstants.spacingM),
                                Text(
                                  'No reports found',
                                  style: TextStyle(color: Constants.textSecondary),
                                ),
                                SizedBox(height: AppConstants.spacingS),
                                Text(
                                  'Pull down to refresh',
                                  style: TextStyle(
                                    color: Constants.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(AppConstants.spacingM),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) => _buildReportItem(_reports[index]),
                      ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}