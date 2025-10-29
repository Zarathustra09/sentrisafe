import 'package:flutter/material.dart';
import '../constants.dart';

class CrimeSelectionModal extends StatefulWidget {
  final String? selectedCrime;
  final Function(String) onCrimeSelected;

  const CrimeSelectionModal({
    Key? key,
    this.selectedCrime,
    required this.onCrimeSelected,
  }) : super(key: key);

  @override
  State<CrimeSelectionModal> createState() => _CrimeSelectionModalState();
}

class _CrimeSelectionModalState extends State<CrimeSelectionModal> {
  late TextEditingController _searchController;
  String _searchQuery = '';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    Icons.report_problem,
                    color: Constants.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Text(
                      'Select Crime Type',
                      style: TextStyle(
                        color: Constants.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

            // Results count
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredCrimeTypes.length} crime type${_filteredCrimeTypes.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      color: Constants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppConstants.spacingS),

            // Crime Types List
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
                        final isSelected = widget.selectedCrime == crimeType;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                          child: InkWell(
                            onTap: () {
                              widget.onCrimeSelected(crimeType);
                              Navigator.of(context).pop();
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
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Constants.primary,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom section with selected crime
            if (widget.selectedCrime != null)
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
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Constants.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        'Selected: ${widget.selectedCrime}',
                        style: TextStyle(
                          color: Constants.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
