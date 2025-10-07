import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Video/completed_videos_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';

class Veo3VideoScreen extends StatefulWidget {
  const Veo3VideoScreen({super.key});

  @override
  State<Veo3VideoScreen> createState() => _Veo3VideoScreenState();
}

class _Veo3VideoScreenState extends State<Veo3VideoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _seedController = TextEditingController();

  String _selectedRatio = '1280:720'; // VEO-3 specific ratios
  int _selectedDuration = 8; // VEO-3 max duration
  bool _isGenerating = false;

  // VEO-3 specific ratio options
  final List<Map<String, String>> _veo3Ratios = [
    {'label': 'Landscape (1280:720)', 'value': '1280:720'},
    {'label': 'Portrait (720:1280)', 'value': '720:1280'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _seedController.dispose();
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
          "VEO-3 AI Video",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purpleColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purpleColor),
            ),
            child: Text(
              'VEO-3',
              style: TextStyle(
                color: AppColors.purpleColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with VEO-3 badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "VEO-3 Video Generation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Advanced AI video generation with VEO-3 model",
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // VEO-3 Features Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purpleColor.withValues(alpha: 0.1),
                      AppColors.blueColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.purpleColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.purpleColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "VEO-3 Model Features",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "• Maximum 8-second video duration\n"
                      "• 720p resolution (1280x720 or 720x1280)\n"
                      "• Advanced prompt understanding\n"
                      "• Custom seed for reproducible results\n"
                      "• Optimized for professional quality",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
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
                hint: "Enter a descriptive title for your VEO-3 video",
                textEditingController: _titleController,
                inputType: TextInputType.text,
                bgColor: AppColors.darkGreyColor,
                enabledBorderColor: AppColors.greyColor.withValues(alpha: 0.3),
                focusedBorderColor: AppColors.purpleColor,
              ),
              const SizedBox(height: 24),

              // Prompt Text
              const Text(
                "Video Prompt",
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
                  maxLines: 4,
                  maxLength: 1000, // VEO-3 prompt limit
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        "Describe your video in detail...\n\n"
                        "Example:\n"
                        "A cinematic shot of a futuristic city at sunset, with flying cars and neon lights reflecting off glass buildings. Camera slowly pans across the skyline.",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "VEO-3 works best with detailed, cinematic descriptions (max 1000 characters)",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // VEO-3 Configuration Section
              const Text(
                "VEO-3 Configuration",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Video Ratio Selection (VEO-3 specific)
              const Text(
                "Video Ratio",
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
                    value: _selectedRatio,
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
                          _selectedRatio = newValue;
                        });
                      }
                    },
                    items: _veo3Ratios.map<DropdownMenuItem<String>>((ratio) {
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

              // Duration Slider (VEO-3 max 8 seconds)
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Duration:",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          "$_selectedDuration seconds",
                          style: TextStyle(
                            color: AppColors.purpleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.purpleColor,
                        inactiveTrackColor: AppColors.greyColor.withValues(alpha: 0.3,
                        ),
                        thumbColor: AppColors.purpleColor,
                        overlayColor: AppColors.purpleColor.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      child: Slider(
                        value: _selectedDuration.toDouble(),
                        min: 1,
                        max: 8, // VEO-3 maximum
                        divisions: 7,
                        onChanged: (double value) {
                          setState(() {
                            _selectedDuration = value.round();
                          });
                        },
                      ),
                    ),
                    Text(
                      "VEO-3 supports 1-8 second videos",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Seed Input (Optional)
              const Text(
                "Seed (Optional)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RoundTextField(
                label: "Seed",
                hint: "Enter seed number for reproducible results",
                textEditingController: _seedController,
                inputType: TextInputType.number,
                bgColor: AppColors.darkGreyColor,
                enabledBorderColor: AppColors.greyColor.withValues(alpha: 0.3),
                focusedBorderColor: AppColors.purpleColor,
              ),
              const SizedBox(height: 8),
              Text(
                "Leave empty for random generation, or use a number to reproduce results",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 40),

              // Generate Button
              RoundButton(
                title: _isGenerating
                    ? "Generating with VEO-3..."
                    : "Generate VEO-3 Video",
                onPress: _isGenerating ? () {} : _generateVeo3Video,
                leadingIcon: _isGenerating ? null : Icons.auto_awesome,
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
                    AnimatedPageRoute(page: const CompletedVideosScreen()),
                  );
                },
                leadingIcon: Icons.video_library,
                leadingIconColor: Colors.white,
                bgColor: AppColors.darkGreyColor,
                borderRadius: 12,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),

              // VEO-3 Advantages Section
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "VEO-3 Advantages",
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
                      "• Higher quality output than standard models\n"
                      "• Better understanding of complex prompts\n"
                      "• Consistent results with seed values\n"
                      "• Optimized for cinematic content\n"
                      "• Professional-grade video generation",
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

  Future<void> _generateVeo3Video() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError("Please enter a video title");
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      _showError("Please enter a video prompt");
      return;
    }

    // Parse seed if provided
    int? seed;
    if (_seedController.text.trim().isNotEmpty) {
      try {
        seed = int.parse(_seedController.text.trim());
      } catch (e) {
        _showError("Seed must be a valid number");
        return;
      }
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      print("🎯 === STARTING VEO-3 VIDEO GENERATION ===");
      print("📋 VEO-3 form validation passed");
      print("📹 Title: '${_titleController.text.trim()}'");
      print("📝 Prompt: '${_promptController.text.trim()}'");
      print("⏱️ Duration: $_selectedDuration seconds");
      print("📏 Ratio: $_selectedRatio");
      print("🎲 Seed: ${seed ?? 'random'}");
      print("🌐 Calling VEO-3 API service...");

      // Call VEO-3 specific API
      final result = await ApiService.createVeo3Video(
        title: _titleController.text.trim(),
        promptText: _promptController.text.trim(),
        duration: _selectedDuration,
        ratio: _selectedRatio,
        seed: seed,
      );

      print("✅ VEO-3 API call successful!");
      print("📋 Result: $result");
      print("🎉 VEO-3 video generation started successfully!");

      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "VEO-3 video generation started! Higher quality results expected.",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      print("🏠 Navigating to videos screen...");
      // Navigate to videos screen
      Navigator.pushReplacement(
        context,
        AnimatedPageRoute(page: const CompletedVideosScreen()),
      );
    } catch (e) {
      print("❌ Error generating VEO-3 video: $e");
      print("❌ Error type: ${e.runtimeType}");
      print("❌ Full error details: ${e.toString()}");
      _showError(
        e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('VEO-3 Error: ', ''),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
      print("🔄 VEO-3 generation process finished, UI updated");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
