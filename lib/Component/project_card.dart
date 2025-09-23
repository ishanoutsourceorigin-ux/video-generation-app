import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String createdDate;
  final String duration;
  final String imagePath;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.title,
    required this.createdDate,
    required this.duration,
    required this.imagePath,
    required this.onPlay,
    required this.onDownload,
    required this.onDelete,
  });

  Widget _buildImageActionButton({
    required String imageAsset,
    required VoidCallback onTap,
    required double iconSize,
    required double padding,
    String? label,
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Enhanced responsive sizing
    final cardWidth = isTablet
        ? (isLandscape ? 280.0 : 240.0)
        : (isLandscape ? 220.0 : 180.0);
    final contentPadding = isTablet ? 16.0 : 12.0;
    final titleFontSize = isTablet ? 16.0 : 14.0;
    final dateFontSize = isTablet ? 12.0 : 10.0;
    final iconSize = isTablet ? 20.0 : 18.0;
    final buttonPadding = isTablet ? 10.0 : 8.0;
    final thumbnailHeight = isTablet ? 140.0 : 110.0;

    return Container(
      margin: EdgeInsets.only(right: isTablet ? 16 : 12),
      width: cardWidth,
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
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF3A3D4A),
                          child: const Icon(
                            Icons.video_library,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    ),
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
                  // Duration badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10 : 8,
                        vertical: isTablet ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        duration,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dateFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Play overlay
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        onTap: onPlay,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                          ),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 16 : 12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: isTablet ? 24 : 20,
                              ),
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
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.access_time,
                        color: Colors.grey.shade500,
                        size: dateFontSize + 2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Created $createdDate",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: dateFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageActionButton(
                        imageAsset: "images/download-icon.png",
                        onTap: onDownload,
                        iconSize: iconSize + 4,
                        padding: buttonPadding,
                        label: "Download",
                      ),
                      const Spacer(),
                      _buildImageActionButton(
                        imageAsset: "images/delete-icon.png",
                        onTap: onDelete,
                        iconSize: iconSize + 4,
                        padding: buttonPadding,
                        label: "Delete",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
