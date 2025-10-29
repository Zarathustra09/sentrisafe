import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../constants.dart';
import '../services/crime_report/crime_report_service.dart';
import '../widgets/crime_selection_modal.dart';

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
  List<String> _selectedCrimes = []; // Changed to list for multiple crimes

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

    // Validate that crime types have been selected
    if (_selectedCrimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one crime type'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    // Validate location coordinates
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please set location coordinates before submitting'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    double? lat = double.tryParse(_latitudeController.text);
    double? lng = double.tryParse(_longitudeController.text);

    if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid location coordinates'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit a report for each selected crime
      List<String> successfulSubmissions = [];
      List<String> failedSubmissions = [];

      for (String crimeType in _selectedCrimes) {
        try {
          final result = await CrimeReportService.submitReport(
            title: crimeType, // Use the crime type as title
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            severity: _selectedSeverity,
            latitude: lat,
            longitude: lng,
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            incidentDate: _selectedDate,
            reportImage: _selectedImage,
          );

          if (result['success']) {
            successfulSubmissions.add(crimeType);
          } else {
            failedSubmissions.add(crimeType);
          }
        } catch (e) {
          failedSubmissions.add(crimeType);
        }
      }

      // Show results
      if (successfulSubmissions.isNotEmpty && failedSubmissions.isEmpty) {
        // All successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All ${successfulSubmissions.length} reports submitted successfully'),
            backgroundColor: Constants.success,
            duration: Duration(seconds: 3),
          ),
        );
        _resetForm();
        setState(() {
          _showReportForm = false;
        });
      } else if (successfulSubmissions.isNotEmpty && failedSubmissions.isNotEmpty) {
        // Partial success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${successfulSubmissions.length} reports submitted successfully, ${failedSubmissions.length} failed'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // All failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit all reports. Please try again.'),
            backgroundColor: Constants.error,
            duration: Duration(seconds: 3),
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
      _selectedCrimes.clear(); // Clear selected crimes
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
                        Icons.phone_in_talk,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Expanded(
                        child: Text(
                          'MAIN HOTLINE - Tap to call the hotline',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                      const SizedBox(height: AppConstants.spacingS),
                     InkWell(
                       onTap: () => _makePhoneCall('911', '911 Emergency Hotline'),
                       child: Container(
                         padding: const EdgeInsets.all(AppConstants.spacingS),
                         decoration: BoxDecoration(
                           color: Constants.background,
                           borderRadius: BorderRadius.circular(
                             AppConstants.radiusS,
                           ),
                           border: Border.all(color: Colors.red),
                         ),
                         child: Row(
                           children: [
                             Icon(Icons.phone, color: Colors.red, size: 20),
                             const SizedBox(width: AppConstants.spacingS),
                             Expanded(
                               child: Text(
                                 'Call now: 911 (Main Hotline)',
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

  Future<void> _showCrimeSelectionModal() async {
    await showDialog(
      context: context,
      builder: (context) => CrimeSelectionModal(
        selectedCrime: _selectedCrimes.isNotEmpty ? _selectedCrimes.first : null,
        onCrimesSelected: (selectedCrimes) { // Changed callback
          setState(() {
            _selectedCrimes = selectedCrimes;
            // Update title controller to show first crime or count
            if (selectedCrimes.isNotEmpty) {
              if (selectedCrimes.length == 1) {
                _titleController.text = selectedCrimes.first;
              } else {
                _titleController.text = '${selectedCrimes.length} crime types selected';
              }
            } else {
              _titleController.text = '';
            }
          });
        },
        selectedSeverity: _selectedSeverity,
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
                  // Crime Type Selection - Updated for multiple selection
                  GestureDetector(
                    onTap: _showCrimeSelectionModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedCrimes.isEmpty
                              ? Constants.greyDark
                              : Constants.primary,
                          width: _selectedCrimes.isEmpty ? 1 : 2,
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        color: _selectedCrimes.isEmpty
                            ? Constants.background
                            : Constants.primary.withOpacity(0.05),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.report_problem,
                            color: _selectedCrimes.isEmpty
                                ? Constants.textSecondary
                                : Constants.primary,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Crime Types *',
                                  style: TextStyle(
                                    color: Constants.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedCrimes.isEmpty
                                      ? 'Tap to select crime types'
                                      : _selectedCrimes.length == 1
                                          ? _selectedCrimes.first
                                          : '${_selectedCrimes.length} crime types selected',
                                  style: TextStyle(
                                    color: _selectedCrimes.isEmpty
                                        ? Constants.textSecondary
                                        : Constants.textPrimary,
                                    fontSize: 16,
                                    fontWeight: _selectedCrimes.isEmpty
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Show selected crimes list
                                if (_selectedCrimes.length > 1) ...[
                                  const SizedBox(height: AppConstants.spacingS),
                                  Wrap(
                                    spacing: AppConstants.spacingXS,
                                    runSpacing: AppConstants.spacingXS,
                                    children: _selectedCrimes.take(3).map((crime) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppConstants.spacingS,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Constants.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                        ),
                                        child: Text(
                                          crime.length > 20 ? '${crime.substring(0, 20)}...' : crime,
                                          style: TextStyle(
                                            color: Constants.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList()
                                      ..addAll(_selectedCrimes.length > 3 ? [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppConstants.spacingS,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Constants.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                          ),
                                          child: Text(
                                            '+${_selectedCrimes.length - 3} more',
                                            style: TextStyle(
                                              color: Constants.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ] : []),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Constants.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Add validation helper text
                  if (_selectedCrimes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        'Please select at least one crime type to continue',
                        style: TextStyle(
                          color: Constants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
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
                  // Submit Button - Updated for multiple reports
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Constants.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingS),
                                Text('Submitting ${_selectedCrimes.length} Report${_selectedCrimes.length == 1 ? '' : 's'}...'),
                              ],
                            )
                          : Text(
                              _selectedCrimes.length <= 1
                                  ? 'Submit Report'
                                  : 'Submit ${_selectedCrimes.length} Reports',
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
