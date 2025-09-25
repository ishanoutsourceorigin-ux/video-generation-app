import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_gen_app/Component/project_card.dart';
import 'package:video_gen_app/Screens/Avatar/create_avatar.dart';
import 'package:video_gen_app/Screens/Project/project_screen.dart';
import 'package:video_gen_app/Screens/Video/create_video.dart';
import 'package:video_gen_app/Screens/Avatar/my_avatars_screen.dart';
import 'package:video_gen_app/Services/dashboard_service.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/dashboard_card.dart';
import 'package:video_gen_app/Component/round_button.dart';

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
    'availableCredits': 5,
    'totalSpent': 85,
  };

  List<Map<String, dynamic>> _recentProjects = [];
  List<Map<String, dynamic>> _userAvatars = [];

  bool _isLoadingStats = true;
  bool _isLoadingProjects = true;
  String _errorMessage = '';

  // GlobalKeys for sections
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _creditsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Load all dashboard data
  Future<void> _loadDashboardData() async {
    await Future.wait([_loadDashboardStats(), _loadRecentProjects()]);
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

      final projects = await DashboardService.getRecentProjects(limit: 6);

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

  // Delete project
  Future<void> _deleteProject(String projectId, int index) async {
    try {
      await ApiService.deleteVideo(projectId);

      setState(() {
        _recentProjects.removeAt(index);
        // Update stats
        _dashboardStats['totalProjects'] =
            (_dashboardStats['totalProjects'] ?? 1) - 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete project: $e')));
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
                  CircleAvatar(
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
                                child: Column(
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
                                        imagePath:
                                            project['thumbnailUrl'] ??
                                            "images/project-card.png",
                                        status: project['status'] ?? 'unknown',
                                        onPlay: () {
                                          final videoUrl = project['videoUrl'];
                                          if (videoUrl != null &&
                                              videoUrl.isNotEmpty) {
                                            // TODO: Open video player
                                            print('Playing video: $videoUrl');
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Video player will open here',
                                                ),
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
                                        onDownload: () {
                                          final videoUrl = project['videoUrl'];
                                          if (videoUrl != null &&
                                              videoUrl.isNotEmpty) {
                                            // TODO: Download video
                                            print(
                                              'Downloading video: $videoUrl',
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Download will start shortly',
                                                ),
                                              ),
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
                                            await _deleteProject(
                                              project['id'],
                                              index,
                                            );
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
            ),
          ],
        ),
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
