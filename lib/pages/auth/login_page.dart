import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../route/route_constant.dart';
import '../../services/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Constants.success,
          ),
        );
        Navigator.pushReplacementNamed(context, homeScreenRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Constants.error,
          ),
        );
      }
    }
  }

  // New helper: opens the forgot-password URL defined in constants
  Future<void> _openForgotPassword() async {
    final uri = Uri.parse(Constants.forgotPasswordUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link'), backgroundColor: Constants.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening link'), backgroundColor: Constants.error),
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
                  SizedBox(height: constraints.maxHeight * 0.1),
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
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Text(
                    "Sign In",
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Constants.textPrimary,
                    ),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.spacingM,
                          ),
                          child: TextFormField(
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
                            style: const TextStyle(
                              color: Constants.textPrimary,
                            ),
                            validator: RequiredValidator(
                              errorText: 'Password is required',
                            ).call,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                              : const Text("Sign in"),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        TextButton(
                          onPressed: _openForgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: Constants.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, registerScreenRoute);
                          },
                          child: Text.rich(
                            const TextSpan(
                              text: "Don't have an account? ",
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(color: Constants.primary),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodyMedium!
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
