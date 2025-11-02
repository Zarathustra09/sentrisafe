import 'package:flutter/material.dart';
import '../constants.dart';

class CrimeSelectionModal extends StatefulWidget {
  final String? selectedCrime;
  final Function(List<Map<String, String>>) onCrimesSelected; // Now passes crime with severity
  final String selectedSeverity;

  const CrimeSelectionModal({
    Key? key,
    this.selectedCrime,
    required this.onCrimesSelected,
    required this.selectedSeverity,
  }) : super(key: key);

  @override
  State<CrimeSelectionModal> createState() => _CrimeSelectionModalState();
}

class _CrimeSelectionModalState extends State<CrimeSelectionModal> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  Set<String> _selectedCrimes = {};

  // Map of crime types with their assigned severity
  final Map<String, String> _crimeTypesWithSeverity = {
    // Low Severity
    'Curfew violations': 'low',
    'Drunk and disorderly conduct': 'low',
    'Vandalism': 'low',
    'Public scandal / Grave threats / Grave coercion': 'low',
    'Trespassing': 'low',

    // Medium Severity
    'Estafa / Swindling': 'medium',
    'Cybercrime (scams, hacking, phishing)': 'medium',
    'Forgery / Falsification of documents': 'medium',
    'Bribery / Corruption': 'medium',
    'Illegal recruitment': 'medium',
    'Illegal gambling (STL, jueteng)': 'medium',
    'Illegal gambling': 'medium',
    'Environmental crimes (illegal logging, quarrying, wildlife trade)': 'medium',
    'Smuggling': 'medium',

    // High Severity
    'Robbery / Burglary (shops, houses)': 'high',
    'Robbery': 'high',
    'Burglary': 'high',
    'Theft / Snatching': 'high',
    'Snatching / street theft (often by motorcycle riders)': 'high',
    'Carnapping': 'high',
    'Arson': 'high',
    'Illegal possession of firearms': 'high',
    'Illegal discharge of firearms': 'high',
    'Drug-related offenses (shabu buy-busts)': 'high',
    'Illegal drugs (possession, trafficking, use)': 'high',
    'Physical injuries / Assault': 'high',
    'Violent crimes (murder, shootings, assaults)': 'high',
    'Child abuse / exploitation': 'high',
    'Violence against women and children (VAWC)': 'high',

    // Critical Severity
    'Murder / Homicide': 'critical',
    'Sexual offenses (rape, harassment)': 'critical',
    'Rape / Sexual assault': 'critical',
    'Human trafficking': 'critical',
  };

  List<String> get _filteredCrimeTypes {
    final crimes = _crimeTypesWithSeverity.keys.toList();
    if (_searchQuery.isEmpty) {
      return crimes;
    }
    return crimes
        .where((crime) => crime.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    if (widget.selectedCrime != null && widget.selectedCrime!.isNotEmpty) {
      _selectedCrimes.add(widget.selectedCrime!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    if (_selectedCrimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one crime type'),
          backgroundColor: Constants.error,
        ),
      );
      return;
    }

    // Create list of maps with crime and severity
    List<Map<String, String>> crimesWithSeverity = _selectedCrimes.map((crime) {
      return {
        'crime': crime,
        'severity': _crimeTypesWithSeverity[crime] ?? 'medium',
      };
    }).toList();

    widget.onCrimesSelected(crimesWithSeverity);
    Navigator.of(context).pop();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Constants.error;
      default:
        return Constants.textSecondary;
    }
  }

  String _getSeverityLabel(String severity) {
    return severity[0].toUpperCase() + severity.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: [
            BoxShadow(
              color: Constants.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: Constants.primary.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusL),
                  topRight: Radius.circular(AppConstants.radiusL),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Constants.greyDark,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist,
                    color: Constants.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Crime Types',
                          style: TextStyle(
                            color: Constants.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Each crime has a pre-assigned severity level',
                          style: TextStyle(
                            color: Constants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Constants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Constants.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search crime types...',
                  hintStyle: TextStyle(color: Constants.textSecondary),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Constants.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Constants.textSecondary,
                    ),
                  )
                      : null,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingM,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Selection summary
            if (_selectedCrimes.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: Constants.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: Constants.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Constants.primary, size: 20),
                        const SizedBox(width: AppConstants.spacingS),
                        Text(
                          'Selected (${_selectedCrimes.length}):',
                          style: TextStyle(
                            color: Constants.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCrimes.clear();
                            });
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(color: Constants.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Wrap(
                      spacing: AppConstants.spacingS,
                      runSpacing: AppConstants.spacingXS,
                      children: _selectedCrimes.map((crime) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingS,
                            vertical: AppConstants.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: Constants.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Text(
                            crime.length > 30 ? '${crime.substring(0, 30)}...' : crime,
                            style: TextStyle(
                              color: Constants.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppConstants.spacingS),

            // Crime Types List with severity badges
            Expanded(
              child: _filteredCrimeTypes.isEmpty
                  ? _buildNoResultsWidget()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                ),
                itemCount: _filteredCrimeTypes.length,
                itemBuilder: (context, index) {
                  final crimeType = _filteredCrimeTypes[index];
                  final isSelected = _selectedCrimes.contains(crimeType);
                  final severity = _crimeTypesWithSeverity[crimeType] ?? 'medium';
                  final severityColor = _getSeverityColor(severity);

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCrimes.remove(crimeType);
                          } else {
                            _selectedCrimes.add(crimeType);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      child: Container(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Constants.primary.withOpacity(0.1)
                              : Constants.background,
                          borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(
                            color: isSelected
                                ? Constants.primary
                                : Constants.greyDark,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCrimes.add(crimeType);
                                  } else {
                                    _selectedCrimes.remove(crimeType);
                                  }
                                });
                              },
                              activeColor: Constants.primary,
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Icon(
                              _getCrimeIcon(crimeType),
                              color: isSelected
                                  ? Constants.primary
                                  : Constants.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(width: AppConstants.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crimeType,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Constants.primary
                                          : Constants.textPrimary,
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: severityColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: severityColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      _getSeverityLabel(severity),
                                      style: TextStyle(
                                        color: severityColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom section with select button
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: Constants.background,
                border: Border(
                  top: BorderSide(
                    color: Constants.greyDark,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedCrimes.isEmpty ? null : _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCrimes.isEmpty
                        ? Constants.greyDark
                        : Constants.primary,
                    foregroundColor: Constants.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                  child: Text(
                    _selectedCrimes.isEmpty
                        ? 'Select crime types'
                        : 'Use Selected Crime Types (${_selectedCrimes.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Constants.textSecondary,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'No crime types found',
            style: TextStyle(
              color: Constants.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(
              color: Constants.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primary,
              foregroundColor: Constants.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  IconData _getCrimeIcon(String crimeType) {
    final type = crimeType.toLowerCase();

    if (type.contains('murder') || type.contains('homicide') || type.contains('killing')) {
      return Icons.dangerous;
    } else if (type.contains('rape') || type.contains('sexual')) {
      return Icons.warning;
    } else if (type.contains('robbery') || type.contains('burglary') || type.contains('theft') || type.contains('snatching')) {
      return Icons.money_off;
    } else if (type.contains('drug') || type.contains('shabu')) {
      return Icons.medication;
    } else if (type.contains('firearm') || type.contains('gun')) {
      return Icons.gps_not_fixed;
    } else if (type.contains('gambling')) {
      return Icons.casino;
    } else if (type.contains('assault') || type.contains('violence') || type.contains('injuries')) {
      return Icons.personal_injury;
    } else if (type.contains('child') || type.contains('women')) {
      return Icons.child_care;
    } else if (type.contains('cyber') || type.contains('scam') || type.contains('hacking')) {
      return Icons.computer;
    } else if (type.contains('environment') || type.contains('logging') || type.contains('quarrying')) {
      return Icons.eco;
    } else if (type.contains('corruption') || type.contains('bribery')) {
      return Icons.gavel;
    } else if (type.contains('arson')) {
      return Icons.local_fire_department;
    } else if (type.contains('trafficking')) {
      return Icons.group;
    } else if (type.contains('vandalism')) {
      return Icons.format_paint;
    } else if (type.contains('curfew')) {
      return Icons.access_time;
    } else {
      return Icons.report_problem;
    }
  }
}