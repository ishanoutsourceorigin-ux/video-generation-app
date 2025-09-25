import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to connect to host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // For web/desktop
  // static const String baseUrl = 'http://YOUR_COMPUTER_IP:5000/api'; // For physical device

  // Get auth headers with Firebase token
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // For development mode - return headers without auth
        return {'Content-Type': 'application/json'};
      }

      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      // Fallback for development
      return {'Content-Type': 'application/json'};
    }
  }

  // Avatar API methods
  static Future<Map<String, dynamic>> createAvatar({
    required String name,
    required String profession,
    required String gender,
    required String style,
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
      request.fields['style'] = style;

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
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'avatarId': avatarId,
        'title': title,
        'script': script,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/videos/create'),
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
        'type': 'text-based',
        'aspectRatio': aspectRatio ?? '9:16',
        'resolution': resolution ?? 1080,
        'withAudio': withAudio ?? true,
        'withSubtitles': withSubtitles ?? true,
        'withLipSync': withLipSync ?? true,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/videos/create-text-based'),
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
}
