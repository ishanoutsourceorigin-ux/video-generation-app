import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../Config/environment.dart';

class DashboardService {
  static String get baseUrl => Environment.apiUrl;

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
        // Get projects count (instead of videos)
        http.get(Uri.parse('$baseUrl/projects'), headers: headers),
        // Get completed projects count
        http.get(
          Uri.parse(
            '$baseUrl/projects',
          ).replace(queryParameters: {'status': 'completed'}),
          headers: headers,
        ),
        // Get user profile for credits data
        http.get(Uri.parse('$baseUrl/user/profile'), headers: headers),
        // Get payment history for total spent calculation
        http.get(
          Uri.parse('${Environment.baseUrl}/api/payments/history'),
          headers: headers,
        ),
      ]);

      final avatarsResponse = futures[0];
      final projectsResponse = futures[1];
      final completedProjectsResponse = futures[2];
      final userProfileResponse = futures[3];
      final paymentHistoryResponse = futures[4];

      Map<String, dynamic> stats = {
        'totalAvatars': 0,
        'totalProjects': 0,
        'completedProjects': 0,
        'availableCredits': 0,
        'totalTimeSaved': '0h',
        'creditsPurchased': 0,
        'creditsUsed': 0,
        'totalTransactions': 0,
        'userName': '',
        'userEmail': '',
        'userPlan': 'free',
        'isEmailVerified': false,
      };

      // Parse avatars response
      if (avatarsResponse.statusCode == 200) {
        final avatarsData = json.decode(avatarsResponse.body);
        stats['totalAvatars'] =
            avatarsData['total'] ?? avatarsData['avatars']?.length ?? 0;
      }

      // Parse projects response (instead of videos)
      if (projectsResponse.statusCode == 200) {
        final projectsData = json.decode(projectsResponse.body);
        stats['totalProjects'] =
            projectsData['total'] ?? projectsData['projects']?.length ?? 0;
      }

      // Parse completed projects response
      if (completedProjectsResponse.statusCode == 200) {
        final completedData = json.decode(completedProjectsResponse.body);
        stats['completedProjects'] =
            completedData['total'] ?? completedData['projects']?.length ?? 0;
      }

      // Parse user profile response for credits data
      if (userProfileResponse.statusCode == 200) {
        final userData = json.decode(userProfileResponse.body);
        final user = userData['user'] ?? {};

        stats['availableCredits'] =
            user['availableCredits'] ?? user['credits'] ?? 0;
        stats['creditsPurchased'] = user['totalPurchased'] ?? 0;

        // Use totalUsed from backend if available, otherwise calculate
        if (user['totalUsed'] != null && user['totalUsed'] > 0) {
          stats['creditsUsed'] = user['totalUsed'];
        } else {
          // Fallback calculation for backward compatibility
          final purchased = user['totalPurchased'] ?? 0;
          final available = user['availableCredits'] ?? user['credits'] ?? 0;
          stats['creditsUsed'] = purchased - available;
        }

        // Get totalSpent from user profile as fallback
        final userTotalSpent = user['totalSpent'];
        if (userTotalSpent != null) {
          stats['totalSpent'] = userTotalSpent is int
              ? userTotalSpent.toDouble()
              : (userTotalSpent as double);
        }

        // Additional user info for dashboard
        stats['userName'] = user['name'] ?? '';
        stats['userEmail'] = user['email'] ?? '';
        stats['userPlan'] = user['plan'] ?? 'free';
        stats['isEmailVerified'] = user['isEmailVerified'] ?? false;
      }

      // Parse payment history response for transaction data
      if (paymentHistoryResponse.statusCode == 200) {
        final paymentData = json.decode(paymentHistoryResponse.body);

        // Backend returns 'payments' field, not 'transactions'
        final transactions = paymentData['payments'] as List? ?? [];

        // Calculate total transactions count
        stats['totalTransactions'] = transactions.length;

        // Always calculate total spent from payment history transactions
        double totalSpent = 0.0;

        for (int i = 0; i < transactions.length; i++) {
          final transaction = transactions[i];

          // Include all successful purchase transactions - be more lenient with status
          final status = transaction['status']?.toString().toLowerCase() ?? '';
          if (status == 'completed' ||
              status == 'success' ||
              status == 'succeeded') {
            final amount = transaction['amount'];
            if (amount != null) {
              // Handle both int and double amounts
              final amountValue = amount is int
                  ? amount.toDouble()
                  : (amount as double);
              totalSpent += amountValue;
            }
          }
        }
        // Override user profile totalSpent if we calculated from payment history
        if (totalSpent > 0) {
          stats['totalSpent'] = totalSpent;
        }
      } else {
        stats['totalTransactions'] = 0;
        stats['totalSpent'] = 0.0;
      }

      // Calculate total time saved
      final timeSaved = await calculateTimeSaved();
      stats['totalTimeSaved'] = timeSaved;

      return stats;
    } catch (e) {
      // Return default values on error
      return {
        'totalAvatars': 0,
        'totalProjects': 0,
        'completedProjects': 0,
        'availableCredits': 0,
        'totalTimeSaved': '0h',
        'creditsPurchased': 0,
        'creditsUsed': 0,
        'totalTransactions': 0,
        'userName': '',
        'userEmail': '',
        'userPlan': 'free',
        'isEmailVerified': false,
      };
    }
  }

  // Get recent projects for dashboard
  static Future<List<Map<String, dynamic>>> getRecentProjects({
    int limit = 4,
  }) async {
    try {
      // print(
      //   '🏠 Dashboard loading recent projects - Both text-based and avatar videos',
      // );
      final headers = await _getHeaders();

      // Use projects API instead of videos API
      final uri = Uri.parse('$baseUrl/projects').replace(
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
        final projects = data['projects'] as List? ?? [];
        // print('🎯 Dashboard loaded ${projects.length} recent projects');

        return projects.map<Map<String, dynamic>>((project) {
          return {
            'id': project['_id'] ?? '',
            'title': project['title'] ?? 'Untitled',
            'status': project['status'] ?? 'unknown',
            'createdAt': project['createdAt'] ?? '',
            'type': project['type'] ?? 'unknown', // text-based or avatar-based
            'duration':
                project['configuration']?['duration']?.toString() ?? '0',
            'videoUrl': project['videoUrl'] ?? '',
            'thumbnailUrl': project['thumbnailUrl'] ?? '',
            'description': project['description'] ?? '',
            'aspectRatio': project['configuration']?['aspectRatio'] ?? '9:16',
            'resolution':
                project['configuration']?['resolution']?.toString() ?? '1080',
            'avatarId': project['avatarId'] ?? {},
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
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
        return [];
      }
    } catch (e) {
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

  // Calculate total time saved based on completed projects
  static Future<String> calculateTimeSaved() async {
    try {
      // Get completed projects to calculate time saved
      final completedProjects = await _getCompletedProjectsWithDetails();

      double totalTimeSavedHours = 0.0;

      for (final project in completedProjects) {
        // Get video duration in seconds
        final durationStr = project['duration']?.toString() ?? '0';
        final videoSeconds = int.tryParse(durationStr) ?? 0;
        final videoMinutes = videoSeconds / 60.0;

        // Calculate time saved based on project type
        double timeSavedForProject = 0.0;

        if (project['type'] == 'text-based') {
          // Text-based video generation
          // Manual editing: ~3 hours per minute of video (includes scripting, editing, rendering)
          // Our app: ~8-10 minutes (AI generation time)
          final manualTime = videoMinutes * 3.0; // 3 hours per minute
          final ourAppTime = 10.0 / 60.0; // 10 minutes in hours
          timeSavedForProject = manualTime - ourAppTime;
        } else if (project['type'] == 'avatar-based') {
          // Avatar video generation
          // Manual editing: ~2 hours per minute (recording, editing, post-production)
          // Our app: ~5-8 minutes (avatar + voice generation)
          final manualTime = videoMinutes * 2.0; // 2 hours per minute
          final ourAppTime = 6.0 / 60.0; // 6 minutes in hours
          timeSavedForProject = manualTime - ourAppTime;
        }

        // Ensure we don't have negative time saved
        if (timeSavedForProject > 0) {
          totalTimeSavedHours += timeSavedForProject;
        }
      }

      // Format the time saved for display
      return _formatTimeSaved(totalTimeSavedHours);
    } catch (e) {
      print('Error calculating time saved: $e');
      return "0h";
    }
  }

  // Get completed projects with details for time calculation
  static Future<List<Map<String, dynamic>>>
  _getCompletedProjectsWithDetails() async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/projects').replace(
        queryParameters: {
          'status': 'completed',
          'limit': '100', // Get all completed projects
          'page': '1',
        },
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final projects = data['projects'] as List? ?? [];

        return projects.map<Map<String, dynamic>>((project) {
          return {
            'type': project['type'] ?? 'text-based',
            'duration':
                project['configuration']?['duration']?.toString() ??
                '8', // Default 8 seconds
            'createdAt': project['createdAt'] ?? '',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching completed projects: $e');
      return [];
    }
  }

  // Format time saved in a user-friendly way
  static String _formatTimeSaved(double totalHours) {
    if (totalHours < 1) {
      final minutes = (totalHours * 60).round();
      return "${minutes}m";
    } else if (totalHours < 24) {
      final hours = totalHours.floor();
      final minutes = ((totalHours - hours) * 60).round();
      if (minutes == 0) {
        return "${hours}h";
      } else {
        return "${hours}h ${minutes}m";
      }
    } else {
      final days = (totalHours / 24).floor();
      final remainingHours = (totalHours % 24).floor();
      if (remainingHours == 0) {
        return "${days}d";
      } else {
        return "${days}d ${remainingHours}h";
      }
    }
  }
}
