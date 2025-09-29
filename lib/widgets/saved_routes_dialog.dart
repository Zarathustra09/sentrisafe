import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/saved_route_model.dart';
import '../services/route_database_helper.dart';
import 'dart:convert';
import '../pages/map_page.dart'; // For CrimeAnalysis

class SavedRoutesDialog extends StatefulWidget {
  final Function(SavedRoute) onRouteSelected;

  const SavedRoutesDialog({
    Key? key,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  _SavedRoutesDialogState createState() => _SavedRoutesDialogState();
}

class _SavedRoutesDialogState extends State<SavedRoutesDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedRoute> _savedRoutes = [];
  List<SavedRoute> _filteredRoutes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'safer', 'regular'

  @override
  void initState() {
    super.initState();
    _loadSavedRoutes();
    _searchController.addListener(_filterRoutes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRoutes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final routeModels = await RouteDatabaseHelper().getRoutes();
      final routes = routeModels.map((model) => SavedRoute(
        id: model.id ?? 0,
        name: model.name,
        description: model.description,
        startLat: model.startLat,
        startLng: model.startLng,
        endLat: model.endLat,
        endLng: model.endLng,
        startAddress: model.startAddress,
        endAddress: model.endAddress,
        polyline: model.polyline,
        safetyScore: model.safetyScore,
        duration: model.duration,
        distance: model.distance,
        crimeAnalysis: model.crimeAnalysisJson != null ? CrimeAnalysis.fromJson(jsonDecode(model.crimeAnalysisJson!)) : null,
        isSaferRoute: model.isSaferRoute,
        routeType: model.routeType,
        createdAt: DateTime.parse(model.createdAt),
        updatedAt: DateTime.parse(model.updatedAt),
      )).toList();
      setState(() {
        _savedRoutes = routes;
        _filteredRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load saved routes: $e';
        _isLoading = false;
      });
    }
  }

  void _filterRoutes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRoutes = _savedRoutes.where((route) {
        return route.name.toLowerCase().contains(query) ||
            route.startAddress.toLowerCase().contains(query) ||
            route.endAddress.toLowerCase().contains(query) ||
            (route.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _deleteRoute(SavedRoute route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Constants.surface,
        title: Text(
          'Delete Route',
          style: TextStyle(color: Constants.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${route.name}"?',
          style: TextStyle(color: Constants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Constants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Constants.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RouteDatabaseHelper().deleteRoute(route.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route deleted.'),
            backgroundColor: Constants.success,
          ),
        );
        _loadSavedRoutes();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete route: $e'),
            backgroundColor: Constants.error,
          ),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: AppConstants.spacingS),
          _buildFilterChip('Safer Routes', 'safer'),
          const SizedBox(width: AppConstants.spacingS),
          _buildFilterChip('Regular Routes', 'regular'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Constants.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadSavedRoutes();
      },
      selectedColor: Constants.primary,
      backgroundColor: Constants.surface,
      side: BorderSide(color: Constants.greyDark),
    );
  }

  Widget _buildRouteItem(SavedRoute route) {
    return Card(
      color: Constants.surface,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        onTap: () => widget.onRouteSelected(route),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    route.isSaferRoute ? Icons.security : Icons.route,
                    color: route.isSaferRoute ? Constants.success : Constants.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      route.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Constants.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (route.safetyScore != null) ...[
                    Icon(Icons.star, color: Constants.warning, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      route.safetyScore!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        color: Constants.textSecondary,
                      ),
                    ),
                  ],
                  IconButton(
                    icon: Icon(Icons.delete, color: Constants.error, size: 20),
                    onPressed: () => _deleteRoute(route),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              Row(
                children: [
                  Icon(Icons.location_on, color: Constants.success, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      route.startAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Constants.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.flag, color: Constants.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      route.endAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Constants.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (route.description != null && route.description!.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  route.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Constants.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppConstants.spacingS),
              Row(
                children: [
                  if (route.duration != null) ...[
                    Icon(Icons.access_time, color: Constants.accent, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      route.duration!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Constants.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                  ],
                  if (route.distance != null) ...[
                    Icon(Icons.straighten, color: Constants.accent, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      route.distance!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Constants.textSecondary,
                      ),
                    ),
                    const Spacer(),
                  ],
                  Text(
                    '${route.createdAt.day}/${route.createdAt.month}/${route.createdAt.year}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Constants.greyDark,
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

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Constants.background,
      child: Scaffold(
        backgroundColor: Constants.background,
        appBar: AppBar(
          backgroundColor: Constants.surface,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.close, color: Constants.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Saved Routes',
            style: TextStyle(
              color: Constants.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Constants.primary),
              onPressed: _loadSavedRoutes,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            children: [

              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search routes...',
                  hintStyle: TextStyle(color: Constants.greyDark),
                  prefixIcon: Icon(Icons.search, color: Constants.primary),
                  filled: true,
                  fillColor: Constants.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Constants.textPrimary),
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Filter chips
              _buildFilterChips(),
              const SizedBox(height: AppConstants.spacingM),

              // Routes list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Constants.error,
                        size: 48,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Constants.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      ElevatedButton(
                        onPressed: _loadSavedRoutes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : _filteredRoutes.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        color: Constants.greyDark,
                        size: 64,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No saved routes yet'
                            : 'No routes found matching your search',
                        style: TextStyle(
                          color: Constants.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Create your first route and save it!'
                            : 'Try adjusting your search terms',
                        style: TextStyle(
                          color: Constants.greyDark,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredRoutes.length,
                  itemBuilder: (context, index) {
                    return _buildRouteItem(_filteredRoutes[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}