import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Services/project_service.dart';

void main() async {
  print("🔍 Testing backend projects...");

  try {
    // Test 1: Direct API call
    print("\n📡 Testing direct API call:");
    final apiResponse = await ApiService.getVideos(limit: 100, page: 1);
    print("API Response: $apiResponse");

    if (apiResponse['data'] != null) {
      final videos = apiResponse['data']['videos'] ?? apiResponse['data'];
      if (videos is List) {
        print("✅ Found ${videos.length} projects in backend");

        // Show first few projects
        for (int i = 0; i < videos.length && i < 3; i++) {
          final project = videos[i];
          print(
            "Project ${i + 1}: ${project['title'] ?? 'No title'} - ${project['status'] ?? 'No status'}",
          );
        }
      } else {
        print("❌ Videos data is not a list: ${videos.runtimeType}");
      }
    } else {
      print("❌ No data field in response");
    }
  } catch (e) {
    print("❌ API Error: $e");

    // Test 2: Try ProjectService (which includes sample data fallback)
    print("\n📦 Testing ProjectService (with fallback):");
    try {
      final projects = await ProjectService.fetchProjects();
      print("✅ ProjectService returned ${projects.length} projects");

      // Show project details
      for (int i = 0; i < projects.length && i < 5; i++) {
        final project = projects[i];
        print(
          "${i + 1}. ${project.title} - ${project.status} (${project.type})",
        );
      }

      // Show statistics
      final stats = await ProjectService.getProjectStats();
      print("\n📊 Project Statistics:");
      stats.forEach((key, value) {
        print("  $key: $value");
      });
    } catch (serviceError) {
      print("❌ ProjectService Error: $serviceError");
    }
  }

  print("\n✅ Test completed!");
}
