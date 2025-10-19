import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sentrisafe/constants.dart';
import 'package:sentrisafe/models/comment_model.dart';
import 'package:sentrisafe/services/auth/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CommentService {
  static Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get comments for a specific announcement
  /// announcementId: The ID of the announcement (foreign key)
  static Future<Map<String, dynamic>> getComments({
    required int announcementId,
    int page = 1,
  }) async {
    if (!await _isConnected()) {
      return {'success': false, 'error': 'No internet connection'};
    }
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$announcementId/comments?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Comments response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('Parsed data: $data');

          // Handle different response formats
          List<Comment> comments = [];
          Map<String, dynamic>? pagination;

          if (data['comments'] != null) {
            // Direct format: {success, comments, pagination}
            comments = (data['comments'] as List)
                .map((item) => Comment.fromJson(item))
                .toList();
            pagination = data['pagination'];
          } else if (data['data'] != null) {
            // Nested format: {success, data: {data, pagination}}
            if (data['data'] is List) {
              comments = (data['data'] as List)
                  .map((item) => Comment.fromJson(item))
                  .toList();
            } else if (data['data']['data'] != null) {
              comments = (data['data']['data'] as List)
                  .map((item) => Comment.fromJson(item))
                  .toList();
              pagination = {
                'current_page': data['data']['current_page'],
                'last_page': data['data']['last_page'],
                'total': data['data']['total'],
                'per_page': data['data']['per_page'],
              };
            }
          }

          print('Parsed ${comments.length} comments');

          return {
            'success': true,
            'comments': comments,
            'pagination': pagination ??
                {
                  'current_page': 1,
                  'last_page': 1,
                  'total': comments.length,
                  'per_page': comments.length,
                }
          };
        } catch (parseError) {
          print('Parse error: $parseError');
          return {
            'success': false,
            'error': 'Failed to parse comments: ${parseError.toString()}'
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to fetch comments'
        };
      }
    } catch (e) {
      if (e is SocketException) {
        return {'success': false, 'error': 'No internet connection'};
      }
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Add a comment to an announcement
  /// announcementId: The ID of the announcement (foreign key)
  /// content: The comment text
  static Future<Map<String, dynamic>> addComment({
    required int announcementId,
    required String content,
    int? parentId, // Optional parent ID for replies
  }) async {
    if (!await _isConnected()) {
      return {'success': false, 'error': 'No internet connection'};
    }
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final requestBody = {
        'content': content,
        'parent_id':
            parentId, // Always include parent_id (null for top-level comments)
      };

      final response = await http.post(
        Uri.parse('$baseUrl/announcements/$announcementId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Add comment response: ${response.body}');
      print('Add comment status code: ${response.statusCode}');
      print('Request body was: ${jsonEncode(requestBody)}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('Parsed add comment data: $data');
          print('Data keys: ${data.keys}');
          print('Has comment key: ${data.containsKey('comment')}');
          print('Has data key: ${data.containsKey('data')}');
          print('Has success key: ${data.containsKey('success')}');
          print('Success value: ${data['success']}');

          // Check if the API response itself indicates failure
          if (data['success'] == false) {
            print('API returned success=false in response body!');
            return {
              'success': false,
              'error':
                  data['message'] ?? data['error'] ?? 'Failed to add comment',
            };
          }

          // Handle different response formats
          Comment? comment;
          String? message = data['message'];

          if (data['comment'] != null) {
            print('Parsing from data[comment]');
            comment = Comment.fromJson(data['comment']);
          } else if (data['data'] != null) {
            print('Parsing from data[data]');
            comment = Comment.fromJson(data['data']);
          } else {
            print('WARNING: No comment found in response! Full data: $data');
          }

          // Always return success for 200/201 status codes
          // The comment was added successfully even if we can't parse the response
          return {
            'success': true,
            if (comment != null) 'comment': comment,
            'message': message ?? 'Comment added successfully',
          };
        } catch (parseError, stackTrace) {
          print('Parse error in addComment: $parseError');
          print('Stack trace: $stackTrace');
          // Comment might have been added successfully but we can't parse response
          return {
            'success': true,
            'message': 'Comment added successfully',
          };
        }
      } else {
        print('Failed status code: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to add comment'
        };
      }
    } catch (e) {
      print('Exception in addComment: $e');
      if (e is SocketException) {
        return {'success': false, 'error': 'No internet connection'};
      }
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Update an existing comment
  /// commentId: The ID of the comment to update
  /// content: The new comment text
  static Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required String content,
  }) async {
    if (!await _isConnected()) {
      return {'success': false, 'error': 'No internet connection'};
    }
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      );

      print('Update comment response: ${response.body}');
      print('Update comment status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('Parsed update comment data: $data');

          // Handle different response formats
          Comment? comment;
          String? message;

          if (data['comment'] != null) {
            comment = Comment.fromJson(data['comment']);
            message = data['message'];
          } else if (data['data'] != null) {
            comment = Comment.fromJson(data['data']);
            message = data['message'];
          }

          if (comment != null) {
            return {
              'success': true,
              'comment': comment,
              'message': message ?? 'Comment updated successfully',
            };
          } else {
            return {
              'success': true,
              'message': 'Comment updated successfully',
            };
          }
        } catch (parseError) {
          print('Parse error in updateComment: $parseError');
          return {
            'success': true,
            'message': 'Comment updated successfully',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to update comment'
        };
      }
    } catch (e) {
      if (e is SocketException) {
        return {'success': false, 'error': 'No internet connection'};
      }
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Delete a comment
  /// commentId: The ID of the comment to delete
  static Future<Map<String, dynamic>> deleteComment({
    required int commentId,
  }) async {
    if (!await _isConnected()) {
      return {'success': false, 'error': 'No internet connection'};
    }
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Delete comment response: ${response.body}');
      print('Delete comment status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Comment deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to delete comment'
        };
      }
    } catch (e) {
      if (e is SocketException) {
        return {'success': false, 'error': 'No internet connection'};
      }
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get a single comment by ID
  /// announcementId: The ID of the announcement (foreign key)
  /// commentId: The ID of the comment to retrieve
  static Future<Map<String, dynamic>> getCommentById({
    required int announcementId,
    required int commentId,
  }) async {
    if (!await _isConnected()) {
      return {'success': false, 'error': 'No internet connection'};
    }
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$announcementId/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Get comment response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final comment = Comment.fromJson(data['data']);

        return {
          'success': true,
          'comment': comment,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to fetch comment'
        };
      }
    } catch (e) {
      if (e is SocketException) {
        return {'success': false, 'error': 'No internet connection'};
      }
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
