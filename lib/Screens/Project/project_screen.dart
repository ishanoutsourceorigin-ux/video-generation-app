import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Component/project_card.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/chewie_video_dialog.dart';
import 'package:video_gen_app/Models/project_model.dart';
import 'package:video_gen_app/Services/project_service.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Video/create_video.dart';
import 'package:video_gen_app/Screens/Project/project_detail_screen.dart';
import 'package:video_gen_app/Utils/video_download_helper.dart';

class ProjectsScreen extends StatefulWidget {
  final bool showAppBar;

  const ProjectsScreen({super.key, this.showAppBar = true});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, int> _projectStats = {};
  String _selectedFilter = 'all'; // 'all', 'text-based', 'avatar-based'

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadProjectStats();
  }

  // Load projects from service
  Future<void> _loadProjects() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📂 Loading all projects (text-based + avatar)');

      // Load both text-based and avatar-based projects
      final textBasedResponse = await ApiService.getProjects(
        type: 'text-based',
        limit: 100,
        page: 1,
      );

      final avatarBasedResponse = await ApiService.getProjects(
        type: 'avatar-based',
        limit: 100,
        page: 1,
      );

      final List<ProjectModel> allProjects = [];

      // Process text-based projects
      if (textBasedResponse['projects'] != null) {
        final List<dynamic> textProjects =
            textBasedResponse['projects'] as List<dynamic>;
        print('📝 Found ${textProjects.length} text-based projects');
        for (var json in textProjects) {
          try {
            allProjects.add(ProjectModel.fromJson(json));
          } catch (e) {
            print('❌ Error parsing text-based project: $e');
            continue;
          }
        }
      }

      // Process avatar-based projects
      if (avatarBasedResponse['projects'] != null) {
        final List<dynamic> avatarProjects =
            avatarBasedResponse['projects'] as List<dynamic>;
        print('🎭 Found ${avatarProjects.length} avatar-based projects');
        for (var json in avatarProjects) {
          try {
            // print('🔍 Avatar project JSON: $json');
            allProjects.add(ProjectModel.fromJson(json));
          } catch (e) {
            print('❌ Error parsing avatar-based project: $e');
            print('🔍 Failed project JSON: $json');
            continue;
          }
        }
      }

      // Sort by creation date (newest first)
      allProjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('🎯 Total projects loaded: ${allProjects.length}');

      if (mounted) {
        setState(() {
          _projects = allProjects;
          _filteredProjects = _filterProjects(allProjects);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading projects: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Filter projects based on selected filter
  List<ProjectModel> _filterProjects(List<ProjectModel> projects) {
    switch (_selectedFilter) {
      case 'text-based':
        return projects.where((p) => p.type == 'text-based').toList();
      case 'avatar-based':
        return projects.where((p) => p.type == 'avatar-based').toList();
      default:
        return projects;
    }
  }

  // Update filter
  void _updateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filteredProjects = _filterProjects(_projects);
    });
  }

  // Load project statistics
  Future<void> _loadProjectStats() async {
    try {
      final stats = await ProjectService.getProjectStats();
      if (mounted) {
        setState(() {
          _projectStats = stats;
        });
      }
    } catch (e) {
      print('Error loading project stats: $e');
    }
  }

  // Refresh projects
  Future<void> _refreshProjects() async {
    if (!mounted) return;

    try {
      // Load both text-based and avatar-based projects
      final textBasedResponse = await ApiService.getProjects(
        type: 'text-based',
        limit: 100,
        page: 1,
      );

      final avatarBasedResponse = await ApiService.getProjects(
        type: 'avatar-based',
        limit: 100,
        page: 1,
      );

      final List<ProjectModel> allProjects = [];

      // Process text-based projects
      if (textBasedResponse['projects'] != null) {
        final List<dynamic> textProjects =
            textBasedResponse['projects'] as List<dynamic>;
        for (var json in textProjects) {
          try {
            allProjects.add(ProjectModel.fromJson(json));
          } catch (e) {
            print('❌ Error parsing text-based project: $e');
            continue;
          }
        }
      }

      // Process avatar-based projects
      if (avatarBasedResponse['projects'] != null) {
        final List<dynamic> avatarProjects =
            avatarBasedResponse['projects'] as List<dynamic>;
        print(
          '🔄 Refresh: Found ${avatarProjects.length} avatar-based projects',
        );
        for (var json in avatarProjects) {
          try {
            allProjects.add(ProjectModel.fromJson(json));
          } catch (e) {
            print('❌ Refresh: Error parsing avatar-based project: $e');
            print('🔍 Refresh: Failed project JSON: $json');
            continue;
          }
        }
      }

      // Sort by creation date (newest first)
      allProjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _projects = allProjects;
          _filteredProjects = _filterProjects(allProjects);
          _errorMessage = null;
        });
      }

      // Also refresh stats
      _loadProjectStats();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Delete project
  Future<void> _deleteProject(String projectId) async {
    try {
      final success = await ProjectService.deleteProject(projectId);
      if (success && mounted) {
        // Remove from local list
        setState(() {
          _projects.removeWhere((p) => p.id == projectId);
        });

        // Refresh stats
        _loadProjectStats();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Project deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete project: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Play project
  void _playProject(ProjectModel project) {
    if (project.videoUrl != null &&
        project.videoUrl!.isNotEmpty &&
        project.isCompleted) {
      // Open video player dialog
      showDialog(
        context: context,
        builder: (context) => ChewieVideoDialog(
          videoUrl: project.videoUrl!,
          title: project.title,
        ),
      );
    } else if (project.isProcessing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video is still processing. Please wait..."),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video is not ready to play"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Download project using modern VideoDownloadHelper
  Future<void> _downloadProject(ProjectModel project) async {
    if (project.videoUrl != null &&
        project.videoUrl!.isNotEmpty &&
        project.isCompleted) {
      await VideoDownloadHelper.downloadVideo(
        context: context,
        videoUrl: project.videoUrl!,
        fileName: project.title,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video is not ready for download"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    // Responsive padding
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final verticalPadding = isTablet ? 30.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.appBgColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Your Projects",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: isTablet ? 28 : 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      AnimatedPageRoute(page: const CreateVideo()),
                    );
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: widget.showAppBar ? verticalPadding : (isTablet ? 60 : 50),
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "All Projects",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                        Text(
                          "${_projectStats['total'] ?? 0} total projects",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side: Button (responsive)
                  if (isTablet)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          AnimatedPageRoute(page: const CreateVideo()),
                        );
                      },
                      icon: Container(
                        padding: EdgeInsets.all(isTablet ? 12 : 8),
                        decoration: BoxDecoration(
                          color: AppColors.purpleColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: isTablet ? 28 : 24,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: screenSize.width * 0.5,
                      child: RoundButton(
                        title: "New Project",
                        onPress: () {
                          Navigator.push(
                            context,
                            AnimatedPageRoute(page: const CreateVideo()),
                          );
                        },
                        leadingIcon: Icons.add,
                        leadingIconColor: Colors.white,
                        bgColor: AppColors.purpleColor,
                        borderRadius: 12,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: isTablet ? 32 : 24),

              // Filter Section
              // Row(
              //   children: [
              //     Text(
              //       "Filter by Type:",
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: isTablet ? 18 : 16,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: isTablet ? 16 : 12),

              // Filter Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton(
                      title: "All Videos",
                      filterValue: "all",
                      count: _projects.length,
                      isTablet: isTablet,
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    _buildFilterButton(
                      title: "Text Based",
                      filterValue: "text-based",
                      count: _projects
                          .where((p) => p.type == 'text-based')
                          .length,
                      isTablet: isTablet,
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    _buildFilterButton(
                      title: "Avatar Based",
                      filterValue: "avatar-based",
                      count: _projects
                          .where((p) => p.type == 'avatar-based')
                          .length,
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 32 : 24),

              // Projects grid with pull to refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshProjects,
                  color: AppColors.purpleColor,
                  backgroundColor: AppColors.darkGreyColor,
                  child: _buildProjectsGrid(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsGrid() {
    // Show loading state
    if (_isLoading) {
      return _buildLoadingState();
    }

    // Show error state
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // Show empty state if no projects
    if (_filteredProjects.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isLargeTablet = screenWidth > 900;
        final isDesktop = screenWidth > 1200;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // Dynamic grid configuration
        int crossAxisCount = 2; // Default for mobile portrait
        double childAspectRatio = 0.8; // Reduced for more height
        double crossAxisSpacing = 16;
        double mainAxisSpacing = 16;

        if (isDesktop) {
          // Desktop: 5-6 columns
          crossAxisCount = isLandscape ? 6 : 5;
          childAspectRatio = 0.65; // Reduced for more height
          crossAxisSpacing = 20;
          mainAxisSpacing = 20;
        } else if (isLargeTablet) {
          // Large tablet: 4-5 columns
          crossAxisCount = isLandscape ? 5 : 4;
          childAspectRatio = 0.68; // Reduced for more height
          crossAxisSpacing = 18;
          mainAxisSpacing = 18;
        } else if (isTablet) {
          // Regular tablet: 3-4 columns
          crossAxisCount = isLandscape ? 4 : 3;
          childAspectRatio = 0.7; // Reduced for more height
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        } else {
          // Mobile: 2-3 columns
          crossAxisCount = isLandscape ? 3 : 2;
          childAspectRatio = isLandscape
              ? 0.75
              : 0.8; // Reduced for more height
          crossAxisSpacing = isLandscape ? 12 : 16;
          mainAxisSpacing = isLandscape ? 12 : 16;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _filteredProjects.length,
          padding: EdgeInsets.only(bottom: isTablet ? 30 : 20),
          itemBuilder: (context, index) {
            final project = _filteredProjects[index];
            return ProjectCard(
              title: project.title,
              createdDate: project.formattedDate,
              duration: project.durationFormatted,
              status: project.status,
              projectId: project.id,
              prompt: project.description,
              videoUrl: project.videoUrl, // Add videoUrl parameter
              imagePath:
                  project.type == 'avatar-based' &&
                      project.avatarImageUrl != null &&
                      project.avatarImageUrl!.isNotEmpty
                  ? project.avatarImageUrl!
                  : (project.thumbnailUrl.isNotEmpty
                        ? project.thumbnailUrl
                        : 'images/project-card.png'),
              onTap: () {
                print('🔍 Project Screen Project ID: ${project.id}');
                print('🔍 Project Screen Project Title: ${project.title}');
                print('🔍 Project Screen Project Status: ${project.status}');

                if (project.id.isNotEmpty) {
                  Navigator.push(
                    context,
                    AnimatedPageRoute(
                      page: ProjectDetailScreen(
                        projectId: project.id,
                        initialProject: {
                          '_id': project.id,
                          'title': project.title,
                          'description': project.description,
                          'status': project.status,
                          'type': project.type,
                          'thumbnailUrl': project.thumbnailUrl,
                          'videoUrl': project.videoUrl,
                          'createdAt': project.createdAt.toIso8601String(),
                          'updatedAt': project.updatedAt.toIso8601String(),
                          'duration': project.duration,
                          'aspectRatio': project.aspectRatio,
                          'resolution': project.resolution,
                        },
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to open project details. Invalid project ID.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              onPlay: () => _playProject(project),
              onDownload: () => _downloadProject(project),
              onDelete: () =>
                  _showDeleteConfirmation(context, project.title, project.id),
            );
          },
        );
      },
    );
  }

  // Build filter button
  Widget _buildFilterButton({
    required String title,
    required String filterValue,
    required int count,
    required bool isTablet,
  }) {
    final isSelected = _selectedFilter == filterValue;

    return GestureDetector(
      onTap: () => _updateFilter(filterValue),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purpleColor : AppColors.darkGreyColor,
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          border: Border.all(
            color: isSelected
                ? AppColors.purpleColor
                : AppColors.greyColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontSize: isTablet ? 16 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 60 : 40,
            vertical: isTablet ? 40 : 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: isTablet ? 120 : (isLandscape ? 100 : 80),
                color: Colors.grey.shade400,
              ),
              SizedBox(height: isTablet ? 24 : 16),
              Text(
                "No Projects Found",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 28 : (isLandscape ? 24 : 20),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                "Create your first video project to get started",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isTablet ? 20 : (isLandscape ? 18 : 16),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 400 : double.infinity,
                  ),
                  child: RoundButton(
                    title: isTablet
                        ? "Create Your First Project"
                        : "Create Project",
                    onPress: () {
                      Navigator.push(
                        context,
                        AnimatedPageRoute(page: const CreateVideo()),
                      );
                    },
                    leadingIcon: Icons.add,
                    leadingIconColor: Colors.white,
                    bgColor: AppColors.purpleColor,
                    borderRadius: isTablet ? 16 : 12,
                    fontSize: isTablet ? 18 : 16,
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 20 : 16,
                      horizontal: isTablet ? 40 : 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading state widget
  Widget _buildLoadingState() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isTablet ? 60 : 50,
            height: isTablet ? 60 : 50,
            child: CircularProgressIndicator(
              color: AppColors.purpleColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            "Loading Projects...",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  // Error state widget
  Widget _buildErrorState() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 60 : 40,
            vertical: isTablet ? 40 : 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: isTablet ? 80 : 60,
                color: Colors.red.shade400,
              ),
              SizedBox(height: isTablet ? 24 : 16),
              Text(
                "Failed to Load Projects",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                _errorMessage ?? "Something went wrong",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isTablet ? 16 : 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              SizedBox(
                width: isTablet ? 200 : 160,
                child: RoundButton(
                  title: "Try Again",
                  onPress: _loadProjects,
                  bgColor: AppColors.purpleColor,
                  borderRadius: isTablet ? 16 : 12,
                  fontSize: isTablet ? 16 : 14,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 12,
                    horizontal: isTablet ? 32 : 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String projectName,
    String projectId,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGreyColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        ),
        title: Text(
          "Delete Project",
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          constraints: BoxConstraints(maxWidth: isTablet ? 400 : 300),
          child: Text(
            "Are you sure you want to delete '$projectName'? This action cannot be undone.",
            style: TextStyle(color: Colors.grey, fontSize: isTablet ? 16 : 14),
          ),
        ),
        actionsPadding: EdgeInsets.all(isTablet ? 20 : 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: isTablet ? 12 : 8,
              ),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProject(projectId);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: isTablet ? 12 : 8,
              ),
            ),
            child: Text(
              "Delete",
              style: TextStyle(
                color: Colors.red,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
