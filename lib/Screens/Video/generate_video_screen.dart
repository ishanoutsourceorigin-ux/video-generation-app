import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';
import 'package:video_gen_app/Screens/Video/avatar_videos_screen.dart';
import 'package:video_gen_app/Screens/Settings/credit_purchase_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';

class GenerateVideoScreen extends StatefulWidget {
  final Map<String, dynamic> avatar;

  const GenerateVideoScreen({super.key, required this.avatar});

  @override
  State<GenerateVideoScreen> createState() => _GenerateVideoScreenState();
}

class _GenerateVideoScreenState extends State<GenerateVideoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _scriptController = TextEditingController();
  bool _isGenerating = false;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController =
      TextEditingController();

  // Default prompts
  final String _defaultPrompt =
      "high quality, clear, cinematic, natural speaking, perfect lip sync, professional";
  final String _defaultNegativePrompt =
      "blurry, low quality, chaotic, deformed, watermark, bad anatomy, shaky camera, distorted face";

  @override
  void dispose() {
    _titleController.dispose();
    _scriptController.dispose();
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarName = widget.avatar['name'] ?? 'Unknown';
    final avatarImageUrl = widget.avatar['imageUrl'] ?? '';

    // Debug: Print avatar data structure
    // print("🔍 Avatar data received: ${widget.avatar}");
    // print("📝 Avatar keys: ${widget.avatar.keys.toList()}");

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Generate AI Video",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Create AI Video",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Generate a talking video with $avatarName",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Avatar Preview
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.blueColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.purpleColor, width: 3),
                  ),
                  child: avatarImageUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            avatarImageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  avatarName.isNotEmpty
                                      ? avatarName[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            avatarName.isNotEmpty
                                ? avatarName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  avatarName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Video Title Input
              const Text(
                "Video Title",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RoundTextField(
                label: "Video Title",
                hint: "Enter video title (e.g., Welcome Message)",
                textEditingController: _titleController,
                inputType: TextInputType.text,
                bgColor: AppColors.darkGreyColor,
                enabledBorderColor: AppColors.greyColor.withValues(alpha: 0.3),
                focusedBorderColor: AppColors.purpleColor,
              ),
              const SizedBox(height: 24),

              // Script Input
              const Text(
                "Video Script",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _scriptController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        "Enter the script that $avatarName will speak...\n\nExample:\nHello! Welcome to our company. I'm excited to help you with your journey. Let me know how I can assist you today.",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Write the text that your AI avatar will speak in the video",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Custom Prompt Section
              const Text(
                "Generation Prompt (Optional)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _promptController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _defaultPrompt,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Customize the generation prompt or leave empty for default optimized settings",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 40),

              // Generate Button
              RoundButton(
                title: _isGenerating ? "Generating Video..." : "Generate Video",
                onPress: _isGenerating ? () {} : _generateVideo,
                leadingIcon: _isGenerating ? null : Icons.videocam,
                leadingIconColor: Colors.white,
                bgColor: _isGenerating
                    ? AppColors.greyColor.withValues(alpha: 0.5)
                    : AppColors.purpleColor,
                borderRadius: 12,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              const SizedBox(height: 16),

              // View Generated Videos Button
              RoundButton(
                title: "View Generated Videos",
                onPress: () {
                  Navigator.push(
                    context,
                    AnimatedPageRoute(page: const AvatarVideosScreen()),
                  );
                },
                leadingIcon: Icons.video_library,
                leadingIconColor: Colors.white,
                bgColor: AppColors.darkGreyColor,
                borderRadius: 12,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),

              // Info Section
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.blueColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.blueColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Video Generation Info",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Video generation powered by CloneX AI technology\n"
                      "• Perfect lip-sync with your avatar's cloned voice\n"
                      "• Customizable prompts for different styles and moods\n"
                      // "• Automatic duration optimization based on script\n"
                      "• High-quality natural expressions and movements",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                        height: 1.4,
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

  Future<void> _generateVideo() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError("Please enter a video title");
      return;
    }

    if (_scriptController.text.trim().isEmpty) {
      _showError("Please enter a script for the video");
      return;
    }

    // Get avatar ID - check multiple possible field names
    final avatarId =
        widget.avatar['id'] ??
        widget.avatar['_id'] ??
        widget.avatar['avatarId'];

    if (avatarId == null) {
      print("❌ Available avatar fields: ${widget.avatar.keys.toList()}");
      _showError("Avatar ID not found. Please try selecting the avatar again.");
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // CREDIT CHECK: Estimate video duration and check credits
      print("💳 Checking credits for avatar video generation...");
      final scriptLength = _scriptController.text.trim().length;
      final estimatedMinutes = (scriptLength / 150)
          .ceil(); // ~150 chars per minute
      final requiredCredits = CreditSystemService.calculateRequiredCredits(
        videoType: 'avatar-video',
        durationMinutes: estimatedMinutes,
      );

      print("📊 Script length: $scriptLength characters");
      print("⏱️ Estimated duration: $estimatedMinutes minutes");
      print("💰 Required credits: $requiredCredits");

      // Check if user has enough credits
      final hasEnoughCredits = await CreditSystemService.hasEnoughCredits(
        videoType: 'avatar-video',
        durationMinutes: estimatedMinutes,
      );

      if (!hasEnoughCredits) {
        print("❌ Insufficient credits for avatar video generation");
        setState(() {
          _isGenerating = false;
        });
        _showInsufficientCreditsDialog(requiredCredits, estimatedMinutes);
        return;
      }

      print("✅ Credits check passed - user has enough credits");

      // CONSUME CREDITS BEFORE VIDEO GENERATION
      print("💳 Consuming credits before video generation...");
      final creditsConsumed = await CreditSystemService.consumeCredits(
        videoType: 'avatar-video',
        durationMinutes: estimatedMinutes,
        projectId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!creditsConsumed) {
        print("❌ Failed to consume credits");
        setState(() {
          _isGenerating = false;
        });
        _showError("Failed to deduct credits. Please try again.");
        return;
      }

      print("✅ Credits consumed successfully");
      print("🎬 Starting video generation...");
      print("📹 Title: ${_titleController.text.trim()}");
      print("📝 Script: ${_scriptController.text.trim()}");
      print("👤 Avatar ID: $avatarId");

      final result = await ApiService.createVideo(
        avatarId: avatarId,
        title: _titleController.text.trim(),
        script: _scriptController.text.trim(),
        prompt: _promptController.text.trim().isNotEmpty
            ? _promptController.text.trim()
            : _defaultPrompt,
        negativePrompt: _negativePromptController.text.trim().isNotEmpty
            ? _negativePromptController.text.trim()
            : _defaultNegativePrompt,
      );

      print("✅ Video generation started: $result");

      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Avatar video generation started! You'll be notified when it's ready.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      print("🏠 Navigating to avatar videos screen...");
      // Navigate to avatar videos screen (same as text video flow)
      Navigator.pushReplacement(
        context,
        AnimatedPageRoute(page: const AvatarVideosScreen()),
      );
    } catch (e) {
      print("❌ Error generating video: $e");
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInsufficientCreditsDialog(
    int requiredCredits,
    int estimatedMinutes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkGreyColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.purpleColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Insufficient Credits",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
              Text(
                "You need $requiredCredits credits to generate this avatar video (estimated ${estimatedMinutes} minute${estimatedMinutes > 1 ? 's' : ''}).",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.blueColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "💡 Avatar Video Pricing",
                      style: TextStyle(
                        color: AppColors.blueColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "• ${CreditSystemService.avatarVideoCreditsPerMinute} credits per minute\n• High-quality avatar videos by CloneX\n• Perfect lip-sync with cloned voice",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AnimatedPageRoute(page: const CreditPurchaseScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Buy Credits"),
            ),
          ],
        );
      },
    );
  }
}
