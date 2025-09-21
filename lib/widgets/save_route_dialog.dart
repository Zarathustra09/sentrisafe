import 'package:flutter/material.dart';
import '../constants.dart';

class SaveRouteDialog extends StatefulWidget {
  @override
  _SaveRouteDialogState createState() => _SaveRouteDialogState();
}

class _SaveRouteDialogState extends State<SaveRouteDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Constants.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark_add,
                    color: Constants.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    'Save Route',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Route name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Route Name *',
                  labelStyle: TextStyle(color: Constants.textSecondary),
                  hintText: 'Enter a name for this route',
                  hintStyle: TextStyle(color: Constants.greyDark),
                  prefixIcon: Icon(Icons.route, color: Constants.primary),
                  filled: true,
                  fillColor: Constants.background,
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
                    borderSide: BorderSide(color: Constants.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide(color: Constants.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide(color: Constants.error, width: 2),
                  ),
                ),
                style: TextStyle(color: Constants.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Route name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Route name must be at least 3 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Route name must be less than 50 characters';
                  }
                  return null;
                },
                maxLength: 50,
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: Constants.textSecondary),
                  hintText: 'Add any notes about this route',
                  hintStyle: TextStyle(color: Constants.greyDark),
                  prefixIcon: Icon(Icons.notes, color: Constants.primary),
                  filled: true,
                  fillColor: Constants.background,
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
                    borderSide: BorderSide(color: Constants.primary, width: 2),
                  ),
                ),
                style: TextStyle(color: Constants.textPrimary),
                maxLines: 3,
                maxLength: 200,
                validator: (value) {
                  if (value != null && value.trim().length > 200) {
                    return 'Description must be less than 200 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Constants.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL,
                        vertical: AppConstants.spacingS,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final result = {
                          'name': _nameController.text.trim(),
                          'description': _descriptionController.text.trim(),
                        };
                        Future.microtask(() {
                          Navigator.of(context).pop(result);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL,
                        vertical: AppConstants.spacingS,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.save, size: 18),
                        SizedBox(width: 4),
                        Text('Save Route'),
                      ],
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
}