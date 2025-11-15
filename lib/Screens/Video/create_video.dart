import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Screens/Avatar/my_avatars_screen.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';
import 'package:video_gen_app/Component/credit_usage_widget.dart';
import 'package:video_gen_app/Screens/Settings/credit_purchase_screen.dart';

class CreateVideo extends StatefulWidget {
  final bool showAppBar;

  const CreateVideo({super.key, this.showAppBar = true});

  @override
  State<CreateVideo> createState() => _CreateVideoState();
}

class _CreateVideoState extends State<CreateVideo> {
  int _currentCredits = 0;
  bool _isLoadingCredits = true;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    try {
      final credits = await CreditSystemService.getUserCredits();
      setState(() {
        _currentCredits = credits;
        _isLoadingCredits = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCredits = false;
      });
    }
  }

  Future<void> _checkCreditsAndNavigate({
    required String videoType,
    required Widget destination,
    int? durationMinutes,
    int? durationSeconds,
  }) async {
    final requiredCredits = CreditSystemService.calculateRequiredCredits(
      videoType: videoType,
      durationMinutes: durationMinutes,
      durationSeconds: durationSeconds,
    );

    if (_currentCredits < requiredCredits) {
      _showInsufficientCreditsDialog(requiredCredits);
      return;
    }

    // Show credit usage dialog
    showDialog(
      context: context,
      builder: (context) => CreditUsageWidget(
        videoType: videoType,
        durationMinutes: durationMinutes,
        onProceed: () {
          Navigator.of(context).pop();
          Navigator.push(context, AnimatedPageRoute(page: destination));
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showInsufficientCreditsDialog(int requiredCredits) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGreyColor,
        title: const Text(
          'Insufficient Credits',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need $requiredCredits credits to generate this video.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Current balance: $_currentCredits credits',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                AnimatedPageRoute(page: const CreditPurchaseScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueColor,
            ),
            child: const Text(
              'Buy Credits',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGreyColor,
        title: Row(
          children: [
            Icon(Icons.upcoming, color: AppColors.blueColor, size: 24),
            const SizedBox(width: 12),
            const Text('Coming Soon', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Text-based video generation feature is under development and will be available in the next update.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.blueColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.blueColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Try Avatar Videos in the meantime!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkCreditsAndNavigate(
                videoType: 'avatar-video',
                destination: const MyAvatarsScreen(),
                durationMinutes: 1,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueColor,
            ),
            child: const Text(
              'Try Avatar Videos',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.appBgColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),

              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Video Generator",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Choose how you want to create your video",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  // Credit display
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      AnimatedPageRoute(page: const CreditPurchaseScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkGreyColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.blueColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.blueColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          _isLoadingCredits
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.blueColor,
                                  ),
                                )
                              : Text(
                                  '$_currentCredits',
                                  style: TextStyle(
                                    color: AppColors.blueColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Text-Based Video Option
              _buildVideoOption(
                imagePath: "images/text-icon.png",
                iconColor: AppColors.purpleColor,
                title: "Text-Based Video",
                subtitle: "Generate video from text description",
                creditsRequired: 320,
                comingSoon: true,
                onTap: () => _showComingSoonDialog(),
              ),
              const SizedBox(height: 20),

              // Avatar Video Option
              _buildVideoOption(
                imagePath: "images/avatar-icon.png",
                iconColor: AppColors.purpleColor,
                title: "Avatar Video",
                subtitle: "Use your AI Avatar to speak your script",
                creditsRequired: 1,
                creditsUnit: "credit per minute",
                onTap: () => _checkCreditsAndNavigate(
                  videoType: 'avatar-video',
                  destination: const MyAvatarsScreen(),
                  durationMinutes: 1,
                ),
              ),

              const Spacer(),

              // Info Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.blueColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Choose your preferred video creation method. Avatar videos require an active avatar from your collection.",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOption({
    required String imagePath,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int creditsRequired,
    String? creditsUnit,
    bool comingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkGreyColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyColor.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: comingSoon ? Colors.grey : iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      imagePath,
                      width: 40,
                      height: 40,
                      color: comingSoon ? Colors.grey[600] : null,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if image not found
                        return Icon(
                          title.contains("Text")
                              ? Icons.text_fields
                              : Icons.person,
                          color: comingSoon ? Colors.grey[600] : iconColor,
                          size: 28,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: comingSoon ? Colors.grey : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: comingSoon ? Colors.grey[600] : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!comingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.blueColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '$creditsRequired ${creditsUnit != null
                                ? creditsUnit
                                : creditsRequired == 1
                                ? 'credit'
                                : 'credits'}',
                            style: TextStyle(
                              color: AppColors.blueColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: comingSoon ? Colors.grey[600] : Colors.white,
                  size: 20,
                ),
              ],
            ),
            if (comingSoon)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purpleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMING SOON',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
