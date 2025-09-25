// Backend API Configuration
class ApiConfig {
  // Backend URLs for different environments
  // Use 10.0.2.2 for Android emulator to access localhost
  static const String localUrl = 'http://10.0.2.2:5000/api';
  static const String productionUrl =
      'https://video-generator-web-backend.onrender.com/api';

  // Current environment - change this based on your setup
  static const bool isProduction = false;

  // Get the current backend URL
  static String get baseUrl => isProduction ? productionUrl : localUrl;

  // API Endpoints
  static String get uploadProfilePicture =>
      '$baseUrl/user/profile/upload-picture';
  static String get getCloudinarySignature =>
      '$baseUrl/user/cloudinary/signature';
  static String get getUserProfile => '$baseUrl/user/profile';

  // Headers
  static Map<String, String> getAuthHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}
