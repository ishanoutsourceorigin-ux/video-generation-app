import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_gen_app/Component/project_card.dart';
import 'package:video_gen_app/Screens/Auth/login_screen.dart';
import 'package:video_gen_app/Screens/Avatar/create_avatar.dart';
import 'package:video_gen_app/Screens/Project/project_screen.dart';
import 'package:video_gen_app/Screens/Video/create_video.dart';
import 'package:video_gen_app/Screens/my_avatars_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/utils.dart';
import 'package:video_gen_app/Component/dashboard_card.dart';
import 'package:video_gen_app/Component/round_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Add state for section selection
  String _selectedSection = 'projects'; // 'projects' or 'credits'

  // ScrollController for navigation

  // GlobalKeys for sections
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _creditsKey = GlobalKey();

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Utils.flushBarErrorMessage('Logout Successfully', context, success: true);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      Utils.flushBarErrorMessage('Logout failed: $e', context);
    }
  }

  // Method to scroll to projects section
  void _scrollToProjects() {
    setState(() {
      _selectedSection = 'projects';
    });
    final context = _projectsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  // Method to scroll to credits section
  void _scrollToCredits() {
    setState(() {
      _selectedSection = 'credits';
    });
    final context = _creditsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? "User";
    final userName = fullName.split(' ').first; // Get only first name

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: AppColors.appBgColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Welcome Back, $userName",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Eurostile",
                          ),
                        ),
                        const Text(
                          "Ready to create amazing content",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _logout,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.blueColor,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet =
                            MediaQuery.of(context).size.width > 600;
                        final isLandscape =
                            MediaQuery.of(context).orientation ==
                            Orientation.landscape;

                        // Responsive grid configuration
                        int crossAxisCount = 2;
                        double childAspectRatio = 1.5;

                        if (isTablet) {
                          crossAxisCount = isLandscape ? 4 : 3;
                          childAspectRatio = isLandscape ? 1.2 : 1.3;
                        } else if (isLandscape) {
                          crossAxisCount = 3;
                          childAspectRatio = 1.8;
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isTablet ? 16 : 12,
                          mainAxisSpacing: isTablet ? 16 : 12,
                          childAspectRatio: childAspectRatio,
                          children: [
                            DashboardCard(
                              title: "Available Credits",
                              value: "05",
                              imagePath:
                                  "images/credit-icon.png", // Purple tick icon
                            ),
                            DashboardCard(
                              title: "Total Projects",
                              value: "12",
                              imagePath:
                                  "images/project-icon.png", // Yellow lightbulb icon
                            ),
                            DashboardCard(
                              title: "Completed",
                              value: "05",
                              imagePath:
                                  "images/completed-icon.png", // Dollar sign icon
                            ),
                            DashboardCard(
                              title: "Total Spent",
                              value: "\$85",
                              imagePath: "images/money-icon.png", // Money icon
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: RoundButton(
                            title: "My Avatars",

                            onPress: () {
                              navigateWithAnimation(
                                context,
                                const MyAvatarsScreen(),
                              );
                            },
                            bgColor: AppColors.darkGreyColor,
                            borderRadius: 10,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RoundButton(
                            title: "Create Avatar",
                            onPress: () {
                              navigateWithAnimation(
                                context,
                                const CreateAvatar(),
                              );
                            },
                            bgColor: AppColors.darkGreyColor,
                            borderRadius: 10,
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    RoundButton(
                      title: "Create New Video",
                      onPress: () {
                        navigateWithAnimation(context, const CreateVideo());
                      },
                      leadingIcon: Icons.add,
                      leadingIconColor: Colors.white,
                      bgColor: AppColors.blueColor,
                      borderRadius: 10,
                      fontSize: 19,
                    ),
                    const SizedBox(height: 16),

                    // Secondary Buttons Row 1
                    Row(
                      children: [
                        Expanded(
                          child: RoundButton(
                            title: "Projects",
                            onPress: _scrollToProjects,
                            bgColor: _selectedSection == 'projects'
                                ? AppColors.blueColor
                                : AppColors.darkGreyColor,
                            borderRadius: 10,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RoundButton(
                            title: "Credits",
                            onPress: _scrollToCredits,
                            bgColor: _selectedSection == 'credits'
                                ? AppColors.blueColor
                                : AppColors.darkGreyColor,
                            borderRadius: 10,
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Secondary Buttons Row 2 - Avatar buttons

                    // Your Projects Section
                    if (_selectedSection == 'projects') ...[
                      Container(
                        key: _projectsKey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Your Projects",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                navigateWithAnimation(
                                  context,
                                  const ProjectsScreen(),
                                );
                              },
                              child: Text(
                                "See All",
                                style: TextStyle(
                                  color: AppColors.purpleColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Projects Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;

                          // decide how many columns based on screen width
                          int crossAxisCount = 2; // default for small screens
                          if (width > 600) {
                            crossAxisCount = 3; // tablet
                          }
                          if (width > 900) {
                            crossAxisCount = 4; // desktop
                          }

                          return GridView.builder(
                            // so it doesn’t try to expand infinitely inside another scrollable
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      0.8, // adjust height vs width of card
                                ),
                            itemCount: 4, // your items
                            itemBuilder: (context, index) {
                              return ProjectCard(
                                title: "Demo $index",
                                createdDate: "9/08/25",
                                duration: "0:08",
                                imagePath: "images/project-card.png",
                                onPlay: () => print("Play $index"),

                                onDownload: () => print("Download $index"),
                                onDelete: () => print("Delete $index"),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Payments & Credits Section
                    if (_selectedSection == 'credits') ...[
                      Container(
                        key: _creditsKey,
                        child: const Text(
                          "Payments & Credits",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Stats Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet =
                              MediaQuery.of(context).size.width > 600;
                          final isLandscape =
                              MediaQuery.of(context).orientation ==
                              Orientation.landscape;

                          // Responsive grid configuration
                          int crossAxisCount = 2;
                          double childAspectRatio = 1.5;

                          if (isTablet) {
                            crossAxisCount = isLandscape ? 4 : 3;
                            childAspectRatio = isLandscape ? 1.2 : 1.3;
                          } else if (isLandscape) {
                            crossAxisCount = 3;
                            childAspectRatio = 1.8;
                          }

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: isTablet ? 16 : 12,
                            mainAxisSpacing: isTablet ? 16 : 12,
                            childAspectRatio: childAspectRatio,
                            children: [
                              DashboardCard(
                                title: "Credits Purchased",
                                value: "105",
                                imagePath:
                                    "images/credit-icon.png", // Purple tick icon
                              ),
                              DashboardCard(
                                title: "Credits Used",
                                value: "75",
                                imagePath:
                                    "images/project-icon.png", // Yellow lightbulb icon
                              ),
                              DashboardCard(
                                title: "Total Transactions",
                                value: "05",
                                imagePath:
                                    "images/completed-icon.png", // Dollar sign icon
                              ),
                              // DashboardCard(
                              //   title: "Total Spent",
                              //   value: "\$85",
                              //   imagePath: "images/money-icon.png", // Money icon
                              // ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Buy More Credits
                      const Text(
                        "Buy More Credits",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Need more credits to create videos? Choose from our credit packages:",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Credit Packages
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                        children: [
                          _buildCreditPackage(
                            "Basic Pack",
                            "\$10",
                            "5 video credits",
                            false,
                          ),
                          _buildCreditPackage(
                            "Pro Pack",
                            "\$25",
                            "20 video credits",
                            true,
                          ),
                          _buildCreditPackage(
                            "Business Pack",
                            "\$55",
                            "50 video credits",
                            false,
                          ),
                          _buildCreditPackage(
                            "Premium Pack",
                            "\$810",
                            "100 video credits",
                            false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Payment History
                      const Text(
                        "Payment History",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment History List
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildPaymentHistoryHeader(),
                            _buildPaymentHistoryItem(
                              "3 days ago",
                              "Basic",
                              "\$10.00",
                              "40",
                              "Paid",
                            ),
                            _buildPaymentHistoryItem(
                              "8 minutes ago",
                              "Pro",
                              "\$25.00",
                              "130",
                              "Paid",
                            ),
                            _buildPaymentHistoryItem(
                              "1 day ago",
                              "Basic",
                              "\$10.00",
                              "40",
                              "Pending",
                            ),
                            _buildPaymentHistoryItem(
                              "EFEFEAL",
                              "Basic",
                              "\$10.00",
                              "40",
                              "Unpaid",
                            ),
                            _buildPaymentHistoryItem(
                              "EFEFEAL",
                              "Basic",
                              "\$10.00",
                              "40",
                              "Unpaid",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF2A2D3A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(Icons.info_outline, "About", 0),
            _buildBottomNavItem(Icons.video_camera_back, "Video Generator", 1),
            _buildBottomNavItem(Icons.create, "Create New", 2),
            _buildBottomNavItem(Icons.folder_outlined, "Projects", 3),
            _buildBottomNavItem(Icons.settings_outlined, "Settings", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.purple : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPackage(
    String title,
    String price,
    String description,
    bool isPopular,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(12),
        border: isPopular
            ? Border.all(color: AppColors.darkBlueColor, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blueColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Popular",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              // fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleColor,
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Choose Plan", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Date",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Plan",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Amount",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Credits",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Status",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(
    String date,
    String plan,
    String amount,
    String credits,
    String status,
  ) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'unpaid':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              plan,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              credits,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
