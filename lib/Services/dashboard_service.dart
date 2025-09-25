import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class DashboardService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Get auth headers with Firebase token
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'Content-Type': 'application/json'};
      }

      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      return {'Content-Type': 'application/json'};
    }
  }

  // Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();

      // Fetch all data in parallel
      final futures = await Future.wait([
        // Get avatars count
        http.get(Uri.parse('$baseUrl/avatars'), headers: headers),
        // Get videos count
        http.get(Uri.parse('$baseUrl/videos'), headers: headers),
        // Get completed videos count
        http.get(
          Uri.parse(
            '$baseUrl/videos',
          ).replace(queryParameters: {'status': 'completed'}),
          headers: headers,
        ),
      ]);

      final avatarsResponse = futures[0];
      final videosResponse = futures[1];
      final completedVideosResponse = futures[2];

      Map<String, dynamic> stats = {
        'totalAvatars': 0,
        'totalProjects': 0,
        'completedProjects': 0,
        'availableCredits': 5, // Default credits for demo
        'totalSpent': 85, // Mock data for now
      };

      // Parse avatars response
      if (avatarsResponse.statusCode == 200) {
        final avatarsData = json.decode(avatarsResponse.body);
        stats['totalAvatars'] =
            avatarsData['total'] ?? avatarsData['avatars']?.length ?? 0;
      }

      // Parse videos response
      if (videosResponse.statusCode == 200) {
        final videosData = json.decode(videosResponse.body);
        stats['totalProjects'] =
            videosData['total'] ?? videosData['videos']?.length ?? 0;
      }

      // Parse completed videos response
      if (completedVideosResponse.statusCode == 200) {
        final completedData = json.decode(completedVideosResponse.body);
        stats['completedProjects'] =
            completedData['total'] ?? completedData['videos']?.length ?? 0;
      }

      return stats;
    } catch (e) {
      print('Dashboard stats error: $e');
      // Return default values on error
      return {
        'totalAvatars': 0,
        'totalProjects': 0,
        'completedProjects': 0,
        'availableCredits': 5,
        'totalSpent': 85,
      };
    }
  }

  // Get recent projects (videos) for dashboard
  static Future<List<Map<String, dynamic>>> getRecentProjects({
    int limit = 4,
  }) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/videos').replace(
        queryParameters: {
          'limit': limit.toString(),
          'page': '1',
          'sort': 'createdAt',
          'order': 'desc',
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = data['videos'] as List? ?? [];

        return videos.map<Map<String, dynamic>>((video) {
          return {
            'id': video['_id'] ?? '',
            'title': video['title'] ?? 'Untitled',
            'status': video['status'] ?? 'unknown',
            'createdAt': video['createdAt'] ?? '',
            'duration': video['duration']?.toString() ?? '0:00',
            'videoUrl': video['videoUrl'] ?? '',
            'thumbnailUrl': video['thumbnailUrl'] ?? 'images/project-card.png',
            'avatarId': video['avatarId'] ?? {},
            'metadata': video['metadata'] ?? {},
          };
        }).toList();
      } else {
        print('Failed to fetch projects: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Recent projects error: $e');
      return [];
    }
  }

  // Get user's avatars for dashboard
  static Future<List<Map<String, dynamic>>> getUserAvatars({
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/avatars').replace(
        queryParameters: {
          'limit': limit.toString(),
          'page': '1',
          'sort': 'createdAt',
          'order': 'desc',
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final avatars = data['avatars'] as List? ?? [];

        return avatars.map<Map<String, dynamic>>((avatar) {
          return {
            'id': avatar['_id'] ?? '',
            'name': avatar['name'] ?? 'Unnamed',
            'profession': avatar['profession'] ?? '',
            'status': avatar['status'] ?? 'unknown',
            'imageUrl': avatar['imageUrl'] ?? '',
            'createdAt': avatar['createdAt'] ?? '',
            'gender': avatar['gender'] ?? '',
            'style': avatar['style'] ?? '',
          };
        }).toList();
      } else {
        print('Failed to fetch avatars: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('User avatars error: $e');
      return [];
    }
  }

  // Format date for display
  static String formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return 'Unknown';

      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // Format duration
  static String formatDuration(String? durationString) {
    try {
      if (durationString == null || durationString.isEmpty) return '0:00';

      // If it's already formatted (contains ':'), return as is
      if (durationString.contains(':')) {
        return durationString;
      }

      // If it's seconds, convert to MM:SS
      final seconds = int.tryParse(durationString) ?? 0;
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;

      return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '0:00';
    }
  }
}
