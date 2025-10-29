import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants.dart';
import '../../route/route_constant.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/terms_and_conditions_dialog.dart';

class RegistrationPage extends StatefulWidget {
  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypePasswordController = TextEditingController();
  File? _idImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRetypePassword = true;
  bool _acceptedTerms = false;

  // Stepper state + separate form keys so we validate per-step
  int _currentStep = 0;
  final _personalFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  // Barangays list
  final List<String> _barangays = [
    'ALTURA MATANDA',
    'AMBULONG',
    'BAGEAG',
    'BAGUMBAYAN',
    'BALELE',
    'BANADERO',
    'BANJO EAST',
    'BILOG-BILOG',
    'BOOT',
    'CALE',
    'DARASA',
    'JANOPOL ORIENTAL',
    'MABINI',
    'MALAKING PULO',
    'MARIA PAZ',
    'MAUGAT',
    'MONTAÑA (IK-IK)',
    'NATATAS',
    'PAGASPAS',
    'PANTAY BATA',
    'PANTAY MATANDA',
    'POBLACION BARANGAY 1',
    'POBLACION BARANGAY 2',
    'POBLACION BARANGAY 3',
    'POBLACION BARANGAY 4',
    'POBLACION BARANGAY 5',
    'POBLACION BARANGAY 6',
    'POBLACION BARANGAY 7',
    'SAMBAT',
    'SANTOR',
    'SULPOC',
    'SUPLANG',
    'TALAGA',
    'TINURIK',
    'TRAPICHE',
  ];

