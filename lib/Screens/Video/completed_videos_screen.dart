import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Project/project_detail_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';

class CompletedVideosScreen extends StatefulWidget {
  const CompletedVideosScreen({super.key});

  @override
  State<CompletedVideosScreen> createState() => _CompletedVideosScreenState();
}

class _CompletedVideosScreenState extends State<CompletedVideosScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, completed, processing, failed
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🎬 Loading completed videos screen - Text-based only');
      final response = await ApiService.getProjects(
        status: _filterStatus == 'all' ? null : _filterStatus,
        type: 'text-based', // Only load text-based projects
      );

      setState(() {
        _projects = List<Map<String, dynamic>>.from(response['projects'] ?? []);
        print('📽️ Loaded ${_projects.length} text-based projects');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
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
          'AI Generated Videos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.purpleColor,
        onRefresh: _loadProjects,
        child: Column(
          children: [
            _buildFilterTabs(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildFilterTab('All', 'all'),
          _buildFilterTab('Completed', 'completed'),
          _buildFilterTab('Processing', 'processing'),
          _buildFilterTab('Failed', 'failed'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String status) {
    final isSelected = _filterStatus == status;
    // final count = _getStatusCount(status);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filterStatus = status);
          _loadProjects();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purpleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              // if (count > 0) ...[
              //   const SizedBox(height: 2),
              //   Container(
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 6,
              //       vertical: 2,
              //     ),
              //     decoration: BoxDecoration(
              //       color: isSelected
              //           ? Colors.white.withOpacity(0.2)
              //           : AppColors.purpleColor,
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //     child: Text(
              //       count.toString(),
              //       style: TextStyle(
              //         color: isSelected ? Colors.white : Colors.white,
              //         fontSize: 10,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  // int _getStatusCount(String status) {
  //   if (status == 'all') return _projects.length;
  //   return _projects.where((project) => project['status'] == status).length;
  // }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purpleColor),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_projects.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProjectGrid();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading projects',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProjects,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_filterStatus) {
      case 'completed':
        message = 'No completed videos yet';
        icon = Icons.video_library;
        break;
      case 'processing':
        message = 'No videos currently processing';
        icon = Icons.hourglass_empty;
        break;
      case 'failed':
        message = 'No failed videos';
        icon = Icons.error_outline;
        break;
      default:
        message = 'No projects found';
        icon = Icons.folder_open;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (_filterStatus == 'all') ...[
            const SizedBox(height: 8),
            const Text(
              'Start creating your first AI video!',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final status = project['status'] ?? 'unknown';
    final videoUrl = project['videoUrl'];
    final thumbnailUrl = project['thumbnailUrl'];
    final title = project['title'] ?? 'Untitled Project';
    final type = project['type'] ?? 'unknown';
    final createdAt = project['createdAt'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AnimatedPageRoute(
            page: ProjectDetailScreen(
              projectId: project['_id'] ?? '',
              initialProject: project,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkGreyColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Preview
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildThumbnail(status, videoUrl, thumbnailUrl),
              ),
            ),

            // Project Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Status Badge
                    _buildStatusBadge(status),

                    const Spacer(),

                    // Type and Date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type == 'text-based'
                                ? 'AI Generated'
                                : 'Avatar Video',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    String status,
    String? videoUrl,
    String? thumbnailUrl,
  ) {
    Widget placeholder;
    Color backgroundColor;

    switch (status) {
      case 'completed':
        backgroundColor = Colors.green.withOpacity(0.1);
        placeholder = const Icon(
          Icons.play_circle_fill,
          color: Colors.green,
          size: 32,
        );
        break;
      case 'processing':
        backgroundColor = Colors.orange.withOpacity(0.1);
        placeholder = const CircularProgressIndicator(
          color: Colors.orange,
          strokeWidth: 2,
        );
        break;
      case 'failed':
        backgroundColor = Colors.red.withOpacity(0.1);
        placeholder = const Icon(Icons.error, color: Colors.red, size: 32);
        break;
      default:
        backgroundColor = Colors.blue.withOpacity(0.1);
        placeholder = const Icon(
          Icons.hourglass_empty,
          color: Colors.blue,
          size: 32,
        );
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
          ? Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: placeholder),
            )
          : Center(child: placeholder),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Ready';
        break;
      case 'processing':
        color = Colors.orange;
        label = 'Processing';
        break;
      case 'failed':
        color = Colors.red;
        label = 'Failed';
        break;
      case 'pending':
        color = Colors.blue;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
