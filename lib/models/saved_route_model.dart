import '../pages/map_page.dart';

class SavedRoute {
  final int id;
  final String name;
  final String? description;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String startAddress;
  final String endAddress;
  final String polyline;
  final double? safetyScore;
  final String? duration;
  final String? distance;
  final CrimeAnalysis? crimeAnalysis;
  final bool isSaferRoute;
  final String routeType;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedRoute({
    required this.id,
    required this.name,
    this.description,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.startAddress,
    required this.endAddress,
    required this.polyline,
    this.safetyScore,
    this.duration,
    this.distance,
    this.crimeAnalysis,
    required this.isSaferRoute,
    required this.routeType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      startLat: double.parse(json['start_lat'].toString()),
      startLng: double.parse(json['start_lng'].toString()),
      endLat: double.parse(json['end_lat'].toString()),
      endLng: double.parse(json['end_lng'].toString()),
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      polyline: json['polyline'],
      safetyScore: json['safety_score'] != null
          ? double.parse(json['safety_score'].toString())
          : null,
      duration: json['duration'],
      distance: json['distance'],
      crimeAnalysis: json['crime_analysis'] != null
          ? CrimeAnalysis.fromJson(json['crime_analysis'])
          : null,
      isSaferRoute: json['is_safer_route'] ?? false,
      routeType: json['route_type'] ?? 'regular',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'start_address': startAddress,
      'end_address': endAddress,
      'polyline': polyline,
      'safety_score': safetyScore,
      'duration': duration,
      'distance': distance,
      'crime_analysis': crimeAnalysis?.toJson(),
      'is_safer_route': isSaferRoute,
      'route_type': routeType,
    };
  }
}

class SavedRouteStats {
  final int totalRoutes;
  final int saferRoutes;
  final int regularRoutes;
  final double? avgSafetyScore;

  SavedRouteStats({
    required this.totalRoutes,
    required this.saferRoutes,
    required this.regularRoutes,
    this.avgSafetyScore,
  });

  factory SavedRouteStats.fromJson(Map<String, dynamic> json) {
    return SavedRouteStats(
      totalRoutes: json['total_routes'] ?? 0,
      saferRoutes: json['safer_routes'] ?? 0,
      regularRoutes: json['regular_routes'] ?? 0,
      avgSafetyScore: json['avg_safety_score'] != null
          ? double.parse(json['avg_safety_score'].toString())
          : null,
    );
  }
}

class SavedRouteResponse {
  final bool success;
  final List<SavedRoute> data;
  final String? message;
  final PaginationInfo? pagination;

  SavedRouteResponse({
    required this.success,
    required this.data,
    this.message,
    this.pagination,
  });

  factory SavedRouteResponse.fromJson(Map<String, dynamic> json) {
    return SavedRouteResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? (json['data'] as List).map((e) => SavedRoute.fromJson(e)).toList()
          : [],
      message: json['message'],
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}