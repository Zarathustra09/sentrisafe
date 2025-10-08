import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../constants.dart';
import '../services/crime_report/crime_report_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showReportForm = false;
  bool _showEmergencyContacts = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String _selectedSeverity = 'low';
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location obtained successfully'),
          backgroundColor: Constants.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Constants.error,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      PermissionStatus cameraPermission = await Permission.camera.request();
      if (cameraPermission.isGranted) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera permission is required to take photos'),
            backgroundColor: Constants.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Constants.error,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Constants.primary,
              surface: Constants.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await CrimeReportService.submitReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null // Pass null if description is empty
            : _descriptionController.text.trim(),
        severity: _selectedSeverity,
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        incidentDate: _selectedDate,
        reportImage: _selectedImage,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Constants.success,
            duration: Duration(seconds: 2),
          ),
        );
        _resetForm();
        setState(() {
          _showReportForm = false;
        });
      } else {
        String errorMessage = 'Failed to submit report';
        if (result['errors'] is Map) {
          errorMessage = result['errors'].values.first.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Constants.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Constants.error,
        ),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _addressController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    setState(() {
      _selectedSeverity = 'low';
      _selectedDate = DateTime.now();
      _selectedImage = null;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber, String serviceName) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Constants.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          title: Row(
            children: [
              Icon(Icons.phone, color: Constants.primary, size: 24),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  'Confirm Call',
                  style: TextStyle(
                    color: Constants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to call $serviceName?',
                style: TextStyle(color: Constants.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: Constants.background,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  border: Border.all(color: Constants.greyDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Constants.success, size: 20),
                    const SizedBox(width: AppConstants.spacingS),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Constants.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.success,
                foregroundColor: Constants.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
              ),
              icon: Icon(Icons.phone, size: 20),
              label: Text('Call Now'),
            ),
          ],
        );
      },
    );

    // If user confirmed, make the call
    if (confirm == true) {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

      try {
        if (!await launchUrl(launchUri)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Could not launch phone dialer for: $cleanNumber',
                ),
                backgroundColor: Constants.error,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Constants.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Widget _buildEmergencyContacts() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      color: Constants.background,
      child: ListView(
        children: [
          // Back Button and Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showEmergencyContacts = false;
                  });
                },
                icon: Icon(Icons.arrow_back, color: Constants.textPrimary),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Icon(Icons.emergency, color: Constants.error, size: 24),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'Emergency Contacts',
                style: TextStyle(
                  color: Constants.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: Constants.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TEST CARD - For testing phone call feature
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bug_report,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: Text(
                              'TEST CARD - Tap to Test Call Feature',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      InkWell(
                        onTap: () =>
                            _makePhoneCall('1234567890', 'Test Contact'),
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.spacingS),
                          decoration: BoxDecoration(
                            color: Constants.background,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusS,
                            ),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.phone, color: Colors.orange, size: 20),
                              const SizedBox(width: AppConstants.spacingS),
                              Expanded(
                                child: Text(
                                  'Tap here to test: 123-456-7890',
                                  style: TextStyle(
                                    color: Constants.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        '✓ This will show the confirmation dialog',
                        style: TextStyle(
                          color: Constants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '✓ Cancel to avoid actually calling',
                        style: TextStyle(
                          color: Constants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),

                // BFP Section
                _buildEmergencyContactCard(
                  icon: Icons.local_fire_department,
                  iconColor: Constants.error,
                  title: 'BFP',
                  subtitle: 'Tanauan City Fire Station',
                  landline: '(043) 778-2018',
                  mobile: '0922-344-8887',
                ),
                const SizedBox(height: AppConstants.spacingM),

                // PNP Section
                _buildEmergencyContactCard(
                  icon: Icons.local_police,
                  iconColor: Colors.blue,
                  title: 'PNP',
                  subtitle: 'Tanauan City Police Station',
                  landline: '(043) 778-1126',
                  mobile: '0939-322-7848',
                ),
                const SizedBox(height: AppConstants.spacingM),

                // Hospitals Section
                Text(
                  'Hospitals',
                  style: TextStyle(
                    color: Constants.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                _buildHospitalCard(
                  name: 'C.P. Reyes Hospital',
                  phone: '(043) 784-5401',
                ),
                const SizedBox(height: AppConstants.spacingS),
                _buildHospitalCard(
                  name: 'Daniel O. Mercado Medical Center',
                  phone: '(043) 778-1810',
                ),
                const SizedBox(height: AppConstants.spacingS),
                _buildHospitalCard(
                  name: 'Laurel District Memorial Hospital',
                  phone: '(043) 706-5255',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String landline,
    required String mobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Constants.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: Constants.greyDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Constants.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Constants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Constants.greyDark, height: 1),
          InkWell(
            onTap: () => _makePhoneCall(landline, '$title - Landline'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingM,
              ),
              child: _buildContactRow(Icons.phone, 'Landline', landline),
            ),
          ),
          Divider(color: Constants.greyDark, height: 1),
          InkWell(
            onTap: () => _makePhoneCall(mobile, '$title - Mobile'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingM,
              ),
              child: _buildContactRow(Icons.smartphone, 'Mobile', mobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard({required String name, required String phone}) {
    return InkWell(
      onTap: () => _makePhoneCall(phone, name),
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: Constants.background,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: Constants.greyDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: Constants.success, size: 24),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Constants.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.phone, color: Constants.primary, size: 20),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                phone,
                style: TextStyle(
                  color: Constants.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Constants.primary, size: 20),
        const SizedBox(width: AppConstants.spacingS),
        Text(
          '$label: ',
          style: TextStyle(color: Constants.textSecondary, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Constants.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      color: Constants.background,
      child: Column(
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingXL),
            decoration: BoxDecoration(
              color: Constants.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Constants.black.withOpacity(0.1),
                  blurRadius: AppConstants.elevationL,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.home_outlined, size: 48, color: Constants.primary),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'Welcome Home',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Constants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Stay safe and connected with your community',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Constants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          // Quick Actions Section
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: Constants.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Constants.black.withOpacity(0.1),
                  blurRadius: AppConstants.elevationL,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Constants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                // Report Incident Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showReportForm = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primary,
                      foregroundColor: Constants.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                    ),
                    icon: Icon(Icons.report, size: 28),
                    label: Text(
                      'Report Incident',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                // Emergency Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showEmergencyContacts = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.error,
                      foregroundColor: Constants.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                    ),
                    icon: Icon(Icons.emergency, size: 28),
                    label: Text(
                      'Emergency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportForm() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      color: Constants.background,
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Back Button and Header
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showReportForm = false;
                    });
                  },
                  icon: Icon(Icons.arrow_back, color: Constants.textPrimary),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Report Incident',
                  style: TextStyle(
                    color: Constants.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: Constants.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field - Fixed Dropdown
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _titleController.text.isNotEmpty
                        ? _titleController.text
                        : null,
                    style: TextStyle(color: Constants.textPrimary),
                    dropdownColor: Constants.surface,
                    decoration: InputDecoration(
                      labelText: 'Incident Title',
                      labelStyle: TextStyle(color: Constants.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items:
                        [
                              'Illegal gambling (STL, jueteng)',
                              'Illegal possession of firearms',
                              'Drug-related offenses (shabu buy-busts)',
                              'Robbery / Burglary (shops, houses)',
                              'Snatching / street theft (often by motorcycle riders)',
                              'Violent crimes (murder, shootings, assaults)',
                              'Sexual offenses (rape, harassment)',
                              'Murder / Homicide',
                              'Physical injuries / Assault',
                              'Rape / Sexual assault',
                              'Robbery',
                              'Theft / Snatching',
                              'Burglary',
                              'Carnapping',
                              'Arson',
                              'Illegal drugs (possession, trafficking, use)',
                              'Illegal possession of firearms',
                              'Illegal discharge of firearms',
                              'Violence against women and children (VAWC)',
                              'Child abuse / exploitation',
                              'Human trafficking',
                              'Estafa / Swindling',
                              'Cybercrime (scams, hacking, phishing)',
                              'Forgery / Falsification of documents',
                              'Bribery / Corruption',
                              'Illegal recruitment',
                              'Illegal gambling',
                              'Drunk and disorderly conduct',
                              'Vandalism',
                              'Public scandal / Grave threats / Grave coercion',
                              'Trespassing',
                              'Environmental crimes (illegal logging, quarrying, wildlife trade)',
                              'Smuggling',
                              'Curfew violations',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _titleController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Description Field - Made Optional
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: Constants.textPrimary),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: Constants.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.primary),
                      ),
                    ),
                    // Validator removed to make it optional
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Severity Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSeverity,
                    style: TextStyle(color: Constants.textPrimary),
                    dropdownColor: Constants.surface,
                    decoration: InputDecoration(
                      labelText: 'Severity',
                      labelStyle: TextStyle(color: Constants.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('Critical'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSeverity = value!;
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Location Section with Get Current Location Button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Location',
                          style: TextStyle(
                            color: Constants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoadingLocation
                            ? null
                            : _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primary,
                          foregroundColor: Constants.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusS,
                            ),
                          ),
                        ),
                        icon: _isLoadingLocation
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Constants.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.my_location, size: 20),
                        label: Text(
                          _isLoadingLocation ? 'Getting...' : 'Use Current',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  // Location Fields Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          style: TextStyle(color: Constants.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            labelStyle: TextStyle(
                              color: Constants.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                              borderSide: BorderSide(color: Constants.greyDark),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            double? lat = double.tryParse(value);
                            if (lat == null || lat < -90 || lat > 90) {
                              return 'Invalid latitude';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          style: TextStyle(color: Constants.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            labelStyle: TextStyle(
                              color: Constants.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                              borderSide: BorderSide(color: Constants.greyDark),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            double? lng = double.tryParse(value);
                            if (lng == null || lng < -180 || lng > 180) {
                              return 'Invalid longitude';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Address Field
                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: Constants.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Address (Optional)',
                      labelStyle: TextStyle(color: Constants.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Date Picker
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Constants.greyDark),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Constants.textSecondary,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Text(
                            'Incident Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: TextStyle(color: Constants.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Camera Picker
                  GestureDetector(
                    onTap: _pickImageFromCamera,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Constants.greyDark),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Constants.textSecondary,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: Text(
                              _selectedImage != null
                                  ? 'Photo selected: ${_selectedImage!.path.split('/').last}'
                                  : 'Tap to take a photo (optional)',
                              style: TextStyle(color: Constants.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primary,
                        foregroundColor: Constants.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusM,
                          ),
                        ),
                      ),
                      child: _isSubmitting
                          ? CircularProgressIndicator(color: Constants.white)
                          : Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold, TopNavbar, or BottomNavbar here
    if (_showEmergencyContacts) {
      return _buildEmergencyContacts();
    } else if (_showReportForm) {
      return _buildReportForm();
    } else {
      return _buildDashboard();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}
