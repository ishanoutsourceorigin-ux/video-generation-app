import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_gen_app/Config/cloudinary_config.dart';

class CloudinaryService {
  // Test Cloudinary configuration
  static void testConfiguration() {
    print('=== Cloudinary Configuration Test ===');
    print('Cloud Name: ${CloudinaryConfig.cloudName}');
    print('Upload Method: Simple Direct Upload');
    print('Upload URL: ${CloudinaryConfig.uploadUrl}');
    print('Is Configured: ${CloudinaryConfig.isConfigured}');
    print('=====================================');
  }

  static Future<String?> uploadImage(File imageFile) async {
    // Print configuration for debugging
    testConfiguration();

    // Check if Cloudinary is properly configured
    if (!CloudinaryConfig.isConfigured) {
      print('❌ ERROR: Cloudinary not configured!');
      print('📝 Fix: Go to lib/Config/cloudinary_config.dart');
      print(
        '🔧 Replace "your_cloud_name" with your actual Cloudinary cloud name',
      );
      return null;
    }

    try {
      final url = Uri.parse(CloudinaryConfig.uploadUrl);

      print('📤 Simple upload to Cloudinary (no preset)...');
      print('☁️  Cloud: ${CloudinaryConfig.cloudName}');

      final request = http.MultipartRequest('POST', url);

      // Simple upload with just the file - no preset, no folder
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      print('🚀 Sending request...');
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final secureUrl = data['secure_url'] as String?;
        print('✅ Simple upload successful!');
        print('🔗 URL: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Simple upload failed: ${response.statusCode}');
        print('📄 Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }
}