  String? _selectedBarangay;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _streetAddressController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _idImage = File(pickedFile.path);
      });
    }
  }

  String? _validateRetypePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please retype your password';
    }
    if (value != _passwordController.text) {
      return AppConstants.pasNotMatchErrorText;
    }
    return null;
  }

  Future<void> _register() async {
    // Only validate the current step (security form) since previous steps were already validated
    print('=== Registration Validation Debug ===');
    print('Name: ${_nameController.text}');
    print('Email: ${_emailController.text}');
    print('Phone: ${_phoneController.text}');
    print('Barangay: ${_addressController.text}');
    print('Street: ${_streetAddressController.text}');
    print('Password: ${_passwordController.text.isNotEmpty ? "***" : "empty"}');
    print(
        'Retype: ${_retypePasswordController.text.isNotEmpty ? "***" : "empty"}');
    print('ID Image: ${_idImage != null ? "Selected" : "Not selected"}');

    // Only validate the security form since we're on step 2
    final securityValid = _securityFormKey.currentState?.validate() ?? false;

    print('Security Valid: $securityValid');

    if (!securityValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the security information step'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    // Check if all required data is present
    if (_nameController.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the personal information step'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the personal information step'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty ||
        _streetAddressController.text.trim().isEmpty) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the address information step'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    if (_idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid ID image'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Conditions to continue'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    // All validation passed, proceed with registration
    setState(() {
      _isLoading = true;
    });

    // Combine barangay and street address
    final fullAddress =
        '${_streetAddressController.text.trim()}, ${_addressController.text.trim()}';

    final result = await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _retypePasswordController.text,
      idImage: _idImage!,
      address: fullAddress,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Constants.success,
        ),
      );
      Navigator.pushReplacementNamed(context, loginScreenRoute);
    } else {
      final errors = result['errors'] as Map<String, dynamic>;
      String errorMessage = errors.values.first.toString();
      if (errors.values.first is List) {
        errorMessage = (errors.values.first as List).first.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Constants.error,
        ),
      );
    }
  }

  Widget _buildProgressIndicator() {
    final steps = ['Personal', 'Address', 'Security & ID'];
    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;
            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      // Left connecting line (only for steps after first)
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index <= _currentStep
                                ? Constants.primary
                                : Constants.textHint.withValues(alpha: 0.3),
                          ),
                        ),
                      // Step circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isActive
                              ? Constants.primary
                              : Constants.surface,
                          border: Border.all(
                            color: isCompleted || isActive
                                ? Constants.primary
                                : Constants.textHint.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  color: Constants.white, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Constants.white
                                        : Constants.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      // Right connecting line (only for steps before last)
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < _currentStep
                                ? Constants.primary
                                : Constants.textHint.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? Constants.primary
                          : Constants.textSecondary,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _personalFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Name',
                  filled: true,
                  fillColor: Constants.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM * 1.5,
                    vertical: AppConstants.spacingM,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.radiusXL),
                    ),
                  ),
                  hintStyle: TextStyle(color: Constants.textHint),
                ),
                style: const TextStyle(color: Constants.textPrimary),
                validator:
                    RequiredValidator(errorText: 'Name is required').call,
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Constants.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM * 1.5,
                    vertical: AppConstants.spacingM,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.radiusXL),
                    ),
                  ),
                  hintStyle: TextStyle(color: Constants.textHint),
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Constants.textPrimary),
                validator: emaildValidator.call,
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Phone (Optional)',
                  filled: true,
                  fillColor: Constants.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM * 1.5,
                    vertical: AppConstants.spacingM,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.radiusXL),
                    ),
                  ),
                  hintStyle: TextStyle(color: Constants.textHint),
                ),
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Constants.textPrimary),
                validator: null, // Optional field, no validation required
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _accountFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              // Barangay Searchable Dropdown
              TypeAheadField<String>(
                controller: _addressController,
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Select Barangay',
                      filled: true,
                      fillColor: Constants.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM * 1.5,
                        vertical: AppConstants.spacingM,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppConstants.radiusXL),
                        ),
                      ),
                      hintStyle: TextStyle(color: Constants.textHint),
                    ),
                    style: const TextStyle(color: Constants.textPrimary),
                    validator:
                        RequiredValidator(errorText: 'Please select a barangay')
                            .call,
                  );
                },
                suggestionsCallback: (pattern) {
                  return _barangays
                      .where((barangay) => barangay
                          .toLowerCase()
                          .contains(pattern.toLowerCase()))
                      .toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSelected: (suggestion) {
                  setState(() {
                    _selectedBarangay = suggestion;
                    _addressController.text = suggestion;
                  });
                },
                emptyBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No barangay found'),
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              // Street Address / Unit / Lot Number
              TextFormField(
                controller: _streetAddressController,
                decoration: InputDecoration(
                  hintText: 'House No. / Street / Unit / Lot No.',
                  filled: true,
                  fillColor: Constants.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM * 1.5,
                    vertical: AppConstants.spacingM,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.radiusXL),
                    ),
                  ),
                  hintStyle: TextStyle(color: Constants.textHint),
                ),
                style: const TextStyle(color: Constants.textPrimary),
                validator:
                    RequiredValidator(errorText: 'Street address is required')
                        .call,
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],
          ),
        );
      case 2:
        return Form(
          key: _securityFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Constants.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM * 1.5,
                    vertical: AppConstants.spacingM,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.radiusXL),
                    ),
                  ),
                  hintStyle: TextStyle(color: Constants.textHint),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Constants.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                style: const TextStyle(color: Constants.textPrimary),
                validator: passwordValidator.call,
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextFormField(
                controller: _retypePasswordController,
                obscureText: _obscureRetypePassword,
                decoration: InputDecoration(
                  hintText: 'Retype Password',
                  filled: true,
                  fillColor: Constants.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM * 1.5,
                    vertical: AppConstants.spacingM,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.radiusXL),
                    ),
                  ),
                  hintStyle: TextStyle(color: Constants.textHint),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRetypePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Constants.textSecondary,
                    ),
                    onPressed: () => setState(
                        () => _obscureRetypePassword = !_obscureRetypePassword),
                  ),
                ),
                style: const TextStyle(color: Constants.textPrimary),
                validator: _validateRetypePassword,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Container(
                decoration: BoxDecoration(
                  color: Constants.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                ),
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM * 1.5,
                      vertical: AppConstants.spacingM,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: _idImage == null
                              ? Constants.textHint
                              : Constants.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Text(
                            _idImage == null ? 'Valid ID' : 'ID Image Selected',
                            style: TextStyle(
                              color: _idImage == null
                                  ? Constants.textHint
                                  : Constants.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_idImage != null)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusS),
                              image: DecorationImage(
                                image: FileImage(_idImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Terms and Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                      });
                    },
                    activeColor: Constants.primary,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Constants.textSecondary),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text:
                                  'Terms and Conditions & Data Privacy Policy',
                              style: const TextStyle(
                                color: Constants.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const TermsAndConditionsDialog(),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Review your details above before submitting.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: Constants.textSecondary),
                ),
              ),
            ],
          ),
        );
      default:
        return Container();
    }
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      // Save the form state before validating
      _personalFormKey.currentState?.save();
      if (_personalFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      // Save the form state before validating
      _accountFormKey.currentState?.save();
      if (_accountFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    } else {
      // Save the security form state before final submit
      _securityFormKey.currentState?.save();
      // final submit
      _register();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.secondary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
              ),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.08),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Constants.white,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: Constants.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'lib/assets/logo.png',
                      width: 48,
                      height: 48,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.08),
                  Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Constants.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  // Custom Progress Indicator
                  _buildProgressIndicator(),
                  const SizedBox(height: AppConstants.spacingXL),
                  // Step Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<int>(_currentStep),
                      child: _buildCurrentStepContent(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleBack,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: const StadiumBorder(),
                              side: const BorderSide(color: Constants.primary),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentStep > 0)
                        const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleContinue,
                          style: ElevatedButton.styleFrom(
                            elevation: AppConstants.elevationM,
                            backgroundColor: Constants.primary,
                            foregroundColor: Constants.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const StadiumBorder(),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Constants.white,
                                    ),
                                  ),
                                )
                              : Text(_currentStep == 2 ? 'Submit' : 'Continue'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, loginScreenRoute);
                    },
                    child: Text.rich(
                      const TextSpan(
                        text: "Already have an account? ",
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: TextStyle(color: Constants.primary),
                          ),
                        ],
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Constants.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
