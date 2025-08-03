import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants.dart';
import '../../route/route_constant.dart';
import 'dart:async';

class RegistrationPage extends StatefulWidget {
  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  File? _idImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _idImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.08),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.08),
                  Text(
                    "Create Account",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.04),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Name',
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingM * 1.5, vertical: AppConstants.spacingM),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusXL)),
                            ),
                            hintStyle: TextStyle(color: AppColors.textHint),
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                          onSaved: (name) {},
                        ),
                        SizedBox(height: AppConstants.spacingM),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Phone',
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingM * 1.5, vertical: AppConstants.spacingM),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusXL)),
                            ),
                            hintStyle: TextStyle(color: AppColors.textHint),
                          ),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary),
                          onSaved: (phone) {},
                        ),
                        SizedBox(height: AppConstants.spacingM),
                        TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingM * 1.5, vertical: AppConstants.spacingM),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusXL)),
                            ),
                            hintStyle: TextStyle(color: AppColors.textHint),
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                          onSaved: (password) {},
                        ),
                        SizedBox(height: AppConstants.spacingM),
                        // Valid ID Image Upload Field
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                          ),
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingM * 1.5,
                                  vertical: AppConstants.spacingM),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: _idImage == null ? AppColors.textHint : AppColors.primary,
                                    size: 24,
                                  ),
                                  SizedBox(width: AppConstants.spacingM),
                                  Expanded(
                                    child: Text(
                                      _idImage == null ? 'Valid ID' : 'ID Image Selected',
                                      style: TextStyle(
                                        color: _idImage == null ? AppColors.textHint : AppColors.primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (_idImage != null)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(AppConstants.radiusS),
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
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              // Registration logic here, including _idImage
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: AppConstants.elevationM,
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text("Sign Up"),
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
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ],
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: AppColors.textSecondary,
                                ),
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