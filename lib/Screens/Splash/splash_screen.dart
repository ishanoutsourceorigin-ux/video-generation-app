import 'package:flutter/material.dart';
import 'package:video_gen_app/Services/splash_services.dart';
import 'package:video_gen_app/Utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      SplashServices().checkAppStartState(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Image
              ClipOval(
                child: Image.asset(
                  "images/logo.png",
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 50),

              // App Name
              const Text(
                'CloneX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              // Tagline
              const Text(
                'Your Digital Twin, Powered by AI',
                style: TextStyle(
                  color: Color(0xFF9CA3AF), // Light gray
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Get Started Button
              // Container(
              //   width: 200,
              //   height: 56,
              //   decoration: BoxDecoration(
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              //       begin: Alignment.centerLeft,
              //       end: Alignment.centerRight,
              //     ),
              //     borderRadius: BorderRadius.circular(28),
              //   ),
              //   child: Material(
              //     color: Colors.transparent,
              //     child: InkWell(
              //       borderRadius: BorderRadius.circular(28),
              //       onTap: () {},
              //       child: const Center(
              //         child: Text(
              //           'Get Started',
              //           style: TextStyle(
              //             color: Colors.white,
              //             fontSize: 18,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
