import 'package:flutter/material.dart';
import '../Services/video_download_service.dart';

/// Utility class for handling video downloads from Cloudinary
class VideoDownloadHelper {
  /// Download video from Cloudinary URL with user feedback
  ///
  /// [context] - BuildContext for showing dialogs
  /// [videoUrl] - Cloudinary video URL
  /// [fileName] - Optional custom file name
  /// [albumName] - Album name in gallery (default: 'CloneX Videos')
  static Future<void> downloadVideo({
    required BuildContext context,
    required String videoUrl,
    String? fileName,
    String albumName = 'CloneX Videos',
  }) async {
    if (videoUrl.isEmpty) {
      _showErrorDialog(context, 'No video URL provided');
      return;
    }

    try {
      await VideoDownloadService.showDownloadDialog(
        context: context,
        cloudinaryUrl: videoUrl,
        albumName: albumName,
      );
    } catch (e) {
      _showErrorDialog(context, 'Failed to start download: ${e.toString()}');
    }
  }

  /// Show error dialog with improved CloneX UI
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3A3D4A).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Download Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Eurostile",
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Error Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Check if URL is a valid Cloudinary URL
  static bool isValidCloudinaryUrl(String url) {
    return url.isNotEmpty &&
        (url.contains('cloudinary.com') || url.contains('res.cloudinary.com'));
  }

  /// Extract filename from Cloudinary URL
  static String extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        final nameWithoutExtension = lastSegment.split('.').first;
        return '${nameWithoutExtension}_clonex.mp4';
      }
    } catch (e) {
      print('Error extracting filename: $e');
    }
    return 'clonex_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }
}
