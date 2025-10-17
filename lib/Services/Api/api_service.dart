import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../Config/environment.dart';

class ApiService {
  // Production Render URL
  static String get baseUrl => Environment.apiUrl;
  // Local development URLs (commented out for production)
  // static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // For web/desktop

  // Get auth headers with Firebase token
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // print('🔐 Current Firebase User: ${user?.uid ?? 'Not logged in'}');

      if (user == null) {
        print('❌ No user logged in - using dev mode headers');
        // For development mode - return headers without auth
        return {'Content-Type': 'application/json'};                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
      }

      final token = await user.getIdToken();
      // print('🔑 Got Firebase token: ${token?.substring(0, 20) ?? 'null'}...');
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('❌ Error getting auth headers: $e');
      // Fallback for development                                                                                              
      return {'Content-Type': 'application/json'};
    }
  }

  // Avatar API methods
  static Future<Map<String, dynamic>> createAvatar({
    required String name,
    required String profession,
    required String gender,
    required File imageFile,
    required File voiceFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/avatars/create'),
      );

      // Add headers (handle auth gracefully)
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          request.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        // Continue without auth for development mode
        print('Auth not available, continuing in dev mode');
      }

      // Add text fields
      request.fields['name'] = name;
      request.fields['profession'] = profession;
      request.fields['gender'] = gender;

      // Add files
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('voice', voiceFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to create avatar');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getAvatars({
    String? status,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {'limit': limit.toString(), 'page': page.toString()};

      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(
        '$baseUrl/avatars',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch avatars');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getAvatar(String avatarId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/avatars/$avatarId'),
        headers: headers,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch avatar');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> deleteAvatar(String avatarId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/avatars/$avatarId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete avatar');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Video API methods
  static Future<Map<String, dynamic>> createVideo({
    required String avatarId,
    required String title,
    required String script,
    String? aspectRatio,
    String? expression,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'avatarId': avatarId,
        'title': title,
        'script': script,
        if (aspectRatio != null) 'aspectRatio': aspectRatio,
        if (expression != null) 'expression': expression,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/avatar-videos/create'),
        headers: headers,
        body: body,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to create video');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createTextBasedVideo({
    required String title,
    required String description,
    required String style,
    required String voice,
    required int duration,
    String? aspectRatio,
    int? resolution,
    bool? withAudio,
    bool? withSubtitles,
    bool? withLipSync,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'title': title,
        'description': description,
        'style': style,
        'voice': voice,
        'duration': duration,
        'aspectRatio': aspectRatio ?? '9:16',
        'resolution': resolution ?? 1080,
        'withAudio': withAudio ?? true,
        'withSubtitles': withSubtitles ?? true,
        'withLipSync': withLipSync ?? false,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/projects/create-text-based'),
        headers: headers,
        body: body,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to create text-based video');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getVideos({
    String? status,
    String? avatarId,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {'limit': limit.toString(), 'page': page.toString()};

      if (status != null) {
        queryParams['status'] = status;
      }

      if (avatarId != null) {
        queryParams['avatarId'] = avatarId;
      }

      final uri = Uri.parse(
        '$baseUrl/videos',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch videos');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getVideo(String videoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId'),
        headers: headers,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch video');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> deleteVideo(String videoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/videos/$videoId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete video');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Project Management API methods
  static Future<Map<String, dynamic>> getProjects({
    String? status,
    String? type,
    int limit = 20,
    int page = 1,
    String sort = 'createdAt',
    String order = 'desc',
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {
        'limit': limit.toString(),
        'page': page.toString(),
        'sort': sort,
        'order': order,
      };

      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse(
        '$baseUrl/projects',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch projects');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProject(String projectId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: headers,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch project');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProjectStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/stats'),
        headers: headers,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch project statistics');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode(updates);

      final response = await http.put(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: headers,
        body: body,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to update project');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> deleteProject(String projectId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete project');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> retryProject(String projectId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/retry'),
        headers: headers,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to retry project');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // VEO-3 specific video generation method
  static Future<Map<String, dynamic>> createVeo3Video({
    required String title,
    required String promptText,
    required int duration,
    required String ratio,
    int? seed,
  }) async {
    try {
      print('🎬 === VEO-3 VIDEO GENERATION ===');
      print('📋 VEO-3 Project details:');
      print('  📝 Title: $title');
      print('  📝 Prompt: $promptText');
      print('  ⏱️ Duration: ${duration}s (max 8s for VEO-3)');
      print('  📐 Ratio: $ratio');
      print('  🎲 Seed: ${seed ?? 'random'}');

      // Validate VEO-3 constraints on frontend
      if (duration != 8) {
        print(
          '⚠️ VEO-3 Duration: Adjusting from ${duration}s to 8s (VEO-3 requirement)',
        );
        duration = 8; // VEO-3 requires exactly 8 seconds
      }

      if (!['1280:720', '720:1280'].contains(ratio)) {
        throw Exception(
          'VEO-3 only supports 1280:720 (landscape) or 720:1280 (portrait) ratios',
        );
      }

      final headers = await _getHeaders();
      print('🔑 Headers prepared');

      final body = json.encode({
        'title': title,
        'description': promptText,
        'aspectRatio': ratio == '1280:720' ? '16:9' : '9:16',
        'resolution': 720, // VEO-3 uses 720p
        'duration': duration,
        'model': 'veo-3', // Specify VEO-3 model
        'veo3Config': {'promptText': promptText, 'ratio': ratio, 'seed': seed},
      });

      print('📦 Request body created for VEO-3');
      print('🌐 Sending VEO-3 request to: $baseUrl/projects/create-text-based');

      final response = await http.post(
        Uri.parse('$baseUrl/projects/create-text-based'),
        headers: headers,
        body: body,
      );

      print('📡 VEO-3 Response received!');
      print('📊 Response status: ${response.statusCode}');

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        print('✅ VEO-3 Project created successfully!');
        return data;
      } else {
        print('❌ VEO-3 Server error: ${data['error']}');
        throw Exception(
          data['error'] ?? 'Failed to create VEO-3 video project',
        );
      }
    } catch (e) {
      print('❌ Error creating VEO-3 video: $e');
      throw Exception('VEO-3 Error: $e');
    }
  }

  static Future<Map<String, dynamic>> createTextBasedProject({
    required String title,
    required String description,
    required String aspectRatio,
    required String resolution,
    required String duration,
  }) async {
    try {
      print('🎬 === STARTING TEXT-BASED PROJECT CREATION ===');
      print('📋 Project details:');
      print('  📝 Title: $title');
      print('  📝 Description: $description');
      print('  📐 Aspect Ratio: $aspectRatio');
      print('  🔧 Resolution: $resolution');
      print('  ⏱️ Duration: $duration');

      final headers = await _getHeaders();
      print('🔑 Headers prepared');

      final body = json.encode({
        'title': title,
        'description': description,
        'aspectRatio': aspectRatio,
        'resolution': int.parse(resolution),
        'duration': int.parse(duration),
      });

      print('� Request body created: $body');
      print('🌐 Sending request to: $baseUrl/projects/create-text-based');

      final response = await http.post(
        Uri.parse('$baseUrl/projects/create-text-based'),
        headers: headers,
        body: body,
      );

      print('📡 Response received!');
      print('📊 Response status: ${response.statusCode}');
      print('� Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        print('✅ Project created successfully!');
        print('📋 Project data: ${data['project']}');
        return data;
      } else {
        print('❌ Server error: ${data['error']}');
        throw Exception(data['error'] ?? 'Failed to create text-based project');
      }
    } catch (e) {
      print('❌ Error creating text-based project: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createAvatarBasedVideo({
    required String title,
    required String script,
    required String avatarId,
    String? aspectRatio,
    int? resolution,
    int? duration,
    String? style,
    String? provider,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'title': title,
        'script': script,
        'avatarId': avatarId,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/avatar-videos/create'),
        headers: headers,
        body: body,
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to create avatar-based video');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
