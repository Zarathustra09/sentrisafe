import 'package:flutter/material.dart';
import '../constants.dart';

class CrimeSelectionModal extends StatefulWidget {
  final String? selectedCrime;
  final Function(List<String>) onCrimesSelected; // Changed to accept multiple crimes
  final String selectedSeverity;

  const CrimeSelectionModal({
    Key? key,
    this.selectedCrime,
    required this.onCrimesSelected, // Changed parameter name
    required this.selectedSeverity,
  }) : super(key: key);

  @override
  State<CrimeSelectionModal> createState() => _CrimeSelectionModalState();
}

class _CrimeSelectionModalState extends State<CrimeSelectionModal> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  Set<String> _selectedCrimes = {}; // Changed to Set for multiple selection

  // List of all crime types
  final List<String> _crimeTypes = [
    'Illegal gambling (STL, jueteng)',
    'Illegal possession of firearms',
    'Drug-related offenses (shabu buy-busts)',
    'Robbery / Burglary (shops, houses)',
    'Snatching / street theft (often by motorcycle riders)',
    'Violent crimes (murder, shootings, assaults)',
    'Sexual offenses (rape, harassment)',
    'Murder / Homicide',
    'Physical injuries / Assault',
    'Rape / Sexual assault',
    'Robbery',
    'Theft / Snatching',
    'Burglary',
    'Carnapping',
    'Arson',
    'Illegal drugs (possession, trafficking, use)',
    'Illegal possession of firearms',
    'Illegal discharge of firearms',
    'Violence against women and children (VAWC)',
    'Child abuse / exploitation',
    'Human trafficking',
    'Estafa / Swindling',
    'Cybercrime (scams, hacking, phishing)',
    'Forgery / Falsification of documents',
    'Bribery / Corruption',
    'Illegal recruitment',
    'Illegal gambling',
    'Drunk and disorderly conduct',
    'Vandalism',
    'Public scandal / Grave threats / Grave coercion',
    'Trespassing',
    'Environmental crimes (illegal logging, quarrying, wildlife trade)',
    'Smuggling',
    'Curfew violations',
  ];

  List<String> get _filteredCrimeTypes {
    if (_searchQuery.isEmpty) {
      return _crimeTypes;
    }
    return _crimeTypes
        .where((crime) => crime.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Initialize with existing selected crime if any
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
    widget.onCrimesSelected(_selectedCrimes.toList());
    Navigator.of(context).pop();
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
                          'Choose one or more crime types to report',
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

            // Crime Types List (multiple selection with checkboxes)
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
                                    child: Text(
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
