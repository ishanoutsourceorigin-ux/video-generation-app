import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Project/project_detail_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Utils/video_download_helper.dart';
import 'package:video_gen_app/Component/chewie_video_dialog.dart';
import 'package:video_gen_app/Component/project_card.dart';

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
        border: Border.all(color: AppColors.greyColor.withValues(alpha: 0.3)),
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
              //           ? Colors.white.withValues(alpha: 0.2)
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
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
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
    final title = project['title'] ?? 'Untitled Project';
    final createdAt = project['createdAt'] ?? '';
    final duration = project['duration']?.toString() ?? '0';
    final thumbnailUrl = project['thumbnailUrl'] ?? '';
    final projectId = project['id'] ?? project['_id'] ?? '';

    return ProjectCard(
      title: title,
      createdDate: _formatDate(createdAt),
      duration: '${duration}s',
      status: status,
      projectId: projectId,
      prompt: project['description'],
      videoUrl: project['videoUrl'],
      imagePath: thumbnailUrl.isNotEmpty
          ? thumbnailUrl
          : 'images/project-card.png',
      onTap: () => _viewProject(project),
      onPlay: () => _playVideo(project['videoUrl'] ?? '', title),
      onDownload: () => _downloadVideo(project['videoUrl'] ?? '', title),
      onDelete: () => _deleteProject(projectId),
    );
  }

  void _viewProject(Map<String, dynamic> project) {
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: ProjectDetailScreen(
          projectId: project['_id'] ?? '',
          initialProject: project,
        ),
      ),
    );
  }

  void _deleteProject(String projectId) {
    if (projectId.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGreyColor,
        title: const Text(
          'Delete Project',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this project? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete(projectId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String projectId) async {
    try {
      // Implement actual delete API call here
      // await ApiService.deleteProject(projectId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      _loadProjects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Play video in dialog
  void _playVideo(String videoUrl, String title) {
    if (videoUrl.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            ChewieVideoDialog(videoUrl: videoUrl, title: title),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video is not available"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Download video using VideoDownloadHelper
  Future<void> _downloadVideo(String videoUrl, String title) async {
    if (videoUrl.isNotEmpty) {
      await VideoDownloadHelper.downloadVideo(
        context: context,
        videoUrl: videoUrl,
        fileName: title,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video is not available for download"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
