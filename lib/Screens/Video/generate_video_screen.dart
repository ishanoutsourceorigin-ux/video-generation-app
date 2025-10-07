import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Video/avatar_videos_screen.dart';
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
  String _selectedAspectRatio = '9:16'; // Default to portrait for avatars
  String _selectedExpression = 'neutral'; // Default expression

  // D-ID supported aspect ratios only
  final List<Map<String, dynamic>> _aspectRatios = [
    {'label': 'Portrait (9:16) - Best for mobile', 'value': '9:16'},
    {'label': 'Landscape (16:9) - Best for desktop', 'value': '16:9'},
    {'label': 'Square (1:1) - Best for social media', 'value': '1:1'},
  ];

  // D-ID supported expressions
  final List<Map<String, dynamic>> _expressions = [
    {'label': 'Neutral - Natural expression', 'value': 'neutral'},
    {'label': 'Happy - Smiling expression', 'value': 'happy'},
    {'label': 'Surprise - Surprised expression', 'value': 'surprise'},
    {'label': 'Serious - Professional expression', 'value': 'serious'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _scriptController.dispose();
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

              // Aspect Ratio Selection
              const Text(
                "Video Aspect Ratio",
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAspectRatio,
                    isExpanded: true,
                    dropdownColor: AppColors.darkGreyColor,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedAspectRatio = newValue;
                        });
                      }
                    },
                    items: _aspectRatios.map<DropdownMenuItem<String>>((ratio) {
                      return DropdownMenuItem<String>(
                        value: ratio['value'] as String,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            ratio['label'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose aspect ratio for your talking head video (duration auto-detected from audio)",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Expression Selection
              const Text(
                "Avatar Expression",
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedExpression,
                    isExpanded: true,
                    dropdownColor: AppColors.darkGreyColor,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedExpression = newValue;
                        });
                      }
                    },
                    items: _expressions.map<DropdownMenuItem<String>>((
                      expression,
                    ) {
                      return DropdownMenuItem<String>(
                        value: expression['value'] as String,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            expression['label'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose facial expression for your avatar during the video",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
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
                      "• Video generation takes 1-2 minutes with D-ID\n"
                      "• Perfect lip-sync with your avatar's cloned voice\n"
                      "• Duration auto-detected from your script length\n"
                      "• High-quality talking head video with natural expressions",
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
      print("🎬 Starting video generation...");
      print("📹 Title: ${_titleController.text.trim()}");
      print("📝 Script: ${_scriptController.text.trim()}");
      print("👤 Avatar ID: $avatarId");

      final result = await ApiService.createVideo(
        avatarId: avatarId,
        title: _titleController.text.trim(),
        script: _scriptController.text.trim(),
        aspectRatio: _selectedAspectRatio,
        expression: _selectedExpression,
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
}
