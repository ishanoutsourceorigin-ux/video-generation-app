/// Environment configuration for the CloneX Video Generator app
/// Manages different environments and their respective API endpoints
class Environment {
  /// Whether the app is running in production mode
  static const bool isProduction =
      false; // Set to true for production build with Render backend

  /// Development backend URL (local development)
  /// Use 10.0.2.2:5000 for Android emulator or your computer's IP for physical device
  static const String developmentUrl =
      'http://10.0.2.2:5000'; // Android emulator can access host via 10.0.2.2

  /// Production backend URL (Render deployment)
  static const String productionUrl =
      'https://video-generation-app-dar3.onrender.com';

  /// Current base URL based on environment
  static String get baseUrl => isProduction ? productionUrl : developmentUrl;

  /// API endpoints with base URL
  static String get apiUrl => '$baseUrl/api';

  /// Upload endpoints
  static String get uploadUrl => '$baseUrl/uploads';

  /// Avatar endpoints
  static String get avatarUrl => '$apiUrl/avatars';

  /// Video endpoints
  static String get videoUrl => '$apiUrl/videos';

  /// Project endpoints
  static String get projectUrl => '$apiUrl/projects';

  /// User endpoints
  static String get userUrl => '$apiUrl/user';

  /// Payment endpoints
  static String get paymentUrl => '$apiUrl/payments';

  /// WebSocket URL for real-time features
  static String get websocketUrl => isProduction
      ? 'wss://video-generation-app-dar3.onrender.com'
      : 'ws://localhost:5000';

  /// Environment name for debugging
  static String get environmentName =>
      isProduction ? 'Production' : 'Development';

  /// API timeout in milliseconds
  static const int apiTimeout = 30000; // 30 seconds

  /// Upload timeout in milliseconds
  static const int uploadTimeout = 120000; // 2 minutes

  /// Maximum file size for uploads (50MB)
  static const int maxFileSize = 50 * 1024 * 1024;

  /// Stripe publishable key (from backend .env)
  static const String stripePublishableKey =
      'pk_live_51PTnGbP6uDfzoCICEGXnJvPaFmiVs0pLn3nfw1RE9151TMVK45YnxBFfSZyHtKy7qyT2Xobgm8qWhUTkcLvbodGR008b5KUS3F';

  /// Cloudinary configuration
  static const String cloudinaryCloudName = 'dlmzsseud';

  /// Print environment info for debugging
  static void printEnvironmentInfo() {
    print('🌍 Environment: $environmentName');
    print('🔗 Base URL: $baseUrl');
    print('📡 API URL: $apiUrl');
    print('⏱️ API Timeout: ${apiTimeout}ms');
  }
}
