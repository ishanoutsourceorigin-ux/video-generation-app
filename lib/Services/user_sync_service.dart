import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Service to ensure Firebase users are synced with MongoDB backend
class UserSyncService {
  static const String _baseUrl =
      'https://video-generation-app-dar3.onrender.com';

  /// Ensure current Firebase user exists in MongoDB backend
  /// This prevents "User not found" errors during purchases
  static Future<bool> ensureUserExistsInBackend() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No Firebase user logged in');
        return false;
      }

      print('🔄 Checking user existence in backend: ${user.uid}');

      // Get user token for authentication
      final token = await user.getIdToken();

      // Create a test request to backend that will trigger user creation if needed
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/user/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('✅ User exists in backend or was created successfully');
        return true;
      } else if (response.statusCode == 404) {
        // User not found, try to create via a different endpoint
        print('⚠️ User not found, triggering user creation...');
        return await _createUserInBackend();
      } else {
        print('❌ Backend user check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error checking user in backend: $e');
      return false;
    }
  }

  /// Create user in backend by making a profile update request
  static Future<bool> _createUserInBackend() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();

      // Make a profile update request which should trigger user creation
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/user/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'displayName':
                  user.displayName ?? user.email?.split('@')[0] ?? 'User',
              'email': user.email ?? '',
              'syncFromFirebase':
                  true, // Flag to indicate this is a sync request
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ User created in backend successfully');
        return true;
      } else {
        print('❌ Failed to create user in backend: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating user in backend: $e');
      return false;
    }
  }

  /// Get user profile from backend
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/user/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Sync user data from Firebase to backend
  static Future<bool> syncUserFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No Firebase user to sync');
        return false;
      }

      print('🔄 Syncing user from Firebase to backend...');
      print('👤 User details: ${user.uid}, ${user.email}, ${user.displayName}');

      // First ensure user exists
      final exists = await ensureUserExistsInBackend();
      if (!exists) {
        print('❌ Failed to ensure user exists in backend');
        return false;
      }

      print('✅ User sync completed successfully');
      return true;
    } catch (e) {
      print('❌ Error syncing user from Firebase: $e');
      return false;
    }
  }
}
