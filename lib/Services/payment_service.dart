import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:video_gen_app/Config/api_config.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';
import 'package:video_gen_app/Services/user_sync_service.dart';

class PaymentService {
  static String get baseUrl => ApiConfig.baseUrl;
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static Map<String, dynamic>? _currentPurchaseCallbacks;

  // NEW PRODUCT IDS - Subscriptions (must match Play Console and App Store)
  static const Map<String, String> subscriptionProductIds = {
    'basic': 'subbasic_30videos_27', // 30 videos/month - $27
    'starter': 'substarter_60videos_47', // 60 videos/month - $47
    'pro': 'subpro_150videos_97', // 150 videos/month - $97
  };

  // NEW PRODUCT IDS - Credit Topups (must match Play Console and App Store)
  static const Map<String, String> topupProductIds = {
    'credits_10': 'topup_10credits_10', // 10 credits - $10
    'credits_20': 'topup_20credits_18', // 20 credits - $18
    'credits_30': 'topup_30credits_25', // 30 credits - $25
  };

  // Combined product IDs for easy lookup
  static Map<String, String> get productIds => {
    ...subscriptionProductIds,
    ...topupProductIds,
  };

  // Initialize in-app purchase
  static Future<bool> initializeInAppPurchase() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        print('In-app purchases not available');
        return false;
      }

      // Handle any pending purchases
      await _handlePendingPurchases();

      // Clear any stuck purchases
      await _clearStuckPurchases();

      return true;
    } catch (e) {
      print('Error initializing in-app purchase: $e');
      return false;
    }
  }

  // Clear any stuck purchases that might prevent new purchases
  static Future<void> _clearStuckPurchases() async {
    try {
      print('🧹 Clearing any stuck purchases...');

      // Get past purchases and complete any that are stuck
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;

      // Listen briefly to handle any immediate purchases
      StreamSubscription<List<PurchaseDetails>>? tempSubscription;

      tempSubscription = purchaseUpdated.listen(
        (List<PurchaseDetails> purchaseDetailsList) async {
          for (final PurchaseDetails purchase in purchaseDetailsList) {
            if (purchase.pendingCompletePurchase) {
              print('🔧 Completing stuck purchase: ${purchase.productID}');
              await _inAppPurchase.completePurchase(purchase);
            }
          }
          tempSubscription?.cancel();
        },
        onError: (error) {
          print('❌ Error clearing stuck purchases: $error');
          tempSubscription?.cancel();
        },
      );

      // Cancel after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        tempSubscription?.cancel();
      });
    } catch (e) {
      print('💥 Error clearing stuck purchases: $e');
    }
  }

  // Enhanced purchase recovery system
  static Future<void> _handlePendingPurchases() async {
    try {
      print('🔄 Checking for pending purchases...');

      // Get current pending purchases
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;

      // Listen to purchase stream temporarily to catch any pending purchases
      StreamSubscription<List<PurchaseDetails>>? tempSubscription;

      tempSubscription = purchaseUpdated.listen(
        (List<PurchaseDetails> purchaseDetailsList) async {
          print('📦 Found ${purchaseDetailsList.length} purchase(s) in stream');

          for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
            print(
              '🎫 Processing purchase: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}',
            );

            if (purchaseDetails.status == PurchaseStatus.pending) {
              print('⏳ Found pending purchase: ${purchaseDetails.productID}');
              // Handle pending purchase
              await _handlePurchaseUpdate(
                purchaseDetails,
                _getPlanIdFromProductId(purchaseDetails.productID),
                (message) => print('✅ Pending purchase success: $message'),
                (error) => print('❌ Pending purchase error: $error'),
              );
            } else if (purchaseDetails.status == PurchaseStatus.purchased) {
              print(
                '✅ Found completed purchase that needs verification: ${purchaseDetails.productID}',
              );
              // Verify and complete this purchase
              await _verifyAndCompletePurchase(
                purchaseDetails,
                (error) => print('❌ Purchase completion error: $error'),
              );
            } else if (purchaseDetails.status == PurchaseStatus.error) {
              print('❌ Found failed purchase: ${purchaseDetails.productID}');
              // Complete the failed purchase to clean up
              await _inAppPurchase.completePurchase(purchaseDetails);
            }
          }

          // Cancel temporary subscription after first batch
          tempSubscription?.cancel();
        },
        onError: (error) {
          print('❌ Error in pending purchase check: $error');
          tempSubscription?.cancel();
        },
      );

      // Also restore purchases from the store
      await _inAppPurchase.restorePurchases();
      print('🔄 Purchase restoration completed');

      // Cancel temp subscription after a reasonable timeout
      Future.delayed(Duration(seconds: 5), () {
        tempSubscription?.cancel();
      });
    } catch (e) {
      print('💥 Error handling pending purchases: $e');
    }
  }

  // Comprehensive purchase recovery for app restart scenarios
  static Future<void> recoverPurchases() async {
    try {
      print('🚑 Starting purchase recovery...');

      // Check if IAP is available
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        print('❌ IAP not available for recovery');
        return;
      }

      // Get past purchases from the store
      await _inAppPurchase.restorePurchases();

      // Wait a bit for any pending purchases to come through
      await Future.delayed(Duration(seconds: 3));

      print('✅ Purchase recovery completed');
    } catch (e) {
      print('💥 Error during purchase recovery: $e');
    }
  }

  // Verify and complete a purchase (used for recovery)
  static Future<void> _verifyAndCompletePurchase(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    try {
      print('🔍 Verifying recovered purchase: ${purchaseDetails.productID}');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        onError('User not authenticated');
        return;
      }

      // Get user token
      final token = await user.getIdToken();

      // Verify with backend
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/payments/verify-purchase'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'purchaseToken':
                  purchaseDetails.verificationData.serverVerificationData,
              'productId': purchaseDetails.productID,
              'transactionId': purchaseDetails.purchaseID,
              'planId': _getPlanIdFromProductId(purchaseDetails.productID),
              'credits': _getCreditsFromProductId(purchaseDetails.productID),
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Recovered purchase verified successfully');
          // Complete the purchase
          await _inAppPurchase.completePurchase(purchaseDetails);

          // Refresh credits
          await CreditSystemService.getUserCredits();
        } else {
          print('❌ Recovered purchase verification failed: ${data['message']}');
          onError(data['message'] ?? 'Verification failed');
        }
      } else {
        print('❌ Backend error during recovery: ${response.statusCode}');
        onError('Backend verification failed');
      }
    } catch (e) {
      print('💥 Error verifying recovered purchase: $e');
      onError(e.toString());
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

  // Store multiple purchase callbacks with purchase ID as key
  static Map<String, Map<String, dynamic>> _purchaseCallbacks = {};

  // Initialize purchase stream listener
  static void initializePurchaseStream() {
    _subscription?.cancel();
    _subscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) async {
        print('🔔 Received ${purchaseDetailsList.length} purchase updates');

        for (final purchase in purchaseDetailsList) {
          final purchaseId = purchase.purchaseID ?? purchase.productID;
          print(
            '🔄 Processing purchase: $purchaseId - ${purchase.status} - ${purchase.productID}',
          );

          // Find matching plan ID by product ID
          String? matchingPlanId;
          Map<String, dynamic>? callbacks;

          // Find plan ID by product ID
          for (final entry in productIds.entries) {
            if (entry.value == purchase.productID) {
              matchingPlanId = entry.key;
              break;
            }
          }

          if (matchingPlanId == null) {
            print('❌ No plan found for product ID: ${purchase.productID}');
            continue;
          }

          // Look for callbacks in different places
          // 1. Check current purchase callbacks
          if (_currentPurchaseCallbacks != null &&
              _currentPurchaseCallbacks!['planId'] == matchingPlanId) {
            callbacks = _currentPurchaseCallbacks;
          }

          // 2. Check stored callbacks by plan ID
          if (callbacks == null) {
            callbacks = _purchaseCallbacks[matchingPlanId];
          }

          // 3. Check stored callbacks by purchase ID
          if (callbacks == null) {
            callbacks = _purchaseCallbacks[purchaseId];
          }

          if (callbacks != null) {
            print('✅ Found callbacks for purchase, processing...');
            await _handlePurchaseUpdate(
              purchase,
              matchingPlanId,
              callbacks['onSuccess'],
              callbacks['onError'],
            );

            // Clean up callbacks after handling
            _purchaseCallbacks.remove(matchingPlanId);
            _purchaseCallbacks.remove(purchaseId);
            if (_currentPurchaseCallbacks != null &&
                _currentPurchaseCallbacks!['planId'] == matchingPlanId) {
              _currentPurchaseCallbacks = null;
            }
          } else {
            print(
              '⚠️ No callbacks found for purchase: ${purchase.productID} (Plan: $matchingPlanId)',
            );

            // Still try to verify and complete the purchase
            // This handles cases where app was closed during purchase
            if (purchase.status == PurchaseStatus.purchased) {
              print('🔄 Attempting verification without callbacks...');
              final success = await _verifyAndAddCredits(
                purchase,
                matchingPlanId,
              );
              print(
                success ? '✅ Verification successful' : '❌ Verification failed',
              );
            }

            // Always complete the purchase to avoid Play Store issues
            if (purchase.pendingCompletePurchase) {
              print('✅ Completing purchase...');
              await _inAppPurchase.completePurchase(purchase);
            }
          }
        }
      },
      onError: (error) {
        print('💥 Purchase stream error: $error');
        // Notify all active callbacks about the error
        if (_currentPurchaseCallbacks != null) {
          _currentPurchaseCallbacks!['onError'](
            'Purchase stream error: $error',
          );
        }
        for (final callbacks in _purchaseCallbacks.values) {
          if (callbacks['onError'] != null) {
            callbacks['onError']('Purchase stream error: $error');
          }
        }
      },
    );
  }

  // Clear any pending purchases to prevent "You already own this item" errors
  static Future<void> _clearPendingPurchases() async {
    try {
      print('🧹 Clearing any pending purchases...');

      // Get current purchases
      await _inAppPurchase.restorePurchases();

      // Wait a moment for restore to complete
      await Future.delayed(Duration(milliseconds: 500));

      print('✅ Pending purchases cleared');
    } catch (e) {
      print('⚠️ Error clearing pending purchases: $e');
      // Don't throw error, just log it
    }
  }

  // Dispose purchase stream
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // Purchase a plan using in-app purchase
  static Future<bool> purchasePlan({
    required String planId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('🛒 Starting purchase for plan: $planId');

      // First, ensure user exists in backend
      print('🔄 Ensuring user exists in backend...');
      final userSynced = await UserSyncService.ensureUserExistsInBackend();
      if (!userSynced) {
        print(
          '⚠️ Warning: Could not verify user in backend, continuing anyway...',
        );
      }

      // Clear any pending purchases to prevent "You already own this item"
      await _clearPendingPurchases(); // Initialize if needed
      final initialized = await initializeInAppPurchase();
      if (!initialized) {
        onError('In-app purchases not available');
        return false;
      }

      // Initialize purchase stream if not already done
      if (_subscription == null) {
        initializePurchaseStream();
      }

      // Store callbacks for this purchase in multiple ways for reliability
      _currentPurchaseCallbacks = {
        'planId': planId,
        'onSuccess': onSuccess,
        'onError': onError,
      };

      // Store callbacks by plan ID
      _purchaseCallbacks[planId] = {'onSuccess': onSuccess, 'onError': onError};

      // Also store by product ID in case plan ID lookup fails
      final storeProductId = productIds[planId];
      if (storeProductId != null) {
        _purchaseCallbacks[storeProductId] = {
          'onSuccess': onSuccess,
          'onError': onError,
        };
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

      // Determine purchase type based on plan
      bool success;
      if (topupProductIds.containsKey(planId)) {
        // Credits are CONSUMABLE - can be purchased multiple times
        print('🔄 Purchasing CONSUMABLE product (credits): $planId');
        success = await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        // Subscriptions and Faceless are NON-CONSUMABLE
        print(
          '🔄 Purchasing NON-CONSUMABLE product (subscription/faceless): $planId',
        );
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }

      if (success) {
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
      print(
        'Handling purchase update: ${purchase.status} for ${purchase.productID}',
      );

      if (purchase.status == PurchaseStatus.purchased) {
        print('Purchase successful, verifying with backend...');

        // Always complete the purchase first to prevent "You already own this item"
        if (purchase.pendingCompletePurchase) {
          print('Completing purchase to prevent ownership conflicts...');
          await _inAppPurchase.completePurchase(purchase);
        }

        // Then verify purchase with backend and add credits
        final success = await _verifyAndAddCredits(purchase, planId);

        if (success) {
          print('Purchase verification successful');
          onSuccess('Purchase successful! Credits added to your account.');
        } else {
          print('Purchase verification failed - retrying once...');
          // Retry verification once
          await Future.delayed(Duration(seconds: 2));
          final retrySuccess = await _verifyAndAddCredits(purchase, planId);
          if (retrySuccess) {
            onSuccess('Purchase successful! Credits added to your account.');
          } else {
            // Even if verification fails, the purchase was completed successfully
            // User should contact support but won't be charged again
            onError(
              'Purchase completed but verification failed. Please check your credits or contact support.',
            );
          }
        }
        if (purchase.pendingCompletePurchase) {
          print('Completing purchase...');
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        final errorMessage = purchase.error?.message ?? 'Unknown error';
        print('Purchase error: $errorMessage');
        onError('Purchase failed: $errorMessage');
      } else if (purchase.status == PurchaseStatus.canceled) {
        print('Purchase was canceled by user');
        onError('Purchase was canceled');
      } else if (purchase.status == PurchaseStatus.pending) {
        print('Purchase is pending...');
        // Don't call onError or onSuccess for pending purchases
        // Just complete the purchase if needed
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.restored) {
        print('Purchase was restored');
        // Handle restored purchase - treat as successful
        final success = await _verifyAndAddCredits(purchase, planId);
        if (success) {
          onSuccess('Purchase restored! Credits added to your account.');
        } else {
          onError(
            'Purchase restored but verification failed. Please contact support.',
          );
        }
      } else {
        print('⚠️ Unknown purchase status: ${purchase.status}');
        print(
          '🔍 Purchase details: ProductID=${purchase.productID}, TransactionID=${purchase.purchaseID}',
        );

        // For unknown status, try to handle it smartly
        if (purchase.purchaseID != null && purchase.purchaseID!.isNotEmpty) {
          print('🔄 Attempting to verify unknown status purchase...');

          // Try to verify with backend anyway - might be a successful purchase
          final success = await _verifyAndAddCredits(purchase, planId);
          if (success) {
            print('✅ Unknown status purchase verified successfully');
            onSuccess('Purchase completed! Credits added to your account.');
          } else {
            print('❌ Unknown status purchase verification failed');
            onError(
              'Purchase status unclear. Please check your credits or contact support.',
            );
          }
        } else {
          print('❌ Unknown status with no transaction ID');
          onError(
            'Purchase status unclear. Please try again or contact support.',
          );
        }

        // Always complete unknown status purchases to prevent stuck state
        if (purchase.pendingCompletePurchase) {
          print('🔧 Completing unknown status purchase to prevent stuck state');
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    } catch (e) {
      print('Error handling purchase update: $e');
      onError('Error processing purchase: $e');
    } finally {
      // Clear callbacks after handling
      _currentPurchaseCallbacks = null;
    }
  }

  // Verify purchase with backend and add credits
  static Future<bool> _verifyAndAddCredits(
    PurchaseDetails purchase,
    String planId,
  ) async {
    try {
      final planDetails = CreditSystemService.getPlanDetails(planId);

      // Default credits for test purchases or unknown plans
      int credits = 30; // Default fallback

      if (planDetails == null) {
        print('⚠️ Plan details not found for planId: $planId');
        print('🧪 Using fallback: 30 credits for test/unknown product');

        // Try to extract credits from product ID directly
        final extractedCredits = _getCreditsFromProductId(purchase.productID);
        if (extractedCredits > 0) {
          credits = extractedCredits;
          print(
            '✅ Extracted $credits credits from product ID: ${purchase.productID}',
          );
        }
      } else {
        // Use credits from plan details
        if (planDetails.containsKey('videos')) {
          credits = planDetails['videos'] as int;
        } else if (planDetails.containsKey('credits')) {
          credits = planDetails['credits'] as int;
        }
        print('✅ Found plan details - Credits: $credits');
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated');
        return false;
      }

      // Ensure user exists in backend before verification
      print('🔄 Pre-verification: Ensuring user exists in backend...');
      final userSynced = await UserSyncService.ensureUserExistsInBackend();
      if (!userSynced) {
        print(
          '⚠️ Warning: Could not verify user in backend, continuing with verification...',
        );
      }

      // Get the purchase token and product ID
      final purchaseToken = purchase.verificationData.serverVerificationData;
      final productId = purchase.productID;
      final transactionId = purchase.purchaseID ?? '';

      if (transactionId.isEmpty) {
        print('Transaction ID is empty');
        return false;
      }

      // Verify purchase with backend (with retry mechanism)
      final token = await user.getIdToken();

      print('🔐 Starting purchase verification for:');
      print('  - Product ID: $productId');
      print('  - Plan ID: $planId');
      print('  - Credits: $credits');
      print('  - Transaction ID: $transactionId');
      print('  - Purchase Status: ${purchase.status}');
      print('  - Backend URL: $baseUrl');
      print('  - Full Verify URL: $baseUrl/api/payments/verify-purchase');

      // Retry configuration
      const maxRetries = 3;
      const retryDelay = Duration(seconds: 2);

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('🔄 Purchase verification attempt $attempt/$maxRetries');

          final response = await http
              .post(
                Uri.parse('$baseUrl/api/payments/verify-purchase'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'purchaseToken': purchaseToken,
                  'productId': productId,
                  'transactionId': transactionId,
                  'planId': planId,
                  'credits': credits,
                }),
              )
              .timeout(const Duration(seconds: 30));

          print(
            '📡 Purchase verification response: ${response.statusCode} - ${response.body}',
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final success = data['success'] ?? false;
            final verified = data['verified'] ?? false;

            print('🔍 Backend response details:');
            print('  - Success: $success');
            print('  - Verified: $verified');
            print('  - Message: ${data['message'] ?? 'No message'}');
            print('  - Error: ${data['error'] ?? 'No error'}');

            if (success && verified) {
              print(
                '✅ Purchase verified successfully. Credits added: ${data['creditsAdded']}',
              );
              return true;
            } else {
              print(
                '❌ Purchase verification failed: ${data['error'] ?? data['message'] ?? 'Unknown error'}',
              );
              print('🔍 Full backend response: ${response.body}');
              print('📊 Response data: $data');

              // Check for specific error patterns
              final errorMsg =
                  data['error']?.toString() ??
                  data['message']?.toString() ??
                  '';

              // Don't retry for verification failures (these are likely permanent)
              if (errorMsg.contains('already processed') ||
                  errorMsg.contains('duplicate') ||
                  errorMsg.contains('already exists')) {
                print('ℹ️ Purchase already processed, treating as success');
                return true;
              }

              // If it's a Google Play verification issue, try basic validation
              if (errorMsg.contains('google_play') ||
                  errorMsg.contains('verification failed') ||
                  errorMsg.contains('Purchase verification failed')) {
                print(
                  '⚠️ Google Play verification failed, checking for basic validation fallback',
                );
                if (data.containsKey('verified') && data['verified'] == true) {
                  print('✅ Fallback verification passed');
                  return true;
                }
              }

              return false;
            }
          } else if (response.statusCode >= 500 && attempt < maxRetries) {
            // Server error - retry
            print(
              '⚠️ Server error ${response.statusCode}, retrying in ${retryDelay.inSeconds}s...',
            );
            await Future.delayed(retryDelay);
            continue;
          } else {
            // Client error or final attempt
            final errorData = jsonDecode(response.body);
            print(
              '❌ Purchase verification failed with status ${response.statusCode}: ${errorData['error']}',
            );
            return false;
          }
        } catch (e) {
          if (attempt < maxRetries) {
            print(
              '⚠️ Network error during verification (attempt $attempt): $e, retrying...',
            );
            await Future.delayed(retryDelay);
            continue;
          } else {
            print('💥 Final attempt failed: $e');
            return false;
          }
        }
      }

      return false;
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

      print('🔍 Payment History API Response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend returns 'payments' field
        final transactions = data['payments'] ?? data['transactions'] ?? [];

        print(
          '📋 Found ${transactions.length} transactions in payment history',
        );

        // Map backend transaction data to frontend format
        return transactions.map<Map<String, dynamic>>((transaction) {
          print('📝 Processing transaction: $transaction');

          // Get amount and credits from backend response (backend uses 'credits' field)
          final amount = transaction['amount'] ?? 0.0;
          final credits =
              transaction['credits'] ??
              transaction['creditsPurchased'] ??
              _getCreditsFromAmount(amount);
          final planName =
              transaction['planId'] ?? _getPlanNameFromAmount(amount);

          return {
            'createdAt': transaction['date'] ?? transaction['createdAt'] ?? '',
            'planType': planName,
            'amount': amount,
            'creditsPurchased': credits,
            'status': _mapStatus(transaction['status'] ?? 'unknown'),
            'transactionId':
                transaction['transactionId'] ?? transaction['id'] ?? '',
            'type': transaction['type'] ?? 'purchase',
          };
        }).toList();
      } else {
        throw Exception(
          'Failed to fetch payment history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // Helper method to get credits from amount
  static int _getCreditsFromAmount(dynamic amount) {
    final amountValue = amount is int
        ? amount.toDouble()
        : (amount as double? ?? 0.0);

    // Map amount to credits based on your pricing
    if (amountValue >= 149.99) return 9000; // Business plan
    if (amountValue >= 69.99) return 4000; // Pro plan
    if (amountValue >= 24.99) return 1300; // Starter plan
    if (amountValue >= 9.99) return 500; // Basic plan

    // For custom amounts, estimate credits (assuming $0.01 per credit)
    return (amountValue * 100).round();
  }

  // Helper method to get plan name from amount
  static String _getPlanNameFromAmount(dynamic amount) {
    final amountValue = amount is int
        ? amount.toDouble()
        : (amount as double? ?? 0.0);

    if (amountValue >= 149.99) return 'Business';
    if (amountValue >= 69.99) return 'Pro';
    if (amountValue >= 24.99) return 'Starter';
    if (amountValue >= 9.99) return 'Basic';

    return 'Custom';
  }

  // Helper method to map status
  static String _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'succeeded':
        return 'Completed';
      case 'pending':
      case 'processing':
        return 'Pending';
      case 'failed':
      case 'error':
        return 'Failed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return 'Completed'; // Default to completed for better UX
    }
  }

  // Helper method to get plan ID from product ID
  static String _getPlanIdFromProductId(String productId) {
    // New format: subbasic_30videos_27, topup_10credits_10, etc.
    if (productId.startsWith('sub_')) {
      // Extract plan name: subbasic_30videos_27 -> basic
      final parts = productId.split('_');
      if (parts.length >= 2) return parts[1]; // Returns: basic, starter, pro
    } else if (productId.startsWith('topup_')) {
      // topup_10credits_10 -> credits_10
      final match = RegExp(r'topup_(\d+)credits').firstMatch(productId);
      if (match != null) {
        final credits = match.group(1);
        return 'credits_$credits'; // Returns: credits_10, credits_20, credits_30
      }
    }

    // Fallback to 'basic' for unknown formats
    print('⚠️ Unknown product ID format: $productId, defaulting to basic');
    return 'basic';
  }

  // Helper method to get credits from product ID
  static int _getCreditsFromProductId(String productId) {
    // New format: subbasic_30videos_27, topup_10credits_10, etc.
    if (productId.startsWith('sub_')) {
      // Extract video count: subbasic_30videos_27 -> 30
      final match = RegExp(r'_(\d+)videos_').firstMatch(productId);
      if (match != null) {
        return int.parse(match.group(1) ?? '0');
      }
    } else if (productId.startsWith('topup_')) {
      // Extract credits: topup_10credits_10 -> 10
      final match = RegExp(r'topup_(\d+)credits').firstMatch(productId);
      if (match != null) {
        return int.parse(match.group(1) ?? '0');
      }
    }

    // Fallback
    print('⚠️ Unknown product ID format: $productId, defaulting to 0');
    return 0;
  }
}
