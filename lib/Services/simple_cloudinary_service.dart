import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SimpleCloudinaryService {
  static const String cloudName = 'dlmzsseud';
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // Test configuration
  static void testConfiguration() {
    print('=== Simple Cloudinary Test ===');
    print('Cloud Name: $cloudName');
    print('Upload Method: Using profile_images preset');
    print('Upload URL: $uploadUrl');
    print('================================');
  }

  static Future<String?> uploadImage(File imageFile) async {
    testConfiguration();

    try {
      final url = Uri.parse(uploadUrl);

      print('📤 Simple Cloudinary upload...');
      print('☁️ Cloud: $cloudName');

      final request = http.MultipartRequest('POST', url);

      // Add the upload preset we created in Cloudinary
      request.fields['upload_preset'] = 'profile_images';

      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      print('🚀 Uploading...');
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final secureUrl = data['secure_url'] as String?;
        print('✅ Upload successful!');
        print('🔗 URL: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('📄 Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }
}
