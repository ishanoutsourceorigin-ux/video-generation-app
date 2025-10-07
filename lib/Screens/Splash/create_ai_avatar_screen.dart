import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Screens/Auth/login_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';

class CreateAiAvatarScreen extends StatefulWidget {
  const CreateAiAvatarScreen({super.key});

  @override
  State<CreateAiAvatarScreen> createState() => _CreateAiAvatarScreenState();
}

class _CreateAiAvatarScreenState extends State<CreateAiAvatarScreen> {
  PageController pageController = PageController();
  int currentPage = 0;

  final List<OnboardingData> onboardingData = [
    OnboardingData(
      title: "Create your AI avatar in minutes",
      description:
          "upload a short video and let our AI create your digital twin",
      icon: "🤖", // Robot emoji for first screen
      isFirstScreen: true,
    ),
    OnboardingData(
      title: "Create your AI avatar in minutes",
      description:
          "upload a short video and let our AI create your digital twin",
      icon: "💾", // Database/storage icon for second screen
      isFirstScreen: false,
    ),
    OnboardingData(
      title: "Create your AI avatar in minutes",
      description:
          "upload a short video and let our AI create your digital twin",
      icon: "🔒", // Lock icon for third screen
      isFirstScreen: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Icon based on current page
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              child: _buildTopIcon(),
            ),

            // PageView for content
            Expanded(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // const SizedBox(height: 10),

                        // Title
                        Text(
                          onboardingData[index].title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // const SizedBox(height: 20),

                        // Description
                        Text(
                          onboardingData[index].description,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Large Icon/Illustration at bottom
                        Center(child: _buildMainIcon(index)),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom section with dots and button
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentPage == index
                              ? const Color(0xFF6366F1)
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          if (currentPage < onboardingData.length - 1) {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Navigate to login screen
                            navigateWithAnimation(context, const LoginScreen());
                          }
                        },
                        child: Center(
                          child: Text(
                            currentPage == onboardingData.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcon() {
    switch (currentPage) {
      case 0:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            "images/slider-icon-1.png",
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            "images/slider-icon-2.png",
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            "images/slider-icon-3.png",
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildMainIcon(int index) {
    switch (index) {
      case 0:
        // First slider image
        return Image.asset(
          "images/slider-image-1.png",
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      case 1:
        // Second slider image
        return Image.asset(
          "images/slider-image-2.png",
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      case 2:
        // Third slider image
        return Image.asset(
          "images/slider-image-3.png",
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      default:
        return const SizedBox();
    }
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String icon;
  final bool isFirstScreen;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.isFirstScreen,
  });
}
