import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:device_info_plus/device_info_plus.dart';

class VideoDownloadService {
  /// Download and save video from Cloudinary URL to device gallery
  /// Uses streaming download to prevent memory issues with large files
  ///
  /// [cloudinaryUrl] - The Cloudinary video URL to download
  /// [onProgress] - Callback to track download progress (0.0 to 1.0)
  /// [onStatusUpdate] - Callback to update UI status
  /// [albumName] - Album name in gallery (default: 'CloneX Videos')
  ///
  /// Returns true if successful, false otherwise
  static Future<bool> downloadAndSaveVideoFromCloudinary({
    required String cloudinaryUrl,
    required Function(String status) onStatusUpdate,
    Function(double progress)? onProgress,
    String albumName = 'CloneX Videos',
  }) async {
    Dio? dio;
    String? tempFilePath;

    try {
      // Update status
      onStatusUpdate('Preparing download...');

      // Request storage permissions
      if (!await _requestStoragePermissions()) {
        onStatusUpdate('Storage permission denied');
        return false;
      }

      // Initialize Dio with proper configuration
      dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(
            minutes: 10,
          ), // Allow time for large videos
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'video/*',
            'User-Agent': 'CloneX-VideoDownloader/1.0',
          },
        ),
      );

      // Get temporary directory and create unique filename
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'clonex_video_$timestamp.mp4';
      tempFilePath = '${tempDir.path}/$fileName';

      onStatusUpdate('Starting download...');

      // Stream download directly to file to prevent memory issues
      await dio.download(
        cloudinaryUrl,
        tempFilePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress?.call(progress);

            // Update status with percentage
            final percentage = (progress * 100).toInt();
            onStatusUpdate('Downloading... $percentage%');
          } else {
            onStatusUpdate('Downloading... ${_formatBytes(received)}');
          }
        },
      );

      // Verify file exists and has content
      final File tempFile = File(tempFilePath);
      if (!await tempFile.exists()) {
        onStatusUpdate('Download failed: File not created');
        return false;
      }

      final int fileSize = await tempFile.length();
      if (fileSize == 0) {
        onStatusUpdate('Download failed: File is empty');
        await tempFile.delete();
        return false;
      }

      onStatusUpdate('Saving to gallery...');

      // Save to gallery using gal package
      await Gal.putVideo(tempFilePath, album: albumName);

      // Clean up temporary file
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        print('Warning: Could not delete temporary file: $e');
      }

      onStatusUpdate('Video saved successfully!');
      return true;
    } on DioException catch (e) {
      // Handle Dio-specific errors
      String errorMessage = 'Download failed';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout - please check your internet';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Download timeout - file may be too large';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Server error: ${e.response?.statusCode ?? 'Unknown'}';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Network connection error';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Download cancelled';
          break;
        default:
          errorMessage = 'Download failed: ${e.message}';
      }

      onStatusUpdate(errorMessage);
      print('Dio error: $e');
      return false;
    } catch (e) {
      onStatusUpdate('Download failed: ${e.toString()}');
      print('Download error: $e');
      return false;
    } finally {
      // Clean up temporary file if it still exists
      if (tempFilePath != null) {
        try {
          final File tempFile = File(tempFilePath);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          print(
            'Warning: Could not delete temporary file in finally block: $e',
          );
        }
      }

      // Close Dio instance
      dio?.close();
    }
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Request necessary storage permissions with proper Android version detection
  static Future<bool> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Get accurate Android version using device_info_plus
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final int sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ (API 33+) - Use scoped storage permissions
          final status = await Permission.photos.request();
          return status.isGranted;
        } else if (sdkInt >= 30) {
          // Android 11-12 (API 30-32) - Request storage permission
          final status = await Permission.storage.request();
          return status.isGranted;
        } else {
          // Android 10 and below - Request storage permission
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        // iOS - Request photos permission
        final status = await Permission.photos.request();
        return status.isGranted;
      }

      return true; // For other platforms
    } catch (e) {
      print('Permission request error: $e');
      // Fallback: try both permissions
      try {
        final storageStatus = await Permission.storage.request();
        final photosStatus = await Permission.photos.request();
        return storageStatus.isGranted || photosStatus.isGranted;
      } catch (fallbackError) {
        print('Fallback permission request failed: $fallbackError');
        return false;
      }
    }
  }

  /// Show download progress dialog with proper state management
  static Future<void> showDownloadDialog({
    required BuildContext context,
    required String cloudinaryUrl,
    String albumName = 'CloneX Videos',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _DownloadDialog(
          cloudinaryUrl: cloudinaryUrl,
          albumName: albumName,
        );
      },
    );
  }
}

/// Stateful dialog widget for download progress
class _DownloadDialog extends StatefulWidget {
  final String cloudinaryUrl;
  final String albumName;

  const _DownloadDialog({required this.cloudinaryUrl, required this.albumName});

  @override
  _DownloadDialogState createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  String _currentStatus = 'Initializing...';
  bool _isDownloading = true;
  bool _isSuccess = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() async {
    final success =
        await VideoDownloadService.downloadAndSaveVideoFromCloudinary(
          cloudinaryUrl: widget.cloudinaryUrl,
          albumName: widget.albumName,
          onStatusUpdate: (status) {
            if (mounted) {
              setState(() {
                _currentStatus = status;
                _isDownloading =
                    !status.contains('successfully') &&
                    !status.contains('Failed') &&
                    !status.contains('denied') &&
                    !status.contains('timeout') &&
                    !status.contains('error');
                _isSuccess = status.contains('successfully');
              });
            }
          },
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
              });
            }
          },
        );

    // Auto-close dialog after 2 seconds if successful
    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E), // Darker background matching your app
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3A3D4A).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
              // Header with CloneX branding
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // App Icon/Logo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isSuccess
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : _currentStatus.contains('Failed') ||
                                    _currentStatus.contains('error')
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [
                                  const Color(0xFF4C6EF5),
                                  const Color(0xFF7C3AED),
                                ], // Purple to blue gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isSuccess
                                        ? Colors.green
                                        : _currentStatus.contains('Failed')
                                        ? Colors.red
                                        : const Color(0xFF4C6EF5))
                                    .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSuccess
                            ? Icons.check_circle_rounded
                            : _currentStatus.contains('Failed') ||
                                  _currentStatus.contains('error')
                            ? Icons.error_rounded
                            : Icons.cloud_download_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSuccess
                          ? 'Download Complete!'
                          : _currentStatus.contains('Failed') ||
                                _currentStatus.contains('error')
                          ? 'Download Failed'
                          : 'CloneX Video Download',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Eurostile",
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Progress Section
              if (_isDownloading) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_progress > 0) ...[
                        // Circular Progress Indicator
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade700,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF4C6EF5),
                                ),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Loading animation
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF4C6EF5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        _currentStatus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Success or Error State
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSuccess
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: _isSuccess ? Colors.green : Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentStatus,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isSuccess) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Video saved to CloneX Videos album',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Button
              if (!_isDownloading) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSuccess
                          ? Colors.green
                          : const Color(0xFF4C6EF5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isSuccess ? 'Done' : 'OK',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
