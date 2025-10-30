import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_gen_app/Component/project_card.dart';
import 'package:video_gen_app/Utils/video_download_helper.dart';
import 'package:video_gen_app/Screens/Avatar/create_avatar.dart';
import 'package:video_gen_app/Screens/Project/project_screen.dart';
import 'package:video_gen_app/Screens/Project/project_detail_screen.dart';
import 'package:video_gen_app/Screens/Video/create_video.dart';
import 'package:video_gen_app/Screens/Avatar/my_avatars_screen.dart';
import 'package:video_gen_app/Services/dashboard_service.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Services/project_status_service.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/dashboard_card.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/chewie_video_dialog.dart';
import 'package:video_gen_app/Services/payment_service.dart';

class DashboardScreen extends StatefulWidget {
  final bool showAppBar;

  const DashboardScreen({super.key, this.showAppBar = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Add state for section selection
  String _selectedSection = 'projects'; // 'projects' or 'credits'

  // Real data state variables
  Map<String, dynamic> _dashboardStats = {
    'totalAvatars': 0,
    'totalProjects': 0,
    'completedProjects': 0,
    'availableCredits': 0, // New users start with 0 credits
    'totalTimeSaved': '0h', // New users haven't saved time yet
    'creditsPurchased': 0,
    'creditsUsed': 0,
    'totalTransactions': 0,
    'userName': '',
    'userEmail': '',
    'userPlan': 'free',
    'isEmailVerified': false,
  };

  List<Map<String, dynamic>> _recentProjects = [];
  List<Map<String, dynamic>> _paymentHistory = [];

  bool _isLoadingStats = true;
  bool _isLoadingProjects = true;
  bool _isLoadingPayments = true;
  String _errorMessage = '';

  // GlobalKeys for sections
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _creditsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // Initialize project status notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProjectNotificationService().initialize(context);
    });
  }

  @override
  void dispose() {
    ProjectNotificationService().dispose();
    super.dispose();
  }

  // Load all dashboard data
  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadRecentProjects(),
      _loadPaymentHistory(),
    ]);
  }

  // Load dashboard statistics
  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        _isLoadingStats = true;
        _errorMessage = '';
      });

      final stats = await DashboardService.getDashboardStats();

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _errorMessage = 'Failed to load dashboard stats';
        });
      }
      print('Error loading dashboard stats: $e');
    }
  }

  // Load recent projects
  Future<void> _loadRecentProjects() async {
    try {
      setState(() {
        _isLoadingProjects = true;
      });

      final projects = await DashboardService.getRecentProjects(limit: 4);

      if (mounted) {
        setState(() {
          _recentProjects = projects;
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
        });
      }
      print('Error loading recent projects: $e');
    }
  }

  // Download video using the new production-ready service
  Future<void> _downloadVideo(String videoUrl, String projectTitle) async {
    await VideoDownloadHelper.downloadVideo(
      context: context,
      videoUrl: videoUrl,
      albumName: 'CloneX Videos',
    );
  }

  // Delete project
  Future<void> _deleteProject(String projectId, int index) async {
    try {
      await ApiService.deleteProject(
        projectId,
      ); // Fixed: use deleteProject instead of deleteVideo

      setState(() {
        _recentProjects.removeAt(index);
        // Update stats
        _dashboardStats['totalProjects'] =
            (_dashboardStats['totalProjects'] ?? 1) - 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Project deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error deleting project: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Failed to delete project: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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

  // Load payment history
  Future<void> _loadPaymentHistory() async {
    try {
      setState(() {
        _isLoadingPayments = true;
      });

      final history = await PaymentService.getPaymentHistory();

      if (mounted) {
        setState(() {
          _paymentHistory = history;
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Use dummy data for now until API is set up
          _paymentHistory = [
            {
              'createdAt': '2025-10-10T10:00:00Z',
              'planType': 'starter',
              'amount': 24.99,
              'creditsPurchased': 1300,
              'status': 'completed',
            },
            {
              'createdAt': '2025-10-08T15:30:00Z',
              'planType': 'basic',
              'amount': 9.99,
              'creditsPurchased': 500,
              'status': 'completed',
            },
          ];
          _isLoadingPayments = false;
        });
      }
      print('Error loading payment history: $e');
    }
  }

  // Safe dialog dismissal to prevent black screen issues
  void _safePopDialog() {
    try {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      print('Error closing dialog: $e');
    }
  }

  // Purchase plan method - Real Play Store Integration
  Future<void> _purchasePlan(String planId, String price, int credits) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkGreyColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.blueColor),
              const SizedBox(height: 16),
              const Text(
                'Initializing purchase...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Add safety timeout for dialog
      Future.delayed(const Duration(seconds: 10), () {
        _safePopDialog();
      });

      // Initialize in-app purchases
      final isAvailable = await PaymentService.initializeInAppPurchase();

      if (!isAvailable) {
        _safePopDialog();
        _showError('In-app purchases are not available on this device');
        return;
      }

      // Start the purchase process
      final success = await PaymentService.purchasePlan(
        planId: planId,
        onSuccess: (message) async {
          // Close loading dialog
          _safePopDialog();

          // Refresh dashboard data
          await _loadDashboardData();

          // Show success message
          _showSuccess(message, credits);
        },
        onError: (error) {
          // Close loading dialog
          _safePopDialog();

          // Show error message
          _showError(error);
        },
      );

      // If purchase couldn't be initiated
      if (!success) {
        _safePopDialog();
        _showError('Failed to initiate purchase. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still open
      _safePopDialog();

      print('Error purchasing plan: $e');
      _showError('Purchase failed: ${e.toString()}');
    }
  }

  // Show success message after purchase
  void _showSuccess(String message, int credits) {
    if (mounted) {
      // Add new transaction to payment history
      setState(() {
        _paymentHistory.insert(0, {
          'createdAt': DateTime.now().toIso8601String(),
          'planType': 'purchased',
          'amount': 0.0, // Will be updated from backend
          'creditsPurchased': credits,
          'status': 'completed',
        });
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Show error message if purchase fails
  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? "User";
    // Use backend userName if available, otherwise fallback to Firebase
    final backendUserName = _dashboardStats['userName']?.toString() ?? '';
    final userName = backendUserName.isNotEmpty
        ? backendUserName.split(' ').first
        : fullName.split(' ').first; // Get only first name

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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3A3A4E),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFF8F9FA),
                      child: user?.photoURL != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoURL!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.blueColor,
                                            AppColors.purpleColor,
                                          ],
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.blueColor,
                                    AppColors.purpleColor,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
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

                          return _isLoadingStats
                              ? SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.purpleColor,
                                    ),
                                  ),
                                )
                              : _errorMessage.isNotEmpty
                              ? SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          _errorMessage,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: isTablet ? 16 : 12,
                                  mainAxisSpacing: isTablet ? 16 : 12,
                                  childAspectRatio: childAspectRatio,
                                  children: [
                                    DashboardCard(
                                      title: "Credits",
                                      value:
                                          _dashboardStats['availableCredits']
                                              ?.toString() ??
                                          "0",
                                      imagePath: "images/credit-icon.png",
                                    ),
                                    DashboardCard(
                                      title: "Total Projects",
                                      value:
                                          _dashboardStats['totalProjects']
                                              ?.toString() ??
                                          "0",
                                      imagePath: "images/project-icon.png",
                                    ),
                                    DashboardCard(
                                      title: "Completed",
                                      value:
                                          _dashboardStats['completedProjects']
                                              ?.toString() ??
                                          "0",
                                      imagePath: "images/completed-icon.png",
                                    ),
                                    DashboardCard(
                                      title: "Time Saved",
                                      value:
                                          _dashboardStats['totalTimeSaved']
                                              ?.toString() ??
                                          "0h",
                                      imagePath: "images/timer-icon.png",
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
                                    ProjectsScreen(),
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
                        _isLoadingProjects
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _recentProjects.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(40),
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.video_library_outlined,
                                        size: 64,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No projects yet",
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Create your first video to get started",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;

                                  // decide how many columns based on screen width
                                  int crossAxisCount =
                                      2; // default for small screens
                                  if (width > 600) {
                                    crossAxisCount = 3; // tablet
                                  }
                                  if (width > 900) {
                                    crossAxisCount = 4; // desktop
                                  }

                                  return GridView.builder(
                                    // so it doesn’t try to expand infinitely inside another scrollable
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio:
                                              0.8, // adjust height vs width of card
                                        ),
                                    itemCount: _recentProjects.length,
                                    itemBuilder: (context, index) {
                                      final project = _recentProjects[index];
                                      // For avatar-based projects, use avatar image instead of thumbnail
                                      String imagePath =
                                          "images/project-card.png";
                                      if (project['type'] == 'avatar-based' &&
                                          project['avatarId'] != null &&
                                          project['avatarId']['imageUrl'] !=
                                              null) {
                                        imagePath =
                                            project['avatarId']['imageUrl'];
                                      } else if (project['thumbnailUrl'] !=
                                              null &&
                                          project['thumbnailUrl']
                                              .toString()
                                              .isNotEmpty) {
                                        imagePath = project['thumbnailUrl'];
                                      }

                                      return ProjectCard(
                                        title: project['title'] ?? 'Untitled',
                                        createdDate:
                                            DashboardService.formatDate(
                                              project['createdAt'] ?? '',
                                            ),
                                        duration:
                                            DashboardService.formatDuration(
                                              project['duration'],
                                            ),
                                        imagePath: imagePath,
                                        status: project['status'] ?? 'unknown',
                                        prompt: project['description'],
                                        projectId:
                                            project['_id'] ?? project['id'],
                                        videoUrl:
                                            project['videoUrl'], // Add Cloudinary video URL
                                        onTap: () {
                                          final projectId =
                                              project['_id'] ?? project['id'];
                                          print(
                                            '🔍 Dashboard Project ID: $projectId',
                                          );
                                          print(
                                            '🔍 Dashboard Project Data: ${project.keys}',
                                          );
                                          print(
                                            '🔍 Dashboard Project _id: ${project['_id']}',
                                          );
                                          print(
                                            '🔍 Dashboard Project id: ${project['id']}',
                                          );

                                          if (projectId != null &&
                                              projectId.toString().isNotEmpty) {
                                            navigateWithAnimation(
                                              context,
                                              ProjectDetailScreen(
                                                projectId: projectId.toString(),
                                                initialProject: project,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Unable to open project details. Invalid project ID.',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        onPlay: () {
                                          final videoUrl = project['videoUrl'];
                                          if (videoUrl != null &&
                                              videoUrl.isNotEmpty) {
                                            // Open video player dialog
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  ChewieVideoDialog(
                                                    videoUrl: videoUrl,
                                                    title: 'Generated Video',
                                                  ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Video not ready yet',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        onDownload: () async {
                                          final videoUrl = project['videoUrl'];
                                          if (videoUrl != null &&
                                              videoUrl.isNotEmpty) {
                                            await _downloadVideo(
                                              videoUrl,
                                              project['title'] ?? 'video',
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Video not ready for download',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        onDelete: () async {
                                          // Show confirmation dialog
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor:
                                                  AppColors.darkGreyColor,
                                              title: const Text(
                                                'Delete Project',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete "${project['title']}"?',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            // Use the correct ID field - try _id first, then fallback to id
                                            final projectId =
                                                project['_id'] ?? project['id'];
                                            if (projectId != null) {
                                              await _deleteProject(
                                                projectId,
                                                index,
                                              );
                                            }
                                          }
                                        },
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

                            return _isLoadingStats
                                ? SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.purpleColor,
                                      ),
                                    ),
                                  )
                                : GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: isTablet ? 16 : 12,
                                    mainAxisSpacing: isTablet ? 16 : 12,
                                    childAspectRatio: childAspectRatio,
                                    children: [
                                      DashboardCard(
                                        title: "Credits Purchased",
                                        value:
                                            _dashboardStats['creditsPurchased']
                                                ?.toString() ??
                                            "0",
                                        imagePath: "images/credit-icon.png",
                                      ),
                                      DashboardCard(
                                        title: "Credits Used",
                                        value:
                                            _dashboardStats['creditsUsed']
                                                ?.toString() ??
                                            "0",
                                        imagePath: "images/project-icon.png",
                                      ),
                                      DashboardCard(
                                        title: "Total Transactions",
                                        value:
                                            _dashboardStats['totalTransactions']
                                                ?.toString() ??
                                            _paymentHistory.length.toString(),
                                        imagePath: "images/completed-icon.png",
                                      ),
                                      DashboardCard(
                                        title: "Total Spent",
                                        value:
                                            "\$${_dashboardStats['totalSpent']?.toString() ?? "0"}",
                                        imagePath: "images/money-icon.png",
                                      ),
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

                        // Credit Packages - 2x2 Grid Layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet =
                                MediaQuery.of(context).size.width > 600;

                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isTablet ? 0.9 : 0.8,
                              children: [
                                _buildCreditPackage(
                                  "Basic",
                                  "\$9.99",
                                  "500 credits\n1 Text-to-Video\n5 Avatar Videos",
                                  false,
                                  "basic",
                                  500,
                                ),
                                _buildCreditPackage(
                                  "Starter",
                                  "\$24.99",
                                  "1,300 credits\n3 Text-to-Videos\n10 Avatar Videos",
                                  true,
                                  "starter",
                                  1300,
                                ),
                                _buildCreditPackage(
                                  "Pro",
                                  "\$69.99",
                                  "4,000 credits\n10 Text-to-Videos\n25 Avatar Videos",
                                  false,
                                  "pro",
                                  4000,
                                ),
                                _buildCreditPackage(
                                  "Business",
                                  "\$149.99",
                                  "9,000 credits\n25 Text-to-Videos\n50 Avatar Videos",
                                  false,
                                  "business",
                                  9000,
                                ),
                              ],
                            );
                          },
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
                              if (_isLoadingPayments)
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(),
                                )
                              else if (_paymentHistory.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    "No payment history yet",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              else
                                ..._paymentHistory
                                    .take(5)
                                    .map(
                                      (payment) => _buildPaymentHistoryItem(
                                        _capitalizeFirst(
                                          payment['planType'] ?? 'Unknown',
                                        ),
                                        "\$${payment['amount']?.toString() ?? '0.00'}",
                                        payment['creditsPurchased']
                                                ?.toString() ??
                                            '0',
                                        _capitalizeFirst(
                                          payment['status'] ?? 'Unknown',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format date
  // Helper method to capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _buildCreditPackage(
    String title,
    String price,
    String description,
    bool isPopular,
    String planId,
    int credits,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: AppColors.blueColor, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? AppColors.blueColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and popular badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Popular",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Price
          Text(
            price,
            style: TextStyle(
              color: AppColors.blueColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 4,
            ),
          ),

          const SizedBox(height: 12),

          // Credits badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.blueColor.withOpacity(0.3)),
            ),
            child: Text(
              "$credits Credits",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blueColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Buy button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _purchasePlan(planId, price, credits),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? AppColors.blueColor
                    : AppColors.purpleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                "Buy Now",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
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
            flex: 3,
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
            flex: 3,
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
      case 'failed':
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
            flex: 3,
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
            flex: 3,
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
