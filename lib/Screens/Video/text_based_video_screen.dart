import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';
import 'package:video_gen_app/Screens/Video/completed_videos_screen.dart';
import 'package:video_gen_app/Screens/Settings/credit_purchase_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';

class TextBasedVideoScreen extends StatefulWidget {
  const TextBasedVideoScreen({super.key});

  @override
  State<TextBasedVideoScreen> createState() => _TextBasedVideoScreenState();
}

class _TextBasedVideoScreenState extends State<TextBasedVideoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedAspectRatio = '720:1280';
  // String _selectedResolution = '1080';
  String _selectedDuration = '8';
  // bool _withAudio = true;
  // bool _withSubtitles = true;
  bool _isGenerating = false;

  final List<Map<String, String>> _aspectRatios = [
    {'label': 'Landscape (16:9)', 'value': '1280:720'},
    {'label': 'Vertical (9:16)', 'value': '720:1280'},
  ];

  // final List<Map<String, String>> _resolutions = [
  //   {'label': '720p', 'value': '720'},
  //   {'label': '1080p', 'value': '1080'},
  // ];

  // final List<Map<String, String>> _durations = [
  //   {'label': '8 seconds', 'value': '8'}, // VEO-3 only supports 8s
  // ];
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
                enabledBorderColor: AppColors.greyColor.withValues(alpha: 0.3),
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
                    color: AppColors.greyColor.withValues(alpha: 0.3),
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
              // const Text(
              //   "Video Configuration",
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 16),

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

              // // Resolution Selection
              // const Text(
              //   "Resolution",
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Container(
              //   decoration: BoxDecoration(
              //     color: AppColors.darkGreyColor,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(
              //       color: AppColors.greyColor.withValues(alpha: 0.3),
              //     ),
              //   ),
              //   child: DropdownButtonHideUnderline(
              //     child: DropdownButton<String>(
              //       value: _selectedResolution,
              //       isExpanded: true,
              //       dropdownColor: AppColors.darkGreyColor,
              //       style: const TextStyle(color: Colors.white, fontSize: 16),
              //       icon: Icon(
              //         Icons.keyboard_arrow_down,
              //         color: Colors.grey.shade400,
              //       ),
              //       onChanged: (String? newValue) {
              //         if (newValue != null) {
              //           setState(() {
              //             _selectedResolution = newValue;
              //           });
              //         }
              //       },
              //       items: _resolutions.map<DropdownMenuItem<String>>((
              //         resolution,
              //       ) {
              //         return DropdownMenuItem<String>(
              //           value: resolution['value'],
              //           child: Padding(
              //             padding: const EdgeInsets.symmetric(horizontal: 16),
              //             child: Text(resolution['label']!),
              //           ),
              //         );
              //       }).toList(),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),

              // Duration Selection
              // const Text(
              //   "Duration",
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Container(
              //   decoration: BoxDecoration(
              //     color: AppColors.darkGreyColor,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(
              //       color: AppColors.greyColor.withValues(alpha: 0.3),
              //     ),
              //   ),
              //   child: DropdownButtonHideUnderline(
              //     child: DropdownButton<String>(
              //       value: _selectedDuration,
              //       isExpanded: true,
              //       dropdownColor: AppColors.darkGreyColor,
              //       style: const TextStyle(color: Colors.white, fontSize: 16),
              //       icon: Icon(
              //         Icons.keyboard_arrow_down,
              //         color: Colors.grey.shade400,
              //       ),
              //       onChanged: (String? newValue) {
              //         if (newValue != null) {
              //           setState(() {
              //             _selectedDuration = newValue;
              //           });
              //         }
              //       },
              //       items: _durations.map<DropdownMenuItem<String>>((duration) {
              //         return DropdownMenuItem<String>(
              //           value: duration['value'],
              //           child: Padding(
              //             padding: const EdgeInsets.symmetric(horizontal: 16),
              //             child: Text(duration['label']!),
              //           ),
              //         );
              //       }).toList(),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 24),

              // // Audio & Features Section
              // const Text(
              //   "Audio & Features",
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 16),

              // // Audio Toggle
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: AppColors.darkGreyColor,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(
              //       color: AppColors.greyColor.withValues(alpha: 0.3),
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         Icons.volume_up,
              //         color: _withAudio ? AppColors.purpleColor : Colors.grey,
              //         size: 20,
              //       ),
              //       const SizedBox(width: 12),
              //       const Expanded(
              //         child: Text(
              //           "Include Audio",
              //           style: TextStyle(
              //             color: Colors.white,
              //             fontSize: 16,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ),
              //       Switch(
              //         value: _withAudio,
              //         onChanged: (value) {
              //           setState(() {
              //             _withAudio = value;
              //           });
              //         },
              //         activeColor: AppColors.purpleColor,
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 12),

              // // Subtitles Toggle
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: AppColors.darkGreyColor,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(
              //       color: AppColors.greyColor.withValues(alpha: 0.3),
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         Icons.subtitles,
              //         color: _withSubtitles
              //             ? AppColors.purpleColor
              //             : Colors.grey,
              //         size: 20,
              //       ),
              //       const SizedBox(width: 12),
              //       const Expanded(
              //         child: Text(
              //           "Include Subtitles",
              //           style: TextStyle(
              //             color: Colors.white,
              //             fontSize: 16,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ),
              //       Switch(
              //         value: _withSubtitles,
              //         onChanged: (value) {
              //           setState(() {
              //             _withSubtitles = value;
              //           });
              //         },
              //         activeColor: AppColors.purpleColor,
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 40),

              // Generate Button
              RoundButton(
                title: _isGenerating ? "Generating Video..." : "Generate Video",
                onPress: _isGenerating ? () {} : _generateTextBasedVideo,
                leadingIcon: _isGenerating ? null : Icons.play_circle_fill,
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
                      "• Video quality depends on description detail\n",
                      // "• You'll receive a notification when ready",
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
      // CREDIT CHECK: Text-to-video requires 320 credits (fixed cost)
      print("💳 Checking credits for text-to-video generation...");
      const requiredCredits =
          CreditSystemService.textToVideoCredits; // 320 credits

      print("📊 Text-to-video generation");
      print("⏱️ Duration: $duration seconds");
      print("💰 Required credits: $requiredCredits");

      // Check if user has enough credits
      final hasEnoughCredits = await CreditSystemService.hasEnoughCredits(
        videoType: 'text-to-video',
      );

      if (!hasEnoughCredits) {
        print("❌ Insufficient credits for text-to-video generation");
        setState(() {
          _isGenerating = false;
        });
        _showInsufficientCreditsDialog(requiredCredits);
        return;
      }

      print("✅ Credits check passed - user has enough credits");

      // RESERVE CREDITS BEFORE VIDEO GENERATION
      final projectId = 'project-${DateTime.now().millisecondsSinceEpoch}';
      print("💳 NEW CREDIT SYSTEM: Reserving credits for project $projectId...");
      
      final creditsReserved = await CreditSystemService.reserveCredits(
        videoType: 'text-to-video',
        projectId: projectId,
      );

      if (!creditsReserved) {
        print("❌ Failed to reserve credits");
        setState(() {
          _isGenerating = false;
        });
        _showInsufficientCreditsDialog(requiredCredits);
        return;
      }

      print("✅ Credits reserved successfully for project $projectId");
      print("💡 Credits will be automatically confirmed if video succeeds, or refunded if it fails");
      print("🎬 === STARTING TEXT-BASED VIDEO GENERATION ===");
      print("📋 Form validation passed");
      print("📹 Title: '${_titleController.text.trim()}'");
      print("📝 Description: '${_descriptionController.text.trim()}'");
      print("⏱️ Duration: $duration seconds");
      print("📏 Aspect Ratio: $_selectedAspectRatio");
      // print("📱 Resolution: ${_selectedResolution}p");
      print("🚀 Calling API service...");

      // Call backend API for project-based text-based video generation
      final result = await ApiService.createTextBasedProject(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        aspectRatio: _selectedAspectRatio,
        resolution: '720', // Fixed for VEO-3
        duration: '8', // Fixed for VEO-3
        clientProjectId: projectId, // Pass the reserved project ID
      );

      print("✅ API call successful!");
      print("📋 Result: $result");
      print("🎉 Text-based video generation started successfully!");

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

      print("🏠 Navigating to videos screen...");
      // Navigate to videos screen
      Navigator.pushReplacement(
        context,
        AnimatedPageRoute(page: const CompletedVideosScreen()),
      );
    } catch (e) {
      print("❌ Error generating text-based video: $e");
      print("❌ Error type: ${e.runtimeType}");
      print("❌ Full error details: ${e.toString()}");
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _isGenerating = false;
      });
      print("🔄 Generation process finished, UI updated");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInsufficientCreditsDialog(int requiredCredits) {
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
                "You need $requiredCredits credits to generate this AI text-to-video.",
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
                      "💡 Text-to-Video Pricing",
                      style: TextStyle(
                        color: AppColors.blueColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "• $requiredCredits credits per text-to-video\n• High-quality AI-generated videos\n• Professional video content creation",
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
