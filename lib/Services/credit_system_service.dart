import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:video_gen_app/Config/api_config.dart';

class CreditSystemService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Credit consumption rates
  static const int textToVideoCredits = 320; // 320 credits per text-to-video
  static const int avatarVideoCreditsPerMinute = 40; // 40 credits per minute

  // Plan configurations with internal cost structure (not shown to users)
  static const Map<String, Map<String, dynamic>> planConfigs = {
    'basic': {
      'credits': 500,
      'price': 9.99,
      'textToVideos': 1,
      'avatarVideos': 5,
      'internalCost': 5.55, // Internal cost - not shown to users
      'profitMargin': 80, // 80% profit margin - not shown to users
    },
    'starter': {
      'credits': 1300,
      'price': 24.99,
      'textToVideos': 3,
      'avatarVideos': 10,
      'internalCost': 14.30,
      'profitMargin': 75,
    },
    'pro': {
      'credits': 4000,
      'price': 69.99,
      'textToVideos': 10,
      'avatarVideos': 25,
      'internalCost': 43.75,
      'profitMargin': 60,
    },
    'business': {
      'credits': 9000,
      'price': 149.99,
      'textToVideos': 25,
      'avatarVideos': 50,
      'internalCost': 103.50,
      'profitMargin': 45,
    },
  };

  /// Get user's current credit balance
  static Future<int> getUserCredits() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/credits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['credits'] ?? 0;
      } else {
        throw Exception('Failed to fetch credits: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user credits: $e');
      return 0;
    }
  }

  /// Check if user has enough credits for a video generation
  static Future<bool> hasEnoughCredits({
    required String videoType,
    int? durationMinutes,
  }) async {
    try {
      final currentCredits = await getUserCredits();
      int requiredCredits = 0;

      if (videoType == 'text-to-video') {
        requiredCredits = textToVideoCredits;
      } else if (videoType == 'avatar-video') {
        requiredCredits = avatarVideoCreditsPerMinute * (durationMinutes ?? 1);
      }

      return currentCredits >= requiredCredits;
    } catch (e) {
      print('Error checking credits: $e');
      return false;
    }
  }

  /// Consume credits for video generation
  static Future<bool> consumeCredits({
    required String videoType,
    int? durationMinutes,
    required String projectId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      int creditsToConsume = 0;
      if (videoType == 'text-to-video') {
        creditsToConsume = textToVideoCredits;
      } else if (videoType == 'avatar-video') {
        creditsToConsume = avatarVideoCreditsPerMinute * (durationMinutes ?? 1);
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/consume-credits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'credits': creditsToConsume,
          'videoType': videoType,
          'durationMinutes': durationMinutes,
          'projectId': projectId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to consume credits: ${response.statusCode}');
      }
    } catch (e) {
      print('Error consuming credits: $e');
      return false;
    }
  }

  /// Add credits to user account (after successful purchase)
  static Future<bool> addCredits({
    required int credits,
    required String planId,
    required String transactionId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/add-credits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'credits': credits,
          'planId': planId,
          'transactionId': transactionId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to add credits: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding credits: $e');
      return false;
    }
  }

  /// Get user's credit history
  static Future<List<Map<String, dynamic>>> getCreditHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/credit-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      } else {
        throw Exception(
          'Failed to fetch credit history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching credit history: $e');
      return [];
    }
  }

  /// Calculate credits needed for a video
  static int calculateRequiredCredits({
    required String videoType,
    int? durationMinutes,
  }) {
    if (videoType == 'text-to-video') {
      return textToVideoCredits;
    } else if (videoType == 'avatar-video') {
      return avatarVideoCreditsPerMinute * (durationMinutes ?? 1);
    }
    return 0;
  }

  /// Get plan details by ID
  static Map<String, dynamic>? getPlanDetails(String planId) {
    return planConfigs[planId];
  }

  /// Get all available plans (without internal cost/profit data)
  static List<Map<String, dynamic>> getAvailablePlans() {
    return planConfigs.entries.map((entry) {
      final config = entry.value;
      return {
        'id': entry.key,
        'name': entry.key.toUpperCase(),
        'credits': config['credits'],
        'price': config['price'],
        'textToVideos': config['textToVideos'],
        'avatarVideos': config['avatarVideos'],
        // Note: Internal cost and profit margin are NOT included in public data
      };
    }).toList();
  }
}
