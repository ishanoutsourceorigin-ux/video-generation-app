import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Screens/Video/text_based_video_screen.dart';
import 'package:video_gen_app/Screens/Avatar/my_avatars_screen.dart';

class CreateVideo extends StatefulWidget {
  final bool showAppBar;

  const CreateVideo({super.key, this.showAppBar = true});

  @override
  State<CreateVideo> createState() => _CreateVideoState();
}

class _CreateVideoState extends State<CreateVideo> {
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
              const Text(
                "Video Generator",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose how you want to create your video",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Text-Based Video Option
              _buildVideoOption(
                imagePath: "images/text-icon.png",
                iconColor: AppColors.purpleColor,
                title: "Text-Based Video",
                subtitle: "Generate video from text description",
                onTap: () {
                  Navigator.push(
                    context,
                    AnimatedPageRoute(page: const TextBasedVideoScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Avatar Video Option
              _buildVideoOption(
                imagePath: "images/avatar-icon.png",
                iconColor: AppColors.purpleColor,
                title: "Avatar Video",
                subtitle: "Use your AI Avatar to speak your script",
                onTap: () {
                  Navigator.push(
                    context,
                    AnimatedPageRoute(page: const MyAvatarsScreen()),
                  );
                },
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imagePath,
                  width: 40,
                  height: 40,

                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image not found
                    return Icon(
                      title.contains("Text") ? Icons.text_fields : Icons.person,
                      color: iconColor,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
