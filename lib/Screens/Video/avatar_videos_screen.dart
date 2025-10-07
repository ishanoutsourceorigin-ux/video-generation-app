import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Screens/Project/project_detail_screen.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Component/project_card.dart';
import 'package:video_gen_app/Utils/video_download_helper.dart';
import 'package:video_gen_app/Component/chewie_video_dialog.dart';

class AvatarVideosScreen extends StatefulWidget {
  const AvatarVideosScreen({super.key});

  @override
  State<AvatarVideosScreen> createState() => _AvatarVideosScreenState();
}

class _AvatarVideosScreenState extends State<AvatarVideosScreen> {
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
      // print('🎭 Loading avatar videos screen - Avatar-based only');
      final response = await ApiService.getProjects(
        status: _filterStatus == 'all' ? null : _filterStatus,
        type: 'avatar-based', // Only load avatar-based projects
      );

      setState(() {
        _projects = List<Map<String, dynamic>>.from(response['projects'] ?? []);
        print('🎬 Loaded ${_projects.length} avatar video projects');
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
          'Avatar Generated Videos',
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

  Widget _buildFilterTab(String title, String status) {
    final isSelected = _filterStatus == status;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterStatus = status;
          });
          _loadProjects();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purpleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error Loading Videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProjects,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              'No Avatar Videos Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first avatar video to see it here',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

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
    final title = project['title'] ?? 'Untitled';
    final createdAt = project['createdAt'] ?? '';
    final duration = project['duration']?.toString() ?? '0';
    final thumbnailUrl = project['thumbnailUrl'] ?? '';
    final projectId = project['id'] ?? project['_id'] ?? '';

    // For avatar-based projects, use avatar image if available
    final avatarImageUrl = project['avatarId'] is Map
        ? project['avatarId']['imageUrl']
        : null;

    // Use avatar image for avatar-based projects, otherwise use thumbnail or fallback
    final imagePath = avatarImageUrl != null && avatarImageUrl.isNotEmpty
        ? avatarImageUrl
        : (thumbnailUrl.isNotEmpty ? thumbnailUrl : 'images/project-card.png');

    return ProjectCard(
      title: title,
      createdDate: _formatDate(createdAt),
      duration: '${duration}s',
      status: status,
      projectId: projectId,
      prompt: project['description'],
      videoUrl: project['videoUrl'], // Add videoUrl parameter
      imagePath: imagePath,
      onTap: () => _viewProject(project),
      onPlay: () => _playProject(project),
      onDownload: () => _downloadProject(project),
      onDelete: () => _deleteProject(projectId),
    );
  }

  void _playProject(Map<String, dynamic> project) {
    final videoUrl = project['videoUrl'] ?? '';
    final title = project['title'] ?? 'Avatar Video';

    if (videoUrl.isNotEmpty && project['status'] == 'completed') {
      showDialog(
        context: context,
        builder: (context) =>
            ChewieVideoDialog(videoUrl: videoUrl, title: title),
      );
    } else if (project['status'] != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video is still processing. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadProject(Map<String, dynamic> project) async {
    final videoUrl = project['videoUrl'] ?? '';
    final title = project['title'] ?? 'Avatar Video';

    if (videoUrl.isNotEmpty && project['status'] == 'completed') {
      await VideoDownloadHelper.downloadVideo(
        context: context,
        videoUrl: videoUrl,
        fileName: title,
      );
    } else if (project['status'] != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video is not ready for download'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video not available for download'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _viewProject(Map<String, dynamic> project) {
    final projectId = project['id'] ?? project['_id'] ?? '';
    Navigator.push(
      context,
      AnimatedPageRoute(page: ProjectDetailScreen(projectId: projectId)),
    );
  }
}
