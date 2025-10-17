import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:video_gen_app/Config/api_config.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';

class PaymentService {
  static String get baseUrl => ApiConfig.baseUrl;
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Product IDs for both platforms (must match Play Console and App Store)
  static const Map<String, String> productIds = {
    'basic': 'basic_credits_500',
    'starter': 'starter_credits_1300',
    'pro': 'pro_credits_4000',
    'business': 'business_credits_9000',
  };

  // Initialize in-app purchase
  static Future<bool> initializeInAppPurchase() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        print('In-app purchases not available');
        return false;
      }
      return true;
    } catch (e) {
      print('Error initializing in-app purchase: $e');
      return false;
    }
  }

  // Get available products
  static Future<List<ProductDetails>> getAvailableProducts() async {
    try {
      final Set<String> ids = productIds.values.toSet();
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(ids);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      return response.productDetails;
    } catch (e) {
      print('Error getting available products: $e');
      return [];
    }
  }

  // Purchase a plan using in-app purchase
  static Future<bool> purchasePlan({
    required String planId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Initialize if needed
      final initialized = await initializeInAppPurchase();
      if (!initialized) {
        onError('In-app purchases not available');
        return false;
      }

      // Get product details
      final products = await getAvailableProducts();
      final productId = productIds[planId];

      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      // Create purchase param
      final purchaseParam = PurchaseParam(productDetails: product);

      // Start purchase
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (success) {
        // Listen for purchase updates
        _inAppPurchase.purchaseStream.listen(
          (purchaseDetailsList) async {
            for (final purchase in purchaseDetailsList) {
              await _handlePurchaseUpdate(purchase, planId, onSuccess, onError);
            }
          },
          onError: (error) {
            onError('Purchase failed: $error');
          },
        );
        return true;
      } else {
        onError('Failed to initiate purchase');
        return false;
      }
    } catch (e) {
      print('Error purchasing plan: $e');
      onError('Purchase error: $e');
      return false;
    }
  }

  // Handle purchase update
  static Future<void> _handlePurchaseUpdate(
    PurchaseDetails purchase,
    String planId,
    Function(String) onSuccess,
    Function(String) onError,
  ) async {
    try {
      if (purchase.status == PurchaseStatus.purchased) {
        // Verify purchase with backend and add credits
        final success = await _verifyAndAddCredits(purchase, planId);

        if (success) {
          onSuccess('Purchase successful! Credits added to your account.');
        } else {
          onError('Purchase verification failed');
        }

        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        onError('Purchase failed: ${purchase.error?.message}');
      } else if (purchase.status == PurchaseStatus.canceled) {
        onError('Purchase was canceled');
      }
    } catch (e) {
      print('Error handling purchase update: $e');
      onError('Error processing purchase: $e');
    }
  }

  // Verify purchase with backend and add credits
  static Future<bool> _verifyAndAddCredits(
    PurchaseDetails purchase,
    String planId,
  ) async {
    try {
      final planDetails = CreditSystemService.getPlanDetails(planId);
      if (planDetails == null) return false;

      final credits = planDetails['credits'] as int;

      // Add credits to user account
      return await CreditSystemService.addCredits(
        credits: credits,
        planId: planId,
        transactionId: purchase.purchaseID ?? '',
      );
    } catch (e) {
      print('Error verifying and adding credits: $e');
      return false;
    }
  }

  // Restore purchases (mainly for iOS)
  static Future<void> restorePurchases({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      await _inAppPurchase.restorePurchases();
      onSuccess('Purchases restored successfully');
    } catch (e) {
      print('Error restoring purchases: $e');
      onError('Failed to restore purchases: $e');
    }
  }

  // Create payment intent (fallback for web/other platforms)
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String planType,
    required int amount,
    required int credits,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/create-intent'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'planType': planType,
          'amount': amount,
          'credits': credits,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      rethrow;
    }
  }

  // Get payment history
  static Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['payments'] ?? []);
      } else {
        throw Exception('Failed to fetch payment history');
      }
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }
}
