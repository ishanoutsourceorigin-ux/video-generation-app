import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Video/avatar_videos_screen.dart';

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
  int _selectedDuration = 5; // Default to 5 seconds
  String _selectedAspectRatio = '9:16'; // Default to portrait for avatars

  final List<Map<String, dynamic>> _durations = [
    {'label': '5 seconds', 'value': 5},
    {'label': '10 seconds', 'value': 10},
  ];

  final List<Map<String, dynamic>> _aspectRatios = [
    {'label': 'Portrait (9:16) - 720x1280px', 'value': '9:16'},
    {'label': 'Landscape (16:9) - 1280x720px', 'value': '16:9'},
    {'label': 'Square (1:1) - 960x960px', 'value': '1:1'},
    {'label': 'Standard (4:3) - 1104x832px', 'value': '4:3'},
    {'label': 'Portrait Standard (3:4) - 832x1104px', 'value': '3:4'},
    {'label': 'Ultra-wide (21:9) - 1584x672px', 'value': '21:9'},
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
    print("🔍 Avatar data received: ${widget.avatar}");
    print("📝 Avatar keys: ${widget.avatar.keys.toList()}");

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
                enabledBorderColor: AppColors.greyColor.withOpacity(0.3),
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
                    color: AppColors.greyColor.withOpacity(0.3),
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

              // Duration Selection
              const Text(
                "Video Duration",
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
                    color: AppColors.greyColor.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedDuration,
                    isExpanded: true,
                    dropdownColor: AppColors.darkGreyColor,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDuration = newValue;
                        });
                      }
                    },
                    items: _durations.map<DropdownMenuItem<int>>((duration) {
                      return DropdownMenuItem<int>(
                        value: duration['value'] as int,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(duration['label'] as String),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select video duration (RunwayML gen4_turbo supports 5 or 10 seconds)",
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
                    color: AppColors.greyColor.withOpacity(0.3),
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
                "Choose output resolution and aspect ratio for your avatar video",
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
                    ? AppColors.greyColor.withOpacity(0.5)
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
                    MaterialPageRoute(
                      builder: (context) => const AvatarVideosScreen(),
                    ),
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
                  color: AppColors.blueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.blueColor.withOpacity(0.3),
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
                      "• Video generation typically takes 2-5 minutes\n"
                      "• Your avatar will speak the script using their cloned voice\n"
                      "• The video will be saved to your projects\n"
                      "• You'll receive a notification when it's ready",
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
        duration: _selectedDuration,
        aspectRatio: _selectedAspectRatio,
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
        MaterialPageRoute(builder: (context) => const AvatarVideosScreen()),
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
