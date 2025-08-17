import 'package:flutter/material.dart';
import 'constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "John Doe";
  int age = 28;
  String location = "123 Main St, Springfield";
  String profileImageUrl = ""; // Use empty for placeholder
  List<String> reports = [
    "Report #1: Suspicious activity",
    "Report #2: Lost item",
    "Report #3: Noise complaint",
  ];

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool isEditing = false;
  int? selectedReportIdx;

  @override
  void initState() {
    super.initState();
    _nameController.text = name;
    _locationController.text = location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
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
      ),
      body: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Card
              Container(
                decoration: BoxDecoration(
                  color: Constants.surfaceLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl.isEmpty
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
                            onTap: () {
                              // Placeholder for changing profile image
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Change profile image tapped!"),
                                  backgroundColor: Constants.info,
                                ),
                              );
                            },
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
                    // Name, Age, Location
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
                              : Text(
                                  name,
                                  style: TextStyle(
                                    color: Constants.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          SizedBox(height: AppConstants.spacingS),
                          // Age as plain text
                          Text(
                            "Age: $age",
                            style: TextStyle(
                              color: Constants.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacingS),
                          isEditing
                              ? TextField(
                                  controller: _locationController,
                                  style: TextStyle(
                                    color: Constants.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Permanent Location",
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
                                  location,
                                  style: TextStyle(
                                    color: Constants.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                          SizedBox(height: AppConstants.spacingS),
                          // Edit Profile Button
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
                              icon: Icon(isEditing ? Icons.save : Icons.edit),
                              label: Text(
                                isEditing ? "Save Profile" : "Edit Profile",
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isEditing) {
                                    name = _nameController.text;
                                    location = _locationController.text;
                                  }
                                  isEditing = !isEditing;
                                });
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
              // Animated Submitted Reports Section
              AnimatedContainer(
                width: double.infinity,
                duration: AppConstants.animationMedium,
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Constants.secondaryLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                padding: EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Submitted Reports",
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingS),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      itemBuilder: (context, idx) {
                        final isSelected = selectedReportIdx == idx;
                        return AnimatedContainer(
                          duration: AppConstants.animationMedium,
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Constants.surface
                                : Constants.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusS,
                            ),
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
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusS,
                            ),
                            onTap: () {
                              setState(() {
                                selectedReportIdx = isSelected ? null : idx;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(
                                    reports[idx],
                                    style: TextStyle(
                                      color: Constants.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: AppConstants.spacingM,
                                      bottom: AppConstants.spacingS,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Constants.primary,
                                          foregroundColor: Constants.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppConstants.radiusS,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          // Placeholder for details action
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Details for ${reports[idx]}",
                                              ),
                                              backgroundColor: Constants.info,
                                            ),
                                          );
                                        },
                                        child: Text("Details"),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
