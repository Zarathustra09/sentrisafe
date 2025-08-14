import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
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
                Icon(
                  Icons.home_outlined,
                  size: 48,
                  color: Constants.primary,
                ),
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
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    icon: Icon(Icons.report, size: 28),
                    label: Text(
                      'Report Incident',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      // Emergency functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.error,
                      foregroundColor: Constants.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    icon: Icon(Icons.emergency, size: 28),
                    label: Text(
                      'Emergency',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: Constants.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Incident Title',
                      labelStyle: TextStyle(color: Constants.textSecondary),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: Constants.textPrimary),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Constants.textSecondary),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
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
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
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
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primary,
                          foregroundColor: Constants.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
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
                        label: Text(_isLoadingLocation ? 'Getting...' : 'Use Current'),
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
                            labelStyle: TextStyle(color: Constants.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
                            labelStyle: TextStyle(color: Constants.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        borderSide: BorderSide(color: Constants.greyDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  // Date Picker
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Constants.greyDark),
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Constants.textSecondary),
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
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Constants.greyDark),
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt, color: Constants.textSecondary),
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
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        ),
                      ),
                      child: _isSubmitting
                          ? CircularProgressIndicator(color: Constants.white)
                          : Text(
                              'Submit Report',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    return _showReportForm ? _buildReportForm() : _buildDashboard();
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