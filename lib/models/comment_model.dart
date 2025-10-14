class Comment {
  final int id;
  final int announcementId; // Foreign key reference to announcement
  final int userId;
  final int? parentId; // For nested comments (null = top-level)
  final String content;
  final bool isDeleted; // Show "[deleted]" if true
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final List<Comment> replies; // Nested replies

  Comment({
    required this.id,
    required this.announcementId,
    required this.userId,
    this.parentId,
    required this.content,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      announcementId: json['announcement_id'],
      userId: json['user_id'],
      parentId: json['parent_id'],
      content: json['content'] ?? '',
      isDeleted: json['is_deleted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((reply) => Comment.fromJson(reply))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'announcement_id': announcementId,
      'user_id': userId,
      'parent_id': parentId,
      'content': content,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  // Helper to check if this is a top-level comment
  bool get isTopLevel => parentId == null;

  // Helper to display content (show deleted message if deleted)
  String get displayContent =>
      isDeleted ? 'This comment was deleted by the user' : content;
}

class User {
  final int id;
  final String name;
  final String email;
  final String? profilePicture;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
    };
  }
}

class CommentResponse {
  final bool success;
  final String? message;
  final List<Comment> comments;
  final Map<String, dynamic>? pagination;

  CommentResponse({
    required this.success,
    this.message,
    required this.comments,
    this.pagination,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      success: json['success'] ?? true,
      message: json['message'],
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((item) => Comment.fromJson(item))
              .toList()
          : [],
      pagination: json['pagination'],
    );
  }
}

class SingleCommentResponse {
  final bool success;
  final Comment? comment;
  final String? message;

  SingleCommentResponse({
    required this.success,
    this.comment,
    this.message,
  });

  factory SingleCommentResponse.fromJson(Map<String, dynamic> json) {
    return SingleCommentResponse(
      success: json['success'],
      comment: json['comment'] != null
          ? Comment.fromJson(json['comment'])
          : json['data'] != null
              ? Comment.fromJson(json['data'])
              : null,
      message: json['message'],
    );
  }
}
