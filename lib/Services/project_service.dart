import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/project_model.dart';
import 'Api/api_service.dart';

class ProjectService {
  static const String _projectsCacheKey = 'cached_projects';
  static const String _lastFetchKey = 'projects_last_fetch';
  static const Duration _cacheValidity = Duration(minutes: 30);

  // Fetch projects from API with caching
  static Future<List<ProjectModel>> fetchProjects({
    String? status,
    String? type,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedProjects = await _getCachedProjects();
        if (cachedProjects.isNotEmpty && await _isCacheValid()) {
          return _filterProjects(cachedProjects, status: status, type: type);
        }
      }

      // Fetch from API
      final response = await ApiService.getVideos(
        status: status,
        limit: 100, // Get more projects
        page: 1,
      );

      final List<ProjectModel> projects = [];
      if (response['data'] != null) {
        final List<dynamic> projectsJson =
            response['data']['videos'] ?? response['data'];
        for (var json in projectsJson) {
          try {
            projects.add(ProjectModel.fromJson(json));
          } catch (e) {
            print('Error parsing project: $e');
            continue;
          }
        }
      }

      // Cache the results
      await _cacheProjects(projects);

      return _filterProjects(projects, status: status, type: type);
    } catch (e) {
      print('Error fetching projects from API: $e');

      // Fallback to cached data
      final cachedProjects = await _getCachedProjects();
      if (cachedProjects.isNotEmpty) {
        return _filterProjects(cachedProjects, status: status, type: type);
      }

      // If no cache, return sample data for development
      return _getSampleProjects();
    }
  }

  // Create new project
  static Future<ProjectModel?> createProject({
    required String title,
    required String description,
    required String style,
    required String voice,
    required int duration,
    String? avatarId,
    String type = 'text-based',
    String aspectRatio = '9:16',
    int resolution = 1080,
    bool withAudio = true,
    bool withSubtitles = true,
    bool withLipSync = true,
  }) async {
    try {
      Map<String, dynamic> response;

      if (type == 'avatar-based' && avatarId != null) {
        response = await ApiService.createVideo(
          avatarId: avatarId,
          title: title,
          script: description,
        );
      } else {
        response = await ApiService.createTextBasedVideo(
          title: title,
          description: description,
          style: style,
          voice: voice,
          duration: duration,
          aspectRatio: aspectRatio,
          resolution: resolution,
          withAudio: withAudio,
          withSubtitles: withSubtitles,
          withLipSync: withLipSync,
        );
      }

      if (response['data'] != null) {
        final project = ProjectModel.fromJson(response['data']);

        // Update cache
        await _addProjectToCache(project);

        return project;
      }

      return null;
    } catch (e) {
      print('Error creating project: $e');
      rethrow;
    }
  }

  // Delete project
  static Future<bool> deleteProject(String projectId) async {
    try {
      await ApiService.deleteVideo(projectId);

      // Remove from cache
      await _removeProjectFromCache(projectId);

      return true;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }

  // Get single project
  static Future<ProjectModel?> getProject(String projectId) async {
    try {
      final response = await ApiService.getVideo(projectId);
      if (response['data'] != null) {
        return ProjectModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error fetching project: $e');

      // Try to find in cache
      final cachedProjects = await _getCachedProjects();
      try {
        return cachedProjects.firstWhere((p) => p.id == projectId);
      } catch (e) {
        return null;
      }
    }
  }

  // Filter projects by status and type
  static List<ProjectModel> _filterProjects(
    List<ProjectModel> projects, {
    String? status,
    String? type,
  }) {
    var filtered = projects;

    if (status != null && status.toLowerCase() != 'all') {
      filtered = filtered
          .where((p) => p.status.toLowerCase() == status.toLowerCase())
          .toList();
    }

    if (type != null) {
      filtered = filtered
          .where((p) => p.type.toLowerCase() == type.toLowerCase())
          .toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  // Cache management methods
  static Future<void> _cacheProjects(List<ProjectModel> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = projects.map((p) => p.toJson()).toList();
      await prefs.setString(_projectsCacheKey, json.encode(projectsJson));
      await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching projects: $e');
    }
  }

  static Future<List<ProjectModel>> _getCachedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_projectsCacheKey);
      if (cachedData != null) {
        final List<dynamic> projectsJson = json.decode(cachedData);
        return projectsJson.map((json) => ProjectModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading cached projects: $e');
    }
    return [];
  }

  static Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_lastFetchKey);
      if (lastFetch != null) {
        final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
        return DateTime.now().difference(lastFetchTime) < _cacheValidity;
      }
    } catch (e) {
      print('Error checking cache validity: $e');
    }
    return false;
  }

  static Future<void> _addProjectToCache(ProjectModel project) async {
    try {
      final projects = await _getCachedProjects();
      projects.insert(0, project); // Add to beginning
      await _cacheProjects(projects);
    } catch (e) {
      print('Error adding project to cache: $e');
    }
  }

  static Future<void> _removeProjectFromCache(String projectId) async {
    try {
      final projects = await _getCachedProjects();
      projects.removeWhere((p) => p.id == projectId);
      await _cacheProjects(projects);
    } catch (e) {
      print('Error removing project from cache: $e');
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_projectsCacheKey);
      await prefs.remove(_lastFetchKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Sample data for development/testing
  static List<ProjectModel> _getSampleProjects() {
    return [
      ProjectModel(
        id: 'sample_1',
        title: 'Welcome Video',
        description: 'Company welcome message for new employees',
        thumbnailUrl: 'images/project-card.png',
        status: 'completed',
        type: 'text-based',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        duration: 45,
        style: 'professional',
        voice: 'sarah',
      ),
      ProjectModel(
        id: 'sample_2',
        title: 'Product Demo',
        description: 'Showcase of our latest product features',
        thumbnailUrl: 'images/project-card.png',
        status: 'processing',
        type: 'avatar-based',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        duration: 120,
        style: 'modern',
        voice: 'john',
        avatarId: 'avatar_123',
      ),
      ProjectModel(
        id: 'sample_3',
        title: 'Training Module',
        description: 'Employee safety training video',
        thumbnailUrl: 'images/project-card.png',
        status: 'draft',
        type: 'text-based',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        duration: 300,
        style: 'educational',
        voice: 'emma',
      ),
      ProjectModel(
        id: 'sample_4',
        title: 'Marketing Campaign',
        description: 'Promotional video for summer sale',
        thumbnailUrl: 'images/project-card.png',
        status: 'completed',
        type: 'avatar-based',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        duration: 60,
        style: 'energetic',
        voice: 'mike',
        avatarId: 'avatar_456',
      ),
      ProjectModel(
        id: 'sample_5',
        title: 'Customer Testimonial',
        description: 'Happy customer sharing their experience',
        thumbnailUrl: 'images/project-card.png',
        status: 'completed',
        type: 'text-based',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 6)),
        duration: 90,
        style: 'authentic',
        voice: 'lisa',
      ),
      ProjectModel(
        id: 'sample_6',
        title: 'Event Recap',
        description: 'Highlights from our annual conference',
        thumbnailUrl: 'images/project-card.png',
        status: 'failed',
        type: 'avatar-based',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        duration: 180,
        style: 'documentary',
        voice: 'alex',
        avatarId: 'avatar_789',
      ),
    ];
  }

  // Statistics methods
  static Future<Map<String, int>> getProjectStats() async {
    try {
      final projects = await fetchProjects();

      return {
        'total': projects.length,
        'completed': projects.where((p) => p.isCompleted).length,
        'processing': projects.where((p) => p.isProcessing).length,
        'draft': projects.where((p) => p.isDraft).length,
        'failed': projects.where((p) => p.isFailed).length,
      };
    } catch (e) {
      print('Error getting project stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'processing': 0,
        'draft': 0,
        'failed': 0,
      };
    }
  }
}
