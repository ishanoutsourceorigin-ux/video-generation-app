import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Video/my_videos_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';

class TextBasedVideoScreen extends StatefulWidget {
  const TextBasedVideoScreen({super.key});

  @override
  State<TextBasedVideoScreen> createState() => _TextBasedVideoScreenState();
}

class _TextBasedVideoScreenState extends State<TextBasedVideoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedAspectRatio = '9:16';
  String _selectedResolution = '1080';
  String _selectedDuration = '8';
  bool _withAudio = true;
  bool _withSubtitles = true;
  bool _isGenerating = false;

  final List<Map<String, String>> _aspectRatios = [
    {'label': 'Square (1:1)', 'value': '1:1'},
    {'label': 'Vertical (9:16)', 'value': '9:16'},
    {'label': 'Vertical (16:19)', 'value': '16:19'},
    {'label': 'Portrait (3:4)', 'value': '3:4'},
  ];

  final List<Map<String, String>> _resolutions = [
    {'label': '720p', 'value': '720'},
    {'label': '1080p', 'value': '1080'},
  ];

  final List<Map<String, String>> _durations = [
    {'label': '4 seconds', 'value': '4'},
    {'label': '8 seconds', 'value': '8'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          "Text-Based Video",
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
              const Text(
                "Generate a video from text description using AI",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Video Title
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
                hint: "Enter video title (e.g., Product Introduction)",
                textEditingController: _titleController,
                inputType: TextInputType.text,
                bgColor: AppColors.darkGreyColor,
                enabledBorderColor: AppColors.greyColor.withOpacity(0.3),
                focusedBorderColor: AppColors.purpleColor,
              ),
              const SizedBox(height: 24),

              // Video Description
              const Text(
                "Video Description",
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
                  controller: _descriptionController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        "Describe what you want to create...\n\nExample:\nCreate a professional product introduction video showcasing our new smartphone. Highlight the camera quality, battery life, and sleek design. Include smooth transitions and modern graphics.",
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
                "Describe the video content, style, and key points you want to include",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Video Configuration Section
              const Text(
                "Video Configuration",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Aspect Ratio Selection
              const Text(
                "Aspect Ratio",
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
                        value: ratio['value'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(ratio['label']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Resolution Selection
              const Text(
                "Resolution",
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
                    value: _selectedResolution,
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
                          _selectedResolution = newValue;
                        });
                      }
                    },
                    items: _resolutions.map<DropdownMenuItem<String>>((
                      resolution,
                    ) {
                      return DropdownMenuItem<String>(
                        value: resolution['value'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(resolution['label']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Duration Selection
              const Text(
                "Duration",
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
                    value: _selectedDuration,
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
                          _selectedDuration = newValue;
                        });
                      }
                    },
                    items: _durations.map<DropdownMenuItem<String>>((duration) {
                      return DropdownMenuItem<String>(
                        value: duration['value'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(duration['label']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Audio & Features Section
              const Text(
                "Audio & Features",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Audio Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greyColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: _withAudio ? AppColors.purpleColor : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Include Audio",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _withAudio,
                      onChanged: (value) {
                        setState(() {
                          _withAudio = value;
                        });
                      },
                      activeColor: AppColors.purpleColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Subtitles Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greyColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.subtitles,
                      color: _withSubtitles
                          ? AppColors.purpleColor
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Include Subtitles",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _withSubtitles,
                      onChanged: (value) {
                        setState(() {
                          _withSubtitles = value;
                        });
                      },
                      activeColor: AppColors.purpleColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Generate Button
              RoundButton(
                title: _isGenerating ? "Generating Video..." : "Generate Video",
                onPress: _isGenerating ? () {} : _generateTextBasedVideo,
                leadingIcon: _isGenerating ? null : Icons.play_circle_fill,
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
                    AnimatedPageRoute(page: const MyVideosScreen()),
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
                          "AI Video Generation",
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
                      "• AI will generate video content based on your description\n"
                      "• Generation typically takes 1-3 minutes\n"
                      "• Video quality depends on description detail\n"
                      "• You'll receive a notification when ready",
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

  Future<void> _generateTextBasedVideo() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError("Please enter a video title");
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError("Please enter a video description");
      return;
    }

    final duration = int.parse(_selectedDuration);

    setState(() {
      _isGenerating = true;
    });

    try {
      print("🎬 Starting text-based video generation...");
      print("📹 Title: ${_titleController.text.trim()}");
      print("📝 Description: ${_descriptionController.text.trim()}");
      print("⏱️ Duration: $duration seconds");
      print("📏 Aspect Ratio: $_selectedAspectRatio");
      print("📱 Resolution: ${_selectedResolution}p");
      print("🔊 With Audio: $_withAudio");
      print("📝 With Subtitles: $_withSubtitles");

      // Call backend API for text-based video generation
      final result = await ApiService.createTextBasedVideo(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        style: 'default',
        voice: 'default',
        duration: duration,
        aspectRatio: _selectedAspectRatio,
        resolution: int.parse(_selectedResolution),
        withAudio: _withAudio,
        withSubtitles: _withSubtitles,
        withLipSync: false,
      );

      print("✅ Text-based video generation started: $result");

      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "AI video generation started! You'll be notified when it's ready.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate to videos screen
      Navigator.pushReplacement(
        context,
        AnimatedPageRoute(page: const MyVideosScreen()),
      );
    } catch (e) {
      print("❌ Error generating text-based video: $e");
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
