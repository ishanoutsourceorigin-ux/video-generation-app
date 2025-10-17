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
  List<Map<String, dynamic>> _purchaseHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final credits = await CreditSystemService.getUserCredits();
      final history = await PaymentService.getPaymentHistory();

      setState(() {
        _currentCredits = credits;
        _purchaseHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading data: $e');
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

      // For now, simulate purchase (replace with actual in-app purchase)
      final success = await CreditSystemService.addCredits(
        credits: planDetails['credits'],
        planId: planId,
        transactionId: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        await _loadData(); // Refresh data

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${planDetails['credits']} credits added successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
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

                  // Credit packages
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a credit package that fits your needs',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Credit packages grid
                  ...CreditSystemService.getAvailablePlans().map((plan) {
                    final isPopular = plan['id'] == 'starter';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _buildCreditPackage(
                        plan['name'],
                        '\$${plan['price']}',
                        '${plan['credits']} credits • ${plan['textToVideos']} Text Videos + ${plan['avatarVideos']} Avatar Videos',
                        isPopular,
                        plan['id'],
                        plan['credits'],
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
                          'Text-to-Video Generation',
                          '320 credits per video (~8 seconds)',
                          Icons.video_call,
                        ),
                        const SizedBox(height: 16),
                        _buildCreditInfo(
                          'Avatar-Based Videos',
                          '40 credits per minute',
                          Icons.person,
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
    int credits,
  ) {
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
