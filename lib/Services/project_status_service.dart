import 'package:flutter/material.dart';
import 'dart:async';
// import 'package:video_gen_app/Services/Api/api_service.dart';

class ProjectStatusService {
  static final ProjectStatusService _instance =
      ProjectStatusService._internal();
  factory ProjectStatusService() => _instance;
  ProjectStatusService._internal();

  Timer? _statusTimer;
  final List<Function(Map<String, dynamic>)> _listeners = [];
  bool _isPolling = false;

  void addListener(Function(Map<String, dynamic>) callback) {
    _listeners.add(callback);
    _startPolling();
  }

  void removeListener(Function(Map<String, dynamic>) callback) {
    _listeners.remove(callback);
    if (_listeners.isEmpty) {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_isPolling) return;

    // Temporarily disabled to prevent rate limiting during development
    // TODO: Re-enable after optimizing polling strategy
    return;

    // _isPolling = true;
    // _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
    //   await _checkProjectStatus();
    // });
  }

  void _stopPolling() {
    _statusTimer?.cancel();
    _isPolling = false;
  }

  // Future<void> _checkProjectStatus() async {
  //   try {
  //     final response = await ApiService.getProjects(status: 'processing');
  //     final projects = List<Map<String, dynamic>>.from(
  //       response['projects'] ?? [],
  //     );

  //     for (final project in projects) {
  //       // Notify all listeners about project updates
  //       for (final listener in _listeners) {
  //         listener(project);
  //       }
  //     }
  //   } catch (e) {
  //     // Handle error silently in background
  //     print('Status polling error: $e');
  //   }
  // }

  void dispose() {
    _stopPolling();
    _listeners.clear();
  }
}

class ProjectNotificationService {
  static final ProjectNotificationService _instance =
      ProjectNotificationService._internal();
  factory ProjectNotificationService() => _instance;
  ProjectNotificationService._internal();

  BuildContext? _context;
  final Map<String, String> _lastStatus = {};

  void initialize(BuildContext context) {
    _context = context;

    ProjectStatusService().addListener((project) {
      _handleProjectUpdate(project);
    });
  }

  void _handleProjectUpdate(Map<String, dynamic> project) {
    if (_context == null) return;

    final projectId = project['_id'] ?? '';
    final currentStatus = project['status'] ?? '';
    final lastStatus = _lastStatus[projectId];

    // Only show notification if status changed
    if (lastStatus != null && lastStatus != currentStatus) {
      _showStatusNotification(project);
    }

    _lastStatus[projectId] = currentStatus;
  }

  void _showStatusNotification(Map<String, dynamic> project) {
    if (_context == null) return;

    final title = project['title'] ?? 'Project';
    final status = project['status'] ?? 'unknown';
    final videoUrl = project['videoUrl'];

    String message;
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case 'completed':
        if (videoUrl != null && videoUrl.isNotEmpty) {
          message = 'Your video "$title" is ready to view!';
          backgroundColor = Colors.green;
          icon = Icons.check_circle;
        } else {
          message = 'Video "$title" processing completed';
          backgroundColor = Colors.blue;
          icon = Icons.info;
        }
        break;
      case 'failed':
        message = 'Video "$title" generation failed';
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case 'processing':
        message = 'Video "$title" is now processing';
        backgroundColor = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      default:
        return; // Don't show notification for other statuses
    }

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: status == 'completed' && videoUrl != null && videoUrl.isNotEmpty
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to project detail or video player
                  // This would be implemented based on your navigation structure
                },
              )
            : null,
      ),
    );
  }

  void dispose() {
    _context = null;
    _lastStatus.clear();
  }
}
