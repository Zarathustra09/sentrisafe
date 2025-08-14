import '../constants.dart';


class Announcement {
  final int id;
  final int userId;
  final String title;
  final String description;
  final List<AnnouncementImage> images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  Announcement({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.images,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      images: (json['images'] as List? ?? [])
          .map((item) => AnnouncementImage.fromJson(item))
          .toList(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'images': images.map((img) => img.toJson()).toList(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}

class AnnouncementImage {
  final String id;
  final String path;
  final bool isFeatured;
  final int order;

  AnnouncementImage({
    required this.id,
    required this.path,
    required this.isFeatured,
    required this.order,
  });

  factory AnnouncementImage.fromJson(Map<String, dynamic> json) {
    return AnnouncementImage(
      id: json['id'],
      path: json['path'],
      isFeatured: json['is_featured'] ?? false,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'is_featured': isFeatured,
      'order': order,
    };
  }

  // Helper method to get full image URL using constants
  String get fullUrl => '$storageUrl/$path';
}

class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class AnnouncementResponse {
  final bool success;
  final AnnouncementData data;

  AnnouncementResponse({
    required this.success,
    required this.data,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      success: json['success'],
      data: AnnouncementData.fromJson(json['data']),
    );
  }
}

class AnnouncementData {
  final List<Announcement> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  AnnouncementData({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  factory AnnouncementData.fromJson(Map<String, dynamic> json) {
    return AnnouncementData(
      data: (json['data'] as List)
          .map((item) => Announcement.fromJson(item))
          .toList(),
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      total: json['total'],
      perPage: json['per_page'],
    );
  }
}