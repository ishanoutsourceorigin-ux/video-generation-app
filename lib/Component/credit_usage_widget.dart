import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';

class CreditUsageWidget extends StatelessWidget {
  final String videoType;
  final int? durationMinutes;
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const CreditUsageWidget({
    super.key,
    required this.videoType,
    this.durationMinutes,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final requiredCredits = CreditSystemService.calculateRequiredCredits(
      videoType: videoType,
      durationMinutes: durationMinutes,
    );

    return AlertDialog(
      backgroundColor: AppColors.darkGreyColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.credit_card,
              color: AppColors.blueColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Credit Usage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video type info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.appBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoType == 'text-to-video'
                      ? 'Text-to-Video Generation'
                      : 'Avatar-Based Video',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (videoType == 'avatar-video' && durationMinutes != null) ...[
                  Text(
                    'Duration: ${durationMinutes} minute${durationMinutes! > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ] else if (videoType == 'text-to-video') ...[
                  const Text(
                    'Duration: ~8 seconds',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Credit breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credits Required:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.blueColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$requiredCredits Credits',
                  style: TextStyle(
                    color: AppColors.blueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cost breakdown (internal info)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    videoType == 'text-to-video'
                        ? 'Text-to-Video: ${CreditSystemService.textToVideoCredits} credits per video'
                        : 'Avatar Video: ${CreditSystemService.avatarVideoCreditsPerMinute} credit per minute',
                    style: const TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: onProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blueColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Use $requiredCredits Credits'),
        ),
      ],
    );
  }
}

// Helper widget to check and display credit status
class CreditStatusWidget extends StatefulWidget {
  final Widget child;

  const CreditStatusWidget({super.key, required this.child});

  @override
  State<CreditStatusWidget> createState() => _CreditStatusWidgetState();
}

class _CreditStatusWidgetState extends State<CreditStatusWidget> {
  int _currentCredits = 0;
  bool _isLoading = true;

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Credit display header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkGreyColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppColors.blueColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Available Credits:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.blueColor,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _currentCredits > 0
                            ? AppColors.blueColor.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _currentCredits > 0
                              ? AppColors.blueColor.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$_currentCredits',
                        style: TextStyle(
                          color: _currentCredits > 0
                              ? AppColors.blueColor
                              : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}
