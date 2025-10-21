import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants.dart';
import '../../route/route_constant.dart';
import '../../services/auth/auth_service.dart';

class RegistrationPage extends StatefulWidget {
  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypePasswordController = TextEditingController();
  File? _idImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRetypePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
    if (_formKey.currentState!.validate() && _idImage != null) {
      setState(() {
        _isLoading = true;
      });

      final result = await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _retypePasswordController.text,
        idImage: _idImage!,
        address: _addressController.text.trim(),
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
    } else if (_idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid ID image'),
          backgroundColor: Constants.error,
        ),
      );
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
                  Image.asset('lib/assets/logo.png', width: 100, height: 100),
                  SizedBox(height: constraints.maxHeight * 0.08),
                  Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Constants.textPrimary,
                        ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.04),
                  Form(
                    key: _formKey,
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
                          validator: RequiredValidator(
                            errorText: 'Name is required',
                          ).call,
                        ),
                        SizedBox(height: AppConstants.spacingM),
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
                        SizedBox(height: AppConstants.spacingM),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: 'Phone',
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
                          validator: RequiredValidator(
                            errorText: 'Phone is required',
                          ).call,
                        ),
                        SizedBox(height: AppConstants.spacingM),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            hintText: 'Address',
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
                          validator: RequiredValidator(
                            errorText: 'Address is required',
                          ).call,
                        ),
                        SizedBox(height: AppConstants.spacingM),
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
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          style: const TextStyle(color: Constants.textPrimary),
                          validator: passwordValidator.call,
                        ),
                        SizedBox(height: AppConstants.spacingM),
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
                              onPressed: () {
                                setState(() {
                                  _obscureRetypePassword =
                                      !_obscureRetypePassword;
                                });
                              },
                            ),
                          ),
                          style: const TextStyle(color: Constants.textPrimary),
                          validator: _validateRetypePassword,
                        ),
                        SizedBox(height: AppConstants.spacingM),
                        // Valid ID Image Upload Field
                        Container(
                          decoration: BoxDecoration(
                            color: Constants.surface,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusXL,
                            ),
                          ),
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusXL,
                            ),
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
                                  SizedBox(width: AppConstants.spacingM),
                                  Expanded(
                                    child: Text(
                                      _idImage == null
                                          ? 'Valid ID'
                                          : 'ID Image Selected',
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
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.radiusS,
                                        ),
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
                        SizedBox(height: AppConstants.spacingL),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                              : const Text("Sign Up"),
                        ),
                        SizedBox(height: AppConstants.spacingM),
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
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
