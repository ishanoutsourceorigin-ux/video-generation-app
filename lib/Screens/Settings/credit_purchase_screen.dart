import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';
import 'package:video_gen_app/Services/payment_service.dart';
import 'package:video_gen_app/Component/round_button.dart';

class CreditPurchaseScreen extends StatefulWidget {
  const CreditPurchaseScreen({super.key});

  @override
  State<CreditPurchaseScreen> createState() => _CreditPurchaseScreenState();
}

class _CreditPurchaseScreenState extends State<CreditPurchaseScreen> {
  int _currentCredits = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final credits = await CreditSystemService.getUserCredits();

      setState(() {
        _currentCredits = credits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchasePlan(String planId) async {
    try {
      final planDetails = CreditSystemService.getPlanDetails(planId);
      if (planDetails == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkGreyColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.blueColor),
              const SizedBox(height: 16),
              const Text(
                'Processing purchase...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Use real in-app purchase
      final success = await PaymentService.purchasePlan(
        planId: planId,
        onSuccess: (message) async {
          Navigator.of(context).pop(); // Close loading dialog
          await _loadData(); // Refresh data

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onError: (error) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );

      if (!success) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initiate purchase. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
        title: const Text(
          'Buy Credits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.blueColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current credit balance
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.blueColor, AppColors.purpleColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentCredits Credits',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use credits to generate AI videos',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Monthly Subscriptions Section
                  const Text(
                    'Monthly Subscriptions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a monthly plan (only one subscription active at a time)',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Info box about new credit system
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blueColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.blueColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.blueColor),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '1 credit = 1 minute of video\n(1 min 1 sec = 2 credits)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subscription packages
                  ...CreditSystemService.getAvailableSubscriptions().map((
                    plan,
                  ) {
                    final isPopular = plan['popular'] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _buildCreditPackage(
                        plan['name'],
                        plan['priceDisplay'] + '/month',
                        '${plan['videos']} videos per month\n(~${plan['videos']} minutes of content)\n${isPopular ? "Most Popular!" : plan['description']}',
                        isPopular,
                        plan['id'],
                        plan['videos'],
                        isSubscription: true,
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),

                  // Credit Top-ups Section
                  const Text(
                    'Credit Top-ups',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need more credits? Top up anytime, even with an active subscription',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Credit topup packages
                  ...CreditSystemService.getAvailableCreditTopups().map((
                    topup,
                  ) {
                    final isPopular = topup['popular'] ?? false;
                    final savings = topup['savings'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _buildCreditPackage(
                        topup['name'],
                        topup['priceDisplay'],
                        '${topup['credits']} additional credits\n(~${topup['credits']} minutes of videos)\n${savings != null ? savings : topup['description']}',
                        isPopular,
                        topup['id'],
                        topup['credits'],
                        isSubscription: false,
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),

                  // Credit usage info
                  const Text(
                    'How Credits Work',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreyColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildCreditInfo(
                          'Avatar-Based Videos',
                          '1 credit = 1 minute\n1 min 1 sec = 2 credits',
                          Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildCreditInfo(
                          'Text-to-Video Generation',
                          'Coming Soon! Stay tuned for updates',
                          Icons.video_call,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCreditPackage(
    String title,
    String price,
    String description,
    bool isPopular,
    String planId,
    int credits, {
    bool isSubscription = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppColors.blueColor : Colors.grey.withOpacity(0.2),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blueColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: TextStyle(
                        color: AppColors.blueColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                height: 48,
                child: RoundButton(
                  title: 'Buy Now',
                  onPress: () => _purchasePlan(planId),
                  bgColor: isPopular
                      ? AppColors.blueColor
                      : AppColors.purpleColor,
                  fontSize: 14,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfo(String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.blueColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
