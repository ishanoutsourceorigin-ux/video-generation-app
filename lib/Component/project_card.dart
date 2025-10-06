import 'package:flutter/material.dart';
import '../Utils/video_download_helper.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String createdDate;
  final String duration;
  final String imagePath;
  final String? status;
  final String? projectId;
  final String? prompt; // User's prompt/description
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final String? videoUrl; // Cloudinary video URL
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.title,
    required this.createdDate,
    required this.duration,
    required this.imagePath,
    this.status,
    this.projectId,
    this.prompt,
    this.videoUrl,
    required this.onPlay,
    required this.onDownload,
    required this.onDelete,
    this.onTap,
  });

  Widget _buildImageActionButton({
    required String imageAsset,
    required VoidCallback onTap,
    required double iconSize,
    required double padding,
    String? label,
    IconData? fallbackIcon,
  }) {
    return Tooltip(
      message: label ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imageAsset,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                fallbackIcon ?? Icons.circle,
                size: iconSize,
                color: Colors.grey.shade400,
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      case 'queued':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Handle download from Cloudinary URL
  void _handleCloudinaryDownload(BuildContext context) {
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      VideoDownloadHelper.downloadVideo(
        context: context,
        videoUrl: videoUrl!,
        albumName: 'CloneX Videos',
      );
    } else {
      // Fallback to original download callback
      onDownload();
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Ready';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'queued':
        return 'Queued';
      default:
        return status;
    }
  }

  // Check if thumbnail should be shown (only for completed videos)
  bool _shouldShowThumbnail() {
    return status?.toLowerCase() == 'completed';
  }

  // Build placeholder for non-ready videos
  Widget _buildPlaceholder() {
    final statusLower = status?.toLowerCase() ?? 'draft';
    IconData iconData;
    Color iconColor;
    String statusText;

    switch (statusLower) {
      case 'processing':
        iconData = Icons.hourglass_empty;
        iconColor = Colors.orange;
        statusText = 'Processing...';
        break;
      case 'failed':
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        statusText = 'Failed';
        break;
      case 'draft':
        iconData = Icons.edit_outlined;
        iconColor = Colors.grey;
        statusText = 'Draft';
        break;
      default:
        iconData = Icons.video_library_outlined;
        iconColor = Colors.grey;
        statusText = 'Thumbnail Not Available';
    }

    return Container(
      color: const Color(0xFF3A3D4A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: iconColor, size: 50),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              color: iconColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Enhanced responsive sizing
    final contentPadding = isTablet ? 16.0 : 12.0;
    final titleFontSize = isTablet ? 16.0 : 14.0;
    final dateFontSize = isTablet ? 12.0 : 10.0;
    final iconSize = isTablet ? 20.0 : 18.0;
    final buttonPadding = isTablet ? 10.0 : 8.0;
    final thumbnailHeight = isTablet ? 140.0 : 110.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: thumbnailHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.blue.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background image with error handling
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(color: Color(0xFF3A3D4A)),
                      child: _shouldShowThumbnail()
                          ? (imagePath.startsWith('http')
                                ? Image.network(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  )
                                : Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  ))
                          : _buildPlaceholder(),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    // Duration badge and status
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Status badge
                          if (status != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 8 : 6,
                                vertical: isTablet ? 4 : 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  status!,
                                ).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getStatusText(status!),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: dateFontSize - 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          // Duration badge
                          // Container(
                          //   padding: EdgeInsets.symmetric(
                          //     horizontal: isTablet ? 10 : 8,
                          //     vertical: isTablet ? 6 : 4,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     color: Colors.black.withOpacity(0.8),
                          //     borderRadius: BorderRadius.circular(20),
                          //     border: Border.all(
                          //       color: Colors.white.withOpacity(0.2),
                          //       width: 1,
                          //     ),
                          //   ),
                          //   child: Text(
                          //     duration,
                          //     style: TextStyle(
                          //       color: Colors.white,
                          //       fontSize: dateFontSize,
                          //       fontWeight: FontWeight.w600,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Row(
                    children: [
                      Icon(
                        Icons.text_snippet_outlined,
                        color: Colors.grey.shade500,
                        size: dateFontSize + 2,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          prompt ?? "No prompt available",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: dateFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageActionButton(
                        imageAsset: "images/download-icon.png",
                        onTap: () => _handleCloudinaryDownload(context),
                        iconSize: iconSize + 4,
                        padding: buttonPadding,
                        label: "Download",
                        fallbackIcon: Icons.download,
                      ),
                      const SizedBox(width: 20),
                      _buildImageActionButton(
                        imageAsset: "images/delete-icon.png",
                        onTap: onDelete,
                        iconSize: iconSize + 4,
                        padding: buttonPadding,
                        label: "Delete",
                        fallbackIcon: Icons.delete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
