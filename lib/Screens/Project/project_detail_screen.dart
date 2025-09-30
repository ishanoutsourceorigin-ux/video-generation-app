import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_gen_app/Component/video_player_dialog.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic>? initialProject;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialProject,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Map<String, dynamic>? project;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isRetrying = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('🔍 ProjectDetailScreen init - projectId: ${widget.projectId}');
    print('🔍 ProjectDetailScreen init - initialProject: ${widget.initialProject?.keys}');
    
    project = widget.initialProject;
    if (project != null) {
      _isLoading = false;
      print('✅ Using initial project data');
    } else {
      print('⚠️ No initial project data, will fetch from API');
    }
    _loadProjectDetails();
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
        title: Text(
          project?['title'] ?? 'Project Details',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (project != null && project!['status'] == 'completed')
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _downloadVideo(project!['videoUrl']),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppColors.darkGreyColor,
            onSelected: (value) async {
              switch (value) {
                case 'retry':
                  _retryProject();
                  break;
                case 'delete':
                  _deleteProject();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (project?['status'] == 'failed')
                const PopupMenuItem(
                  value: 'retry',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Retry', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _loadProjectDetails() async {
    print('🔍 Loading project details for ID: ${widget.projectId}');
    
    if (widget.projectId.isEmpty) {
      print('❌ Empty project ID provided');
      setState(() {
        _errorMessage = 'Invalid project ID provided';
        _isLoading = false;
      });
      return;
    }
    
    try {
      final result = await ApiService.getProject(widget.projectId);
      print('✅ Project details loaded successfully');
      setState(() {
        project = result['project'];
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      print('❌ Error loading project details: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProject() async {
    final confirmed = await _showConfirmDialog(
      'Delete Project',
      'Are you sure you want to delete this project? This action cannot be undone.',
      'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      await ApiService.deleteProject(widget.projectId);

      if (mounted) {
        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      _showSnackbar('Failed to delete project: ${e.toString()}', isError: true);
    }
  }

  Future<void> _retryProject() async {
    setState(() => _isRetrying = true);

    try {
      final result = await ApiService.retryProject(widget.projectId);
      setState(() {
        project = result['project'];
        _isRetrying = false;
      });
      _showSnackbar('Project retry initiated successfully');
    } catch (e) {
      setState(() => _isRetrying = false);
      _showSnackbar('Failed to retry project: ${e.toString()}', isError: true);
    }
  }

  Future<void> _downloadVideo(String? videoUrl) async {
    if (videoUrl == null || videoUrl.isEmpty) {
      _showSnackbar('No video URL available', isError: true);
      return;
    }

    try {
      _showSnackbar('Starting download...');

      // Get the video data
      final response = await http.get(Uri.parse(videoUrl));

      if (response.statusCode == 200) {
        // Get the appropriate directory based on platform
        Directory? directory;

        if (Platform.isAndroid) {
          // For Android, try multiple approaches
          try {
            // First try: External storage Downloads directory
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              // Create a Downloads folder in the app's external directory
              final appDownloads = Directory('${externalDir.path}/Downloads');
              await appDownloads.create(recursive: true);
              directory = appDownloads;
            }
          } catch (e) {
            print('Failed to access external storage: $e');
            // Fallback: Use app documents directory
            directory = await getApplicationDocumentsDirectory();
          }
        } else if (Platform.isIOS) {
          // For iOS, use documents directory
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory == null) {
          _showSnackbar('Unable to access storage directory', isError: true);
          return;
        }

        // Generate filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final projectTitle =
            project!['title']?.replaceAll(RegExp(r'[^\w\s-]'), '') ?? 'video';
        final filename = '${projectTitle}_$timestamp.mp4';
        final filePath = '${directory.path}/$filename';

        // Write the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        _showSnackbar(
          'Video downloaded successfully!\\nSaved to: ${directory.path}',
        );

        // Update download count
        if (project != null) {
          setState(() {
            project!['downloadCount'] = (project!['downloadCount'] ?? 0) + 1;
          });
        }
      } else {
        _showSnackbar(
          'Failed to download video (${response.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar('Download failed: ${e.toString()}', isError: true);
      print('Download error: $e');
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String content,
    String actionText, {
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkGreyColor,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              content,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : AppColors.purpleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purpleColor),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error Loading Project',
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            RoundButton(
              title: 'Retry',
              onPress: _loadProjectDetails,
              bgColor: AppColors.purpleColor,
              fontSize: 16,
              leadingIcon: Icons.refresh,
            ),
          ],
        ),
      );
    }

    if (project == null) {
      return const Center(
        child: Text(
          'Project not found',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.purpleColor,
      onRefresh: _loadProjectDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoSection(),
            const SizedBox(height: 24),
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildProjectInfo(),
            const SizedBox(height: 24),

            _buildConfigurationSection(),
            // const SizedBox(height: 24),
            // _buildMetricsSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final status = project!['status'] ?? 'unknown';
    final type = project!['type'] ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusBadge(status),
              const Spacer(),
              _buildTypeBadge(type),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            project!['title'] ?? 'Untitled Project',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project!['description'] ?? '',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          if (status == 'processing') ...[
            const SizedBox(height: 16),
            _buildProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = Colors.orange;
        label = 'Processing';
        icon = Icons.hourglass_empty;
        break;
      case 'failed':
        color = Colors.red;
        label = 'Failed';
        icon = Icons.error;
        break;
      case 'pending':
        color = Colors.blue;
        label = 'Pending';
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = type == 'text-based'
        ? AppColors.blueColor
        : AppColors.purpleColor;
    String label = type == 'text-based' ? 'AI Generated' : 'Avatar Video';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Processing...',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              _getEstimatedTimeText(),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(
          color: Colors.orange,
          backgroundColor: Colors.orange,
          minHeight: 4,
        ),
      ],
    );
  }

  String _getEstimatedTimeText() {
    final estimatedTime = project?['estimatedTimeRemaining'];
    if (estimatedTime != null && estimatedTime > 0) {
      final minutes = (estimatedTime / 60).floor();
      final seconds = estimatedTime % 60;
      return '~${minutes}m ${seconds}s remaining';
    }
    return 'Processing...';
  }

  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Created', _formatDate(project!['createdAt'])),
          _buildInfoRow('Type', project!['type'] ?? 'Unknown'),
          _buildInfoRow('Provider', project!['provider'] ?? 'Unknown'),
          if (project!['processingStartedAt'] != null)
            _buildInfoRow(
              'Processing Started',
              _formatDate(project!['processingStartedAt']),
            ),
          if (project!['processingCompletedAt'] != null)
            _buildInfoRow(
              'Completed',
              _formatDate(project!['processingCompletedAt']),
            ),
          if (project!['errorMessage'] != null)
            _buildInfoRow('Error', project!['errorMessage'], isError: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : Colors.white,
                fontSize: 14,
                fontWeight: isError ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    final videoUrl = project!['videoUrl'];
    final status = project!['status'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generated Video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (status == 'completed' && videoUrl != null && videoUrl.isNotEmpty)
            _buildVideoPreview(videoUrl)
          else if (status == 'processing')
            _buildProcessingPlaceholder()
          else if (status == 'failed')
            _buildFailedPlaceholder()
          else
            _buildPendingPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(String videoUrl) {
    // Use existing thumbnail URL from project data, fallback to generation
    String thumbnailUrl =
        project!['thumbnailUrl'] ?? _generateThumbnailUrl(videoUrl);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openVideoPlayer(videoUrl),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
              image: thumbnailUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(thumbnailUrl),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        print('Error loading thumbnail: $exception');
                      },
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Gradient overlay for better visibility
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Play button overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: AppColors.purpleColor,
                      size: 40,
                    ),
                  ),
                ),
                // Duration badge (if available)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${project!['configuration']?['duration'] ?? '8'}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Quality badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purpleColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${project!['configuration']?['resolution'] ?? '720'}p',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Video info row
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: AppColors.appBgColor,
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
        //   ),
        //   child: Row(
        //     children: [
        //       Icon(Icons.videocam, color: AppColors.purpleColor, size: 16),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: Text(
        //           'Tap to play video in browser',
        //           style: TextStyle(color: Colors.white70, fontSize: 12),
        //         ),
        //       ),
        //       Text(
        //         '${_getVideoFileSize()} MB',
        //         style: TextStyle(
        //           color: AppColors.purpleColor,
        //           fontSize: 12,
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // const SizedBox(height: 16),
        // Row(
        //   children: [
        //     Expanded(
        //       child: RoundButton(
        //         title: 'Copy Video URL',
        //         onPress: () {
        //           Clipboard.setData(ClipboardData(text: videoUrl));
        //           _showSnackbar('Video URL copied to clipboard');
        //         },
        //         bgColor: AppColors.purpleColor,
        //         fontSize: 14,
        //         leadingIcon: Icons.copy,
        //         padding: const EdgeInsets.symmetric(vertical: 12),
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: RoundButton(
        //         title: 'Open Video',
        //         onPress: () => _openVideoPlayer(videoUrl),
        //         bgColor: Colors.green,
        //         fontSize: 14,
        //         leadingIcon: Icons.play_arrow,
        //         padding: const EdgeInsets.symmetric(vertical: 12),
        //       ),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 8),
        RoundButton(
          title: 'Download Video',
          onPress: () => _downloadVideo(videoUrl),
          bgColor: Colors.green,
          fontSize: 14,
          leadingIcon: Icons.download,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ],
    );
  }

  Widget _buildProcessingPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Video is being processed...',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a few minutes',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Video generation failed',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try again or contact support',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, color: Colors.blue, size: 48),
            SizedBox(height: 16),
            Text(
              'Video generation pending',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Will start processing soon',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    final config = project!['configuration'] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConfigItem(
                  'Aspect Ratio',
                  config['aspectRatio'] ?? 'Unknown',
                ),
              ),
              Expanded(
                child: _buildConfigItem(
                  'Resolution',
                  '${config['resolution'] ?? 'Unknown'}p',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConfigItem(
                  'Duration',
                  '${config['duration'] ?? 'Unknown'}s',
                ),
              ),
              Expanded(
                child: _buildConfigItem('Style', config['style'] ?? 'Unknown'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = project!['status'];

    return Column(
      children: [
        if (status == 'failed') ...[
          RoundButton(
            title: _isRetrying ? 'Retrying...' : 'Retry Generation',
            onPress: _isRetrying ? () {} : () async => await _retryProject(),
            bgColor: _isRetrying
                ? AppColors.greyColor.withOpacity(0.5)
                : Colors.orange,
            fontSize: 16,
            leadingIcon: _isRetrying ? null : Icons.refresh,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          const SizedBox(height: 12),
        ],
        RoundButton(
          title: _isDeleting ? 'Deleting...' : 'Delete Project',
          onPress: _isDeleting ? () {} : () async => await _deleteProject(),
          bgColor: _isDeleting
              ? AppColors.greyColor.withOpacity(0.5)
              : Colors.red.withOpacity(0.8),
          fontSize: 16,
          leadingIcon: _isDeleting ? null : Icons.delete,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${_formatTime(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${_formatTime(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Generate thumbnail URL from video URL (Cloudinary specific)
  String _generateThumbnailUrl(String videoUrl) {
    try {
      if (videoUrl.contains('cloudinary.com') &&
          videoUrl.contains('/video/upload/')) {
        // Parse the Cloudinary URL structure
        // Example: https://res.cloudinary.com/dlmzsseud/video/upload/v1759173098/ai-generated-videos/video_68dad96b62dddeff2965d614_1759173097511.mp4

        // Replace video/upload with image/upload for thumbnail generation
        String thumbnailUrl = videoUrl.replaceAll(
          '/video/upload/',
          '/image/upload/',
        );

        // Remove the .mp4 extension
        thumbnailUrl = thumbnailUrl.replaceAll('.mp4', '');

        // Add thumbnail transformation parameters
        // Insert transformation after /upload/
        thumbnailUrl = thumbnailUrl.replaceAll(
          '/image/upload/',
          '/image/upload/c_scale,w_400,h_225,f_auto,q_auto/',
        );

        print('🖼️ Original video URL: $videoUrl');
        print('🖼️ Generated thumbnail URL: $thumbnailUrl');
        return thumbnailUrl;
      }
      print(
        '⚠️ Unable to generate thumbnail for non-Cloudinary URL: $videoUrl',
      );
      return '';
    } catch (e) {
      print('❌ Error generating thumbnail URL: $e');
      return '';
    }
  }

  // Open video in web browser or in-app player
  void _openVideoPlayer(String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => VideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  // Get estimated video file size based on duration and resolution
  String _getVideoFileSize() {
    try {
      final duration = project!['configuration']?['duration'] ?? 8;
      final resolution = project!['configuration']?['resolution'] ?? 720;

      // Rough estimation: 720p = ~1MB per second, 1080p = ~2MB per second
      double sizePerSecond = resolution >= 1080 ? 2.0 : 1.0;
      double estimatedSize = duration * sizePerSecond;

      return estimatedSize.toStringAsFixed(1);
    } catch (e) {
      return '~8.0';
    }
  }
}
