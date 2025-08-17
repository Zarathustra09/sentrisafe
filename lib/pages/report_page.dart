import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../constants.dart';
import '../services/crime_report/crime_report_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopNavbar(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: AppConstants.spacingL),
                // Step 1: Title
                Row(
                  children: [
                    Icon(Icons.title, color: Constants.primary),
                    SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Incident Title',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingXS),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: Constants.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter a short title',
                    hintStyle: TextStyle(color: Constants.textHint),
                    filled: true,
                    fillColor: Constants.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                SizedBox(height: AppConstants.spacingM),
                // Step 2: Description
                Row(
                  children: [
                    Icon(Icons.description, color: Constants.primary),
                    SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Description',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingXS),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: Constants.textPrimary),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened',
                    hintStyle: TextStyle(color: Constants.textHint),
                    filled: true,
                    fillColor: Constants.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
                SizedBox(height: AppConstants.spacingM),
                // Step 3: Severity
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Constants.primary),
                    SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Severity',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingXS),
                DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  style: TextStyle(color: Constants.textPrimary),
                  dropdownColor: Constants.surface,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Constants.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
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
                SizedBox(height: AppConstants.spacingM),
                // Step 4: Location
                Row(
                  children: [
                    Icon(Icons.location_on, color: Constants.primary),
                    SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Location',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                SizedBox(height: AppConstants.spacingXS),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        style: TextStyle(color: Constants.textPrimary),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Latitude',
                          hintStyle: TextStyle(color: Constants.textHint),
                          filled: true,
                          fillColor: Constants.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                            borderSide: BorderSide.none,
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
                    SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        style: TextStyle(color: Constants.textPrimary),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Longitude',
                          hintStyle: TextStyle(color: Constants.textHint),
                          filled: true,
                          fillColor: Constants.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                            borderSide: BorderSide.none,
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
                SizedBox(height: AppConstants.spacingXS),
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: Constants.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Address (optional)',
                    hintStyle: TextStyle(color: Constants.textHint),
                    filled: true,
                    fillColor: Constants.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.spacingM),
                // Step 5: Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Constants.primary),
                    SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Incident Date',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingXS),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Constants.surfaceLight,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Constants.textSecondary,
                        ),
                        SizedBox(width: AppConstants.spacingM),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(color: Constants.textPrimary),
                        ),
                        Spacer(),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Constants.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.spacingM),
                // Step 6: Photo
                Row(
                  children: [
                    Icon(Icons.camera_alt, color: Constants.primary),
                    SizedBox(width: AppConstants.spacingS),
                    Text(
                      'Photo (optional)',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingXS),
                GestureDetector(
                  onTap: _pickImageFromCamera,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Constants.surfaceLight,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: Constants.textSecondary),
                        SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Text(
                            _selectedImage != null
                                ? 'Photo selected: ${_selectedImage!.path.split('/').last}'
                                : 'Tap to take a photo',
                            style: TextStyle(color: Constants.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.spacingL),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
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
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Constants.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Report',
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
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
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
