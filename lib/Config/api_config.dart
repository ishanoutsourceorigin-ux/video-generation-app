import 'environment.dart';

// Backend API Configuration
class ApiConfig {
  // Get URLs from environment configuration
  static String get baseUrl =>
      Environment.baseUrl; // Fixed: Use baseUrl not apiUrl

  // Specific API Endpoints
  static String get uploadProfilePicture =>
      '${Environment.baseUrl}/api/user/profile/upload-picture';
  static String get getCloudinarySignature =>
      '${Environment.baseUrl}/api/user/cloudinary/signature';
  static String get getUserProfile => '${Environment.baseUrl}/api/user/profile';

  // Additional endpoints
  static String get avatarsUrl => Environment.avatarUrl;
  static String get videosUrl => Environment.videoUrl;
  static String get projectsUrl => Environment.projectUrl;
  static String get userUrl => Environment.userUrl;
  static String get paymentsUrl => Environment.paymentUrl;

  // Environment info
  static bool get isProduction => Environment.isProduction;
  static String get environmentName => Environment.environmentName;

  // Headers
  static Map<String, String> getAuthHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get multipartHeaders => {
    'Accept': 'application/json',
  };
}
