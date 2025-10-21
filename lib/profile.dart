import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'constants.dart';
import 'services/profile/profile_service.dart';
import 'services/crime_report/crime_report_service.dart';
import 'services/auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String email = "";
  String? profileImageUrl;
  String address = "";
  bool isVerified = false;

  // Crime reports data - using raw Map data
  List<Map<String, dynamic>> crimeReports = [];
  bool isLoadingReports = false;
  String? selectedSeverity;
  String? selectedStatus;
  int currentPage = 1;
  int totalPages = 1;
  int totalReports = 0;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  bool isEditing = false;
  bool isLoading = true;
  int? selectedReportIdx;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCrimeReports();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    final result = await ProfileService.getProfile();

    if (result['success']) {
      final data = result['data'];
      setState(() {
        name = data['name'] ?? '';
        email = data['email'] ?? '';
        profileImageUrl = data['profile_picture'];
        address = data['address'] ?? '';
        isVerified = data['is_verified'] ?? false;
        _nameController.text = name;
        _emailController.text = email;
        _addressController.text = address;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      _showError(result['error']);
    }
  }

  Future<void> _loadCrimeReports({bool reset = false}) async {
    if (reset) {
      setState(() {
        currentPage = 1;
        crimeReports.clear();
      });
    }

    setState(() => isLoadingReports = true);

    final result = await CrimeReportService.getMyReports(
      severity: selectedSeverity,
      status: selectedStatus,
      page: currentPage,
    );

    print('=== PROFILE PAGE DEBUG ===');
    print('Result success: ${result['success']}');
    print('Result keys: ${result.keys.toList()}');

    if (result['success']) {
      final data = result['data'];
      List<Map<String, dynamic>> reports = [];
      int current = 1;
      int total = 1;
      int totalCount = 0;

      if (data is Map) {
        if (data.containsKey('reports')) {
          // Handle the service response structure: data.reports
          final reportsData = data['reports'];
          if (reportsData is List) {
            reports = reportsData.map<Map<String, dynamic>>((report) {
              // Convert CrimeReport objects to Map if needed
              if (report is Map<String, dynamic>) {
                return report;
              } else {
                // If it's a CrimeReport object, convert it to Map
                // Use toJson() method if available, or manual conversion
                try {
                  return report.toJson();
                } catch (e) {
                  // Fallback to manual conversion
                  return {
                    'id': report.id,
                    'title': report.title,
                    'description': report.description,
                    'severity': report.severity,
                    'latitude': report.latitude.toString(),
                    'longitude': report.longitude.toString(),
                    'address': report.address,
                    'report_image': report.reportImage,
                    'incident_date': report.incidentDate.toIso8601String(),
                    'reported_by': report.reportedBy,
                    'created_at': report.createdAt.toIso8601String(),
                    'updated_at': report.updatedAt.toIso8601String(),
                    // Note: status is not included since CrimeReport doesn't have it
                    'status': 'pending', // Default value
                  };
                }
              }
            }).toList();
          }

          final pagination = data['pagination'] ?? {};
          current = pagination['current_page'] ?? 1;
          total = pagination['last_page'] ?? 1;
          totalCount = pagination['total'] ?? reports.length;
          print(
              'Processing custom service response with ${reports.length} reports');
        }
      }

      print('Final reports count: ${reports.length}');
      print('Total count: $totalCount');

      setState(() {
        if (reset) {
          crimeReports = reports;
        } else {
          crimeReports.addAll(reports);
        }
        currentPage = current;
        totalPages = total;
        totalReports = totalCount;
        isLoadingReports = false;
      });

      print('Updated state - crimeReports length: ${crimeReports.length}');
    } else {
      setState(() => isLoadingReports = false);
      _showError(result['error'] ?? 'Failed to load reports');
    }
  }

  Future<void> _loadMoreReports() async {
    if (currentPage < totalPages && !isLoadingReports) {
      currentPage++;
      await _loadCrimeReports();
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showError('Name and email are required');
      return;
    }

    setState(() => isLoading = true);

    final result = await ProfileService.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      password:
          _passwordController.text.isNotEmpty ? _passwordController.text : null,
      address: _addressController.text,
    );

    setState(() => isLoading = false);

    if (result['success']) {
      final data = result['data'];
      setState(() {
        name = data['name'];
        email = data['email'];
        profileImageUrl = data['profile_picture'];
        address = data['address'] ?? address;
        isEditing = false;
      });
      _showSuccess(result['message']);
    } else {
      _showError(result['error']);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => isLoading = true);

      final result = await ProfileService.uploadProfileImage(File(image.path));

      setState(() => isLoading = false);

      if (result['success']) {
        setState(() {
          profileImageUrl = result['image_url'];
        });
        _showSuccess(result['message']);
      } else {
        _showError(result['error']);
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Constants.surface,
          title: Text(
            'Logout',
            style: TextStyle(color: Constants.textPrimary),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Constants.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Constants.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.error,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop();

                if (!mounted) return;

                setState(() => isLoading = true);

                final result = await AuthService.logout();

                if (!mounted) return;

                setState(() => isLoading = false);

                if (result['success']) {
                  navigator.pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Logout failed'),
                      backgroundColor: Constants.error,
                    ),
                  );
                }
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Constants.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Constants.success,
      ),
    );
  }

  Widget _buildNoReportsFound() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: Constants.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_gmailerrorred_outlined,
              size: 64,
              color: Constants.textSecondary,
            ),
          ),
          SizedBox(height: AppConstants.spacingL),
          Text(
            'No Crime Reports Yet',
            style: TextStyle(
              color: Constants.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.spacingS),
          Text(
            selectedSeverity != null || selectedStatus != null
                ? 'No reports match your current filters.\nTry adjusting your search criteria.'
                : 'You haven\'t submitted any crime reports yet.\nStart by reporting incidents to help keep your community safe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Constants.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: AppConstants.spacingL),
          if (selectedSeverity != null || selectedStatus != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Constants.primary),
                foregroundColor: Constants.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              icon: Icon(Icons.clear_all),
              label: Text('Clear Filters'),
              onPressed: () {
                setState(() {
                  selectedSeverity = null;
                  selectedStatus = null;
                });
                _loadCrimeReports(reset: true);
              },
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primary,
                foregroundColor: Constants.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              icon: Icon(Icons.add_circle_outline),
              label: Text('Submit Your First Report'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCrimeReportCard(Map<String, dynamic> report, int index) {
    final isSelected = selectedReportIdx == index;
    final createdAt = DateTime.tryParse(report['created_at']?.toString() ?? '');
    final formattedDate = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
        : 'Unknown date';

    return AnimatedContainer(
      duration: AppConstants.animationMedium,
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Constants.surface : Constants.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Constants.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        onTap: () {
          setState(() {
            selectedReportIdx = isSelected ? null : index;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                report['title']?.toString() ?? 'Untitled Report',
                style: TextStyle(
                  color: Constants.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(
                              report['severity']?.toString() ?? 'low'),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (report['severity']?.toString() ?? 'Unknown')
                              .toUpperCase(),
                          style: TextStyle(
                            color: Constants.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                              report['status']?.toString() ?? 'pending'),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (report['status']?.toString() ?? 'Pending')
                              .toUpperCase(),
                          style: TextStyle(
                            color: Constants.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Submitted: $formattedDate',
                    style: TextStyle(
                      color: Constants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                isSelected
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Constants.textSecondary,
              ),
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      report['description']?.toString() ??
                          'No description available',
                      style: TextStyle(color: Constants.textSecondary),
                    ),
                    if (report['address'] != null &&
                        report['address'].toString().isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Location:',
                        style: TextStyle(
                          color: Constants.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        report['address'].toString(),
                        style: TextStyle(color: Constants.textSecondary),
                      ),
                    ],
                    SizedBox(height: 8),
                    Text(
                      'Coordinates:',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lat: ${double.tryParse(report['latitude']?.toString() ?? '0')?.toStringAsFixed(6) ?? '0.000000'}, Lng: ${double.tryParse(report['longitude']?.toString() ?? '0')?.toStringAsFixed(6) ?? '0.000000'}',
                      style: TextStyle(color: Constants.textSecondary),
                    ),
                    if (report['report_image'] != null &&
                        report['report_image'].toString().isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Evidence Photo:',
                        style: TextStyle(
                          color: Constants.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusS),
                        child: Image.network(
                          '$storageUrl/${report['report_image']}',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Constants.greyLight,
                              child: Icon(Icons.error, color: Constants.error),
                            );
                          },
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
                    Text(
                      'Incident Date:',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateTime.tryParse(
                                  report['incident_date']?.toString() ?? '')
                              ?.toLocal()
                              .toString()
                              .split(' ')[0] ??
                          'Unknown',
                      style: TextStyle(color: Constants.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
        return Constants.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Constants.success;
      case 'investigating':
        return Constants.info;
      case 'pending':
        return Constants.warning;
      case 'closed':
        return Constants.greyDark;
      default:
        return Constants.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Constants.surface,
          title: Text(
            'Filter Reports',
            style: TextStyle(color: Constants.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSeverity,
                decoration: InputDecoration(
                  labelText: 'Severity',
                  labelStyle: TextStyle(color: Constants.textSecondary),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: Constants.surface,
                style: TextStyle(color: Constants.textPrimary),
                items: ['high', 'medium', 'low'].map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Text(severity.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSeverity = value;
                  });
                },
              ),
              SizedBox(height: AppConstants.spacingM),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: Constants.textSecondary),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: Constants.surface,
                style: TextStyle(color: Constants.textPrimary),
                items: ['pending', 'investigating', 'resolved', 'closed']
                    .map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSeverity = null;
                  selectedStatus = null;
                });
                Navigator.of(context).pop();
                _loadCrimeReports(reset: true);
              },
              child: Text(
                'Clear',
                style: TextStyle(color: Constants.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _loadCrimeReports(reset: true);
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      appBar: AppBar(
        backgroundColor: Constants.surface,
        elevation: AppConstants.elevationM,
        title: Text(
          "Profile",
          style: TextStyle(
            color: Constants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Constants.textPrimary),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(
              Icons.logout,
              color: Constants.error,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Constants.primary,
              ),
            )
          : Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Card
                    Container(
                      decoration: BoxDecoration(
                        color: Constants.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                        boxShadow: [
                          BoxShadow(
                            color: Constants.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(AppConstants.spacingM),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Image with camera icon
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Constants.primary,
                                backgroundImage: profileImageUrl != null
                                    ? NetworkImage(profileImageUrl!)
                                    : null,
                                child: profileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Constants.white,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Constants.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Constants.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: AppConstants.spacingL),
                          // Name, Email, Verification Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isEditing
                                    ? TextField(
                                        controller: _nameController,
                                        style: TextStyle(
                                          color: Constants.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Name",
                                          labelStyle: TextStyle(
                                            color: Constants.textSecondary,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusS,
                                            ),
                                            borderSide: BorderSide(
                                              color: Constants.primary,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusS,
                                            ),
                                            borderSide: BorderSide(
                                              color: Constants.primaryDark,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Constants.surface,
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: Constants.textPrimary,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.verified,
                                              color: Constants.success,
                                              size: 20,
                                            ),
                                          ],
                                        ],
                                      ),
                                SizedBox(height: AppConstants.spacingS),
                                isEditing
                                    ? TextField(
                                        controller: _emailController,
                                        style: TextStyle(
                                          color: Constants.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Email",
                                          labelStyle: TextStyle(
                                            color: Constants.textSecondary,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusS,
                                            ),
                                            borderSide: BorderSide(
                                              color: Constants.primary,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusS,
                                            ),
                                            borderSide: BorderSide(
                                              color: Constants.primaryDark,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Constants.surface,
                                        ),
                                      )
                                    : Text(
                                        email,
                                        style: TextStyle(
                                          color: Constants.textPrimary,
                                          fontSize: 16,
                                        ),
                                      ),
                                SizedBox(height: AppConstants.spacingS),
                                isEditing
                                    ? TextField(
                                        controller: _addressController,
                                        style: TextStyle(
                                          color: Constants.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Address",
                                          labelStyle: TextStyle(
                                            color: Constants.textSecondary,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusS,
                                            ),
                                            borderSide: BorderSide(
                                              color: Constants.primary,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusS,
                                            ),
                                            borderSide: BorderSide(
                                              color: Constants.primaryDark,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Constants.surface,
                                        ),
                                      )
                                    : Text(
                                        address.isNotEmpty
                                            ? address
                                            : 'No address set',
                                        style: TextStyle(
                                          color: Constants.textPrimary,
                                          fontSize: 16,
                                        ),
                                      ),
                                if (isEditing) ...[
                                  SizedBox(height: AppConstants.spacingS),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    style: TextStyle(
                                      color: Constants.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      labelText:
                                          "New Password (leave empty to keep current)",
                                      labelStyle: TextStyle(
                                        color: Constants.textSecondary,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.radiusS,
                                        ),
                                        borderSide: BorderSide(
                                          color: Constants.primary,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.radiusS,
                                        ),
                                        borderSide: BorderSide(
                                          color: Constants.primaryDark,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Constants.surface,
                                    ),
                                  ),
                                ],
                                SizedBox(height: AppConstants.spacingS),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Constants.primary,
                                      foregroundColor: Constants.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.radiusS,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppConstants.spacingXS,
                                        horizontal: AppConstants.spacingM,
                                      ),
                                    ),
                                    icon: Icon(
                                        isEditing ? Icons.save : Icons.edit),
                                    label: Text(
                                      isEditing
                                          ? "Save Profile"
                                          : "Edit Profile",
                                    ),
                                    onPressed: () {
                                      if (isEditing) {
                                        _updateProfile();
                                      } else {
                                        setState(() => isEditing = true);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingL),
                    // Submitted Reports Section
                    AnimatedContainer(
                      width: double.infinity,
                      duration: AppConstants.animationMedium,
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: Constants.secondaryLight,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                      padding: EdgeInsets.all(AppConstants.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "My Crime Reports ($totalReports)",
                                style: TextStyle(
                                  color: Constants.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _showFilterDialog,
                                    icon: Icon(
                                      Icons.filter_list,
                                      color: Constants.primary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _loadCrimeReports(reset: true),
                                    icon: Icon(
                                      Icons.refresh,
                                      color: Constants.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: AppConstants.spacingS),
                          if (isLoadingReports && crimeReports.isEmpty)
                            Center(
                              child: CircularProgressIndicator(
                                color: Constants.primary,
                              ),
                            )
                          else if (crimeReports.isEmpty)
                            _buildNoReportsFound()
                          else
                            Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: crimeReports.length,
                                  itemBuilder: (context, idx) {
                                    return _buildCrimeReportCard(
                                        crimeReports[idx], idx);
                                  },
                                ),
                                if (currentPage < totalPages)
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: AppConstants.spacingM),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Constants.primary,
                                        foregroundColor: Constants.white,
                                      ),
                                      onPressed: isLoadingReports
                                          ? null
                                          : _loadMoreReports,
                                      child: isLoadingReports
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Constants.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('Load More'),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingL),
                  ],
                ),
              ),
            ),
    );
  }
}
