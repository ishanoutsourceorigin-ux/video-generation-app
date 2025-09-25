// Cloudinary Configuration
//
// To use this app with Cloudinary:
// 1. Sign up at https://cloudinary.com/
// 2. Go to your dashboard and get your cloud name
// 3. Create an unsigned upload preset:
//    - Go to Settings > Upload Presets
//    - Click "Add upload preset"
//    - Set Mode to "Unsigned"
//    - Set preset name to "profile_images" (or update the name in cloudinary_service.dart)
//    - Set folder to "profile_images"
//    - Save the preset
// 4. Update the values below with your actual Cloudinary details

class CloudinaryConfig {
  // Using the same Cloudinary cloud name as configured in backend/.env
  // CLOUDINARY_CLOUD_NAME=dlmzsseud
  static const String cloudName = 'dlmzsseud';

  // Try this preset first, if it doesn't work we'll try others
  static const String uploadPreset = 'profile_images';

  // Folder where images will be stored in Cloudinary (optional)
  static const String folder = 'profile_images';

  // Base URL for Cloudinary uploads (don't change this)
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // Check if Cloudinary is configured
  static bool get isConfigured => cloudName != 'your_cloud_name';
}
