import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:video_gen_app/Config/api_config.dart';

class BackendService {
  // Upload profile picture via backend
  static Future<String?> uploadProfilePicture(
    File imageFile,
    String token,
  ) async {
    try {
      print('📤 Uploading image via backend...');

      final uri = Uri.parse(ApiConfig.uploadProfilePicture);

      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file with explicit content type
      final fileName = imageFile.path.split('/').last;
      String contentType = 'image/jpeg'; // Default

      // Determine content type based on file extension
      if (fileName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      print('🚀 Sending request to backend...');
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final imageUrl = data['imageUrl'] as String?;
        print('✅ Upload successful!');
        print('🔗 URL: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('📄 Response: $responseBody');

        // Parse error message if available
        try {
          final errorData = json.decode(responseBody);
          final errorMessage = errorData['error'];
          print('💡 Error: $errorMessage');
        } catch (e) {
          print('Could not parse error response');
        }

        return null;
      }
    } catch (e) {
      print('❌ Error uploading via backend: $e');
      return null;
    }
  }

  // Get Cloudinary signature from backend (alternative method)
  static Future<Map<String, dynamic>?> getCloudinarySignature(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getCloudinarySignature),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['signatureData'];
      } else {
        print('Failed to get Cloudinary signature: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting Cloudinary signature: $e');
      return null;
    }
  }
}
