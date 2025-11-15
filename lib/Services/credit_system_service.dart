import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:video_gen_app/Config/api_config.dart';

class CreditSystemService {
  static String get baseUrl => ApiConfig.baseUrl;

  // NEW CREDIT SYSTEM: 1 credit = 1 minute of avatar video
  static const int textToVideoCredits = 320; // COMING SOON - Not currently used
  static const int avatarVideoCreditsPerMinute =
      1; // 1 credit per minute (rounded up)

  // NEW SUBSCRIPTION PLANS (Monthly - only one active at a time)
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'basic': {
      'name': 'Basic',
      'videos': 30,
      'price': 27.0,
      'priceDisplay': '\$27',
      'type': 'subscription',
      'billingPeriod': 'month',
      'description': '30 videos per month',
    },
    'starter': {
      'name': 'Starter',
      'videos': 60,
      'price': 47.0,
      'priceDisplay': '\$47',
      'type': 'subscription',
      'billingPeriod': 'month',
      'description': '60 videos per month',
      'popular': true,
    },
    'pro': {
      'name': 'Pro',
      'videos': 150,
      'price': 97.0,
      'priceDisplay': '\$97',
      'type': 'subscription',
      'billingPeriod': 'month',
      'description': '150 videos per month',
    },
  };

  // NEW IN-APP CREDIT TOP-UPS (Can be purchased anytime, even with active subscription)
  static const Map<String, Map<String, dynamic>> creditTopups = {
    'credits_10': {
      'name': '10 Credits',
      'credits': 10,
      'price': 10.0,
      'priceDisplay': '\$10',
      'type': 'topup',
      'description': '10 additional credits',
    },
    'credits_20': {
      'name': '20 Credits',
      'credits': 20,
      'price': 18.0,
      'priceDisplay': '\$18',
      'type': 'topup',
      'description': '20 additional credits',
      'savings': '\$2 off',
    },
    'credits_30': {
      'name': '30 Credits',
      'credits': 30,
      'price': 25.0,
      'priceDisplay': '\$25',
      'type': 'topup',
      'description': '30 additional credits',
      'savings': '\$5 off',
      'popular': true,
    },
  };

  // FACELESS LTD STRIPE WEBHOOK PLANS (Website payments)
  static const Map<String, Map<String, dynamic>> facelessLtdPlans = {
    'faceless_basic': {
      'name': 'Faceless Basic',
      'videos': 30,
      'price': 60.0,
      'stripeAmount': 6000, // in cents
      'type': 'faceless_ltd',
      'billingPeriod': 'month',
      'description': '30 videos per month via Faceless LTD',
    },
    'faceless_starter': {
      'name': 'Faceless Starter',
      'videos': 60,
      'price': 97.0,
      'stripeAmount': 9700, // in cents
      'type': 'faceless_ltd',
      'billingPeriod': 'month',
      'description': '60 videos per month via Faceless LTD',
    },
    'faceless_pro': {
      'name': 'Faceless Pro',
      'videos': 150,
      'price': 197.0,
      'stripeAmount': 19700, // in cents
      'type': 'faceless_ltd',
      'billingPeriod': 'month',
      'description': '150 videos per month via Faceless LTD',
    },
  };

  // LEGACY - Keeping for backward compatibility (will be removed later)
  static const Map<String, Map<String, dynamic>> planConfigs = {
    'basic': {
      'credits': 30,
      'price': 27.0,
      'textToVideos': 0, // Coming soon
      'avatarVideos': 30,
    },
    'starter': {
      'credits': 60,
      'price': 47.0,
      'textToVideos': 0, // Coming soon
      'avatarVideos': 60,
    },
    'pro': {
      'credits': 150,
      'price': 97.0,
      'textToVideos': 0, // Coming soon
      'avatarVideos': 150,
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

  /// Reserve credits for video generation (NEW FLOW)
  static Future<bool> reserveCredits({
    required String videoType,
    int? durationMinutes,
    required String projectId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      int creditsToReserve = 0;
      if (videoType == 'text-to-video') {
        creditsToReserve = textToVideoCredits;
      } else if (videoType == 'avatar-video') {
        creditsToReserve = avatarVideoCreditsPerMinute * (durationMinutes ?? 1);
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/reserve-credits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'credits': creditsToReserve,
          'videoType': videoType,
          'durationMinutes': durationMinutes,
          'projectId': projectId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('💰 Reserved ${creditsToReserve} credits for project $projectId');
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to reserve credits: ${response.statusCode}');
      }
    } catch (e) {
      print('Error reserving credits: $e');
      return false;
    }
  }

  /// Confirm credit usage after successful video generation
  static Future<bool> confirmCredits({required String projectId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/confirm-credits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'projectId': projectId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Confirmed credits usage for project $projectId');
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to confirm credits: ${response.statusCode}');
      }
    } catch (e) {
      print('Error confirming credits: $e');
      return false;
    }
  }

  /// Refund reserved credits if video generation fails
  static Future<bool> refundCredits({required String projectId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/refund-credits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'projectId': projectId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔄 Refunded credits for failed project $projectId');
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to refund credits: ${response.statusCode}');
      }
    } catch (e) {
      print('Error refunding credits: $e');
      return false;
    }
  }

  /// Legacy consume credits method (for backward compatibility)
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

  /// Calculate credits needed for a video (NEW SYSTEM)
  static int calculateRequiredCredits({
    required String videoType,
    int? durationMinutes,
    int? durationSeconds,
  }) {
    if (videoType == 'text-to-video') {
      // Coming soon - not currently active
      return textToVideoCredits;
    } else if (videoType == 'avatar-video') {
      // NEW SYSTEM: 1 credit = 1 minute (rounded up)
      // If duration is 1 minute 1 second, it costs 2 credits
      final minutes = durationMinutes ?? 0;
      final seconds = durationSeconds ?? 0;

      if (seconds > 0) {
        // Any seconds over the minute rounds up to next credit
        return minutes + 1;
      }
      return minutes > 0 ? minutes : 1; // Minimum 1 credit
    }
    return 0;
  }

  /// Get subscription plan details by ID
  static Map<String, dynamic>? getSubscriptionPlan(String planId) {
    return subscriptionPlans[planId];
  }

  /// Get credit topup details by ID
  static Map<String, dynamic>? getCreditTopup(String topupId) {
    return creditTopups[topupId];
  }

  /// Get Faceless LTD plan details by ID
  static Map<String, dynamic>? getFacelessLtdPlan(String planId) {
    return facelessLtdPlans[planId];
  }

  /// Get plan details by ID (Legacy support)
  static Map<String, dynamic>? getPlanDetails(String planId) {
    // First check subscriptions
    if (subscriptionPlans.containsKey(planId)) {
      return subscriptionPlans[planId];
    }
    // Then check topups
    if (creditTopups.containsKey(planId)) {
      return creditTopups[planId];
    }
    // Finally check faceless ltd
    if (facelessLtdPlans.containsKey(planId)) {
      return facelessLtdPlans[planId];
    }
    // Legacy fallback
    return planConfigs[planId];
  }

  /// Get all available subscription plans
  static List<Map<String, dynamic>> getAvailableSubscriptions() {
    return subscriptionPlans.entries.map((entry) {
      return {
        'id': entry.key,
        'name': entry.value['name'],
        'videos': entry.value['videos'],
        'price': entry.value['price'],
        'priceDisplay': entry.value['priceDisplay'],
        'description': entry.value['description'],
        'billingPeriod': entry.value['billingPeriod'],
        'popular': entry.value['popular'] ?? false,
        'type': 'subscription',
      };
    }).toList();
  }

  /// Get all available credit topups
  static List<Map<String, dynamic>> getAvailableCreditTopups() {
    return creditTopups.entries.map((entry) {
      return {
        'id': entry.key,
        'name': entry.value['name'],
        'credits': entry.value['credits'],
        'price': entry.value['price'],
        'priceDisplay': entry.value['priceDisplay'],
        'description': entry.value['description'],
        'savings': entry.value['savings'],
        'popular': entry.value['popular'] ?? false,
        'type': 'topup',
      };
    }).toList();
  }

  /// Get all available plans (Legacy support - now returns subscriptions)
  static List<Map<String, dynamic>> getAvailablePlans() {
    return getAvailableSubscriptions();
  }

  /// Determine Faceless LTD plan based on Stripe payment amount
  static Map<String, dynamic>? getFacelessPlanByAmount(int amountInCents) {
    for (var entry in facelessLtdPlans.entries) {
      if (entry.value['stripeAmount'] == amountInCents) {
        return {'id': entry.key, ...entry.value};
      }
    }
    return null;
  }
}
