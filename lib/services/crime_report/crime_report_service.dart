import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../constants.dart';
import '../../models/crime_report_model.dart';
import '../auth/auth_service.dart';

class CrimeReportService {
  static Future<Map<String, dynamic>> submitReport({
    required String title,
    required String description,
    required String severity,
    required double latitude,
    required double longitude,
    String? address,
    required DateTime incidentDate,
    File? reportImage,
  }) async {
    try {
      print('=== CRIME REPORT SUBMISSION START ===');

      // Get auth data
      final token = await AuthService.getAuthToken();
      final userId = await AuthService.getUserId();

      print('Token: ${token != null ? "Found" : "Not found"}');
      print('User ID: $userId (Type: ${userId.runtimeType})');

      if (token == null) {
        print('ERROR: No authentication token found');
        return {'success': false, 'error': 'Authentication required'};
      }

      var uri = Uri.parse('$baseUrl/crime-reports');
      var request = http.MultipartRequest('POST', uri);

      print('API URL: $uri');

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      print('Headers added: Authorization and Accept');

      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['severity'] = severity;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['incident_date'] = incidentDate.toIso8601String().split('T')[0];

      print('Form fields added:');
      print('- title: $title');
      print('- description: $description');
      print('- severity: $severity');
      print('- latitude: ${latitude.toString()}');
      print('- longitude: ${longitude.toString()}');
      print('- incident_date: ${incidentDate.toIso8601String().split('T')[0]}');

      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
        print('- address: $address');
      } else {
        print('- address: not provided');
      }

      // Use the saved user_id
      if (userId != null) {
        request.fields['reported_by'] = userId.toString();
        print('- reported_by: ${userId.toString()} (converted from ${userId.runtimeType})');
      } else {
        print('WARNING: No user ID found');
      }

      // Add image file if provided
      if (reportImage != null) {
        String fileExtension = reportImage.path.split('.').last.toLowerCase();
        String mimeType = fileExtension == 'png' ? 'png' : 'jpeg';
        print('Image file: ${reportImage.path} (Type: $mimeType)');

        request.files.add(
          await http.MultipartFile.fromPath(
            'report_image',
            reportImage.path,
            contentType: MediaType('image', mimeType),
          ),
        );
        print('Image file added to request');
      } else {
        print('No image file provided');
      }

      print('Sending request to server...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      print('Decoded response data: $data');
      print('Data type: ${data.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('SUCCESS: Report submission successful');

        try {
          print('Attempting to create CrimeReport from JSON...');
          print('Raw data for CrimeReport.fromJson: $data');

          final crimeReport = CrimeReport.fromJson(data);
          print('CrimeReport created successfully');

          return {
            'success': true,
            'report': crimeReport,
            'message': 'Report submitted successfully'
          };
        } catch (e) {
          print('ERROR creating CrimeReport from JSON: $e');
          print('Error type: ${e.runtimeType}');

          return {
            'success': true,
            'message': 'Report submitted successfully (parsing error: $e)'
          };
        }
      } else {
        print('ERROR: Server returned error status');
        print('Error data: ${data['errors']}');

        return {
          'success': false,
          'errors': data['errors'] ?? {'general': 'Failed to submit report'},
        };
      }
    } catch (e) {
      print('EXCEPTION in submitReport: $e');
      print('Exception type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

      return {
        'success': false,
        'errors': {'general': 'Network error: ${e.toString()}'},
      };
    } finally {
      print('=== CRIME REPORT SUBMISSION END ===');
    }
  }

  static Future<Map<String, dynamic>> getReports() async {
    try {
      print('=== GET REPORTS START ===');

      final token = await AuthService.getAuthToken();
      print('Token for getReports: ${token != null ? "Found" : "Not found"}');

      if (token == null) {
        print('ERROR: No authentication token for getReports');
        return {'success': false, 'error': 'Authentication required'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/crime-reports'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Get reports status code: ${response.statusCode}');
      print('Get reports response: ${response.body}');

      final data = jsonDecode(response.body);
      print('Get reports decoded data: $data');

      if (response.statusCode == 200) {
        try {
          List<CrimeReport> reports = (data['data'] as List)
              .map((report) {
                print('Processing report data: $report');
                return CrimeReport.fromJson(report);
              })
              .toList();

          print('Successfully parsed ${reports.length} reports');
          return {'success': true, 'reports': reports};
        } catch (e) {
          print('ERROR parsing reports list: $e');
          return {'success': false, 'error': 'Error parsing reports: $e'};
        }
      } else {
        print('ERROR: Get reports failed with status ${response.statusCode}');
        return {'success': false, 'error': data['error'] ?? 'Failed to load reports'};
      }
    } catch (e) {
      print('EXCEPTION in getReports: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    } finally {
      print('=== GET REPORTS END ===');
    }
  }

  static Future<Map<String, dynamic>> getMyReports({
    String? severity,
    String? status,
    int page = 1,
  }) async {
    try {
      print('=== GET MY REPORTS START ===');

      final token = await AuthService.getAuthToken();
      if (token == null) {
        print('ERROR: No authentication token for getMyReports');
        return {'success': false, 'error': 'Authentication required'};
      }

      // Build query parameters
      final queryParams = <String, String>{'page': page.toString()};
      if (severity != null && severity.isNotEmpty) {
        queryParams['severity'] = severity;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/my-reports')
          .replace(queryParameters: queryParams);

      print('My reports URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('My reports status code: ${response.statusCode}');
      print('My reports response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        try {
          // Handle paginated response structure - work with raw data
          final reportsData = data['data']['data'] as List;

          // Don't convert to CrimeReport objects, just cast to Map
          List<Map<String, dynamic>> reports = reportsData
              .map<Map<String, dynamic>>((report) {
                print('Processing my report data: $report');
                return Map<String, dynamic>.from(report);
              })
              .toList();

          print('Successfully parsed ${reports.length} my reports');

          return {
            'success': true,
            'data': {
              'reports': reports,
              'pagination': {
                'current_page': data['data']['current_page'],
                'last_page': data['data']['last_page'],
                'total': data['data']['total'],
                'per_page': data['data']['per_page'],
                'from': data['data']['from'],
                'to': data['data']['to'],
              }
            }
          };
        } catch (e) {
          print('ERROR parsing my reports list: $e');
          return {'success': false, 'error': 'Error parsing my reports: $e'};
        }
      } else if (response.statusCode == 404) {
        // Handle 404 specifically - endpoint not found or no reports
        print('ERROR: My reports endpoint not found (404)');

        return {
          'success': true,
          'data': {
            'reports': <Map<String, dynamic>>[],
            'pagination': {
              'current_page': 1,
              'last_page': 1,
              'total': 0,
              'per_page': 10,
              'from': null,
              'to': null,
            }
          }
        };
      } else {
        print('ERROR: Get my reports failed with status ${response.statusCode}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to load your reports',
        };
      }
    } catch (e) {
      print('EXCEPTION in getMyReports: $e');
      return {
        'success': false,
        'error': 'Unable to connect to server. Please check your internet connection.',
      };
    } finally {
      print('=== GET MY REPORTS END ===');
    }
  }

  // Add these methods to your CrimeReportService class
  static Future<Map<String, dynamic>> getReportsWithFilters({
    String? severity,
    String? status,
    double? lat,
    double? lng,
    double? radius,
    int page = 1,
  }) async {
    try {
      print('=== GET REPORTS WITH FILTERS START ===');

      final token = await AuthService.getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required'};
      }

      // Build query parameters
      Map<String, String> queryParams = {'page': page.toString()};

      if (severity != null) queryParams['severity'] = severity;
      if (status != null) queryParams['status'] = status;
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();
      if (radius != null) queryParams['radius'] = radius.toString();

      final uri = Uri.parse('$baseUrl/crime-reports').replace(queryParameters: queryParams);
      print('Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        try {
          List<CrimeReport> reports = (data['data'] as List)
              .map((report) => CrimeReport.fromJson(report))
              .toList();

          return {
            'success': true,
            'reports': reports,
            'pagination': {
              'current_page': data['current_page'],
              'last_page': data['last_page'],
              'total': data['total'],
            }
          };
        } catch (e) {
          print('ERROR parsing reports: $e');
          return {'success': false, 'error': 'Error parsing reports: $e'};
        }
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to load reports'};
      }
    } catch (e) {
      print('EXCEPTION in getReportsWithFilters: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    } finally {
      print('=== GET REPORTS WITH FILTERS END ===');
    }
  }
}