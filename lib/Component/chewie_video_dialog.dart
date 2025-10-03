import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Utils/app_colors.dart';

class ChewieVideoDialog extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const ChewieVideoDialog({super.key, required this.videoUrl, this.title});

  @override
  State<ChewieVideoDialog> createState() => _ChewieVideoDialogState();
}

class _ChewieVideoDialogState extends State<ChewieVideoDialog> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.purpleColor,
          handleColor: AppColors.purpleColor,
          backgroundColor: Colors.grey.shade700,
          bufferedColor: Colors.grey.shade400,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.purpleColor),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load video',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkGreyColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Video Player
            Flexible(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: _buildVideoPlayer(),
              ),
            ),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.greyColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_filled,
            color: AppColors.purpleColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title ?? 'Video Player',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.purpleColor),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Failed to load video',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Video not available',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // First button - Save to Gallery
          SizedBox(
            width: double.infinity,
            child: RoundButton(
              title: _isDownloading ? 'Downloading...' : 'Save to Gallery',
              onPress: _isDownloading ? () {} : _saveToGallery,
              bgColor: Colors.green,
              fontSize: 14,
              leadingIcon: _isDownloading ? null : Icons.download,
              leadingIconColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Second button - Copy Link
          SizedBox(
            width: double.infinity,
            child: RoundButton(
              title: 'Copy Link',
              onPress: _copyVideoLink,
              bgColor: AppColors.purpleColor,
              fontSize: 14,
              leadingIcon: Icons.copy,
              leadingIconColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      setState(() {
        _isDownloading = true;
      });

      // Request storage permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (status.isDenied) {
          _showSnackBar(
            'Storage permission is required to save video',
            Colors.red,
          );
          return;
        }
      }

      _showSnackBar('Starting download...', Colors.blue);

      // Download the video
      final response = await http.get(Uri.parse(widget.videoUrl));

      if (response.statusCode == 200) {
        // Get the appropriate directory
        Directory? directory;

        if (Platform.isAndroid) {
          // Try to get external storage directory
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            // Create Downloads folder
            final downloadsDir = Directory('${directory.path}/Downloads');
            await downloadsDir.create(recursive: true);
            directory = downloadsDir;
          }
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory == null) {
          _showSnackBar('Unable to access storage', Colors.red);
          return;
        }

        // Generate filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'video_$timestamp.mp4';
        final filePath = '${directory.path}/$filename';

        // Save file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        _showSnackBar(
          'Video saved successfully!\nLocation: ${directory.path}',
          Colors.green,
        );
      } else {
        _showSnackBar('Failed to download video', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Download failed: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _copyVideoLink() {
    Clipboard.setData(ClipboardData(text: widget.videoUrl));
    _showSnackBar('Video link copied to clipboard', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
