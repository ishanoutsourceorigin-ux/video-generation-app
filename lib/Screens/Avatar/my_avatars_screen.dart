import 'package:flutter/material.dart';
import 'package:video_gen_app/Screens/Avatar/create_avatar.dart';
import 'package:video_gen_app/Screens/Video/generate_video_screen.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';

class MyAvatarsScreen extends StatefulWidget {
  final bool showAppBar;

  const MyAvatarsScreen({super.key, this.showAppBar = true});

  @override
  State<MyAvatarsScreen> createState() => _MyAvatarsScreenState();
}

class _MyAvatarsScreenState extends State<MyAvatarsScreen> {
  List<dynamic> _avatars = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchAvatars();
  }

  Future<void> _fetchAvatars() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      print('🔍 Fetching avatars from API...');
      final response = await ApiService.getAvatars();
      print('📋 API Response: $response');

      final avatars = response['avatars'] ?? [];
      print('👥 Found ${avatars.length} avatars');

      setState(() {
        _avatars = avatars;
        _isLoading = false;
      });

      if (avatars.isEmpty) {
        print('⚠️  No avatars found - might be user ID mismatch in dev mode');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('❌ Error fetching avatars: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.appBgColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),

              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              const Text(
                "Your AI Avatars",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Manage and create your personalized AI avatars",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Create new avatar button
              RoundButton(
                title: "Create New Avatar",
                onPress: () async {
                  await Navigator.push(
                    context,
                    AnimatedPageRoute(page: const CreateAvatar()),
                  );
                  // Refresh the avatar list when returning from create screen
                  _fetchAvatars();
                },
                leadingIcon: Icons.add,
                leadingIconColor: Colors.white,
                bgColor: AppColors.purpleColor,
                borderRadius: 12,
                fontSize: 16,
                // padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              const SizedBox(height: 24),

              // Avatars grid
              const Text(
                "Available Avatars",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(child: _buildAvatarsGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarsGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              "Error Loading Avatars",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            RoundButton(
              title: "Retry",
              onPress: _fetchAvatars,
              leadingIcon: Icons.refresh,
              leadingIconColor: Colors.white,
              bgColor: AppColors.purpleColor,
              borderRadius: 12,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ],
        ),
      );
    }

    if (_avatars.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.purpleColor,
      backgroundColor: AppColors.darkGreyColor,
      onRefresh: _fetchAvatars,
      child: ListView.builder(
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatar = _avatars[index];
          return _buildAvatarListItem(avatar);
        },
      ),
    );
  }

  Widget _buildAvatarListItem(Map<String, dynamic> avatar) {
    final String name = avatar['name'] ?? 'Unknown';
    final String profession = avatar['profession'] ?? 'No profession';
    final String status = avatar['status'] ?? 'unknown';
    final String createdAt = avatar['createdAt'] ?? '';
    final String imageUrl = avatar['imageUrl'] ?? '';

    // Generate initials from name
    String initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
              .join('')
              .substring(0, 2.clamp(0, name.split(' ').length))
        : 'NA';

    // Format date
    String formatDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays == 0) {
          formatDate = 'Created today';
        } else if (difference.inDays == 1) {
          formatDate = 'Created yesterday';
        } else if (difference.inDays < 7) {
          formatDate = 'Created ${difference.inDays} days ago';
        } else {
          formatDate = 'Created ${date.day}/${date.month}/${date.year}';
        }
      } catch (e) {
        formatDate = 'Recently created';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'active'
              ? AppColors.purpleColor.withOpacity(0.5)
              : AppColors.greyColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar circle with image or initials
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.blueColor,
              shape: BoxShape.circle,
            ),
            child: imageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Avatar details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? Colors.green.withOpacity(0.2)
                            : status == 'processing'
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'active'
                              ? Colors.green
                              : status == 'processing'
                              ? Colors.orange
                              : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  profession,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),

          // Generate Video button (only for active avatars)
          if (status == 'active') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  AnimatedPageRoute(page: GenerateVideoScreen(avatar: avatar)),
                );
                // Refresh avatar list if needed after video generation
                if (result == true) {
                  _fetchAvatars();
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purpleColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No Avatars Created",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first AI avatar to get started",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          RoundButton(
            title: "Create Your First Avatar",
            onPress: () async {
              await Navigator.push(
                context,
                AnimatedPageRoute(page: const CreateAvatar()),
              );
              // Refresh the avatar list when returning from create screen
              _fetchAvatars();
            },
            leadingIcon: Icons.add,
            leadingIconColor: Colors.white,
            bgColor: AppColors.purpleColor,
            borderRadius: 12,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
        ],
      ),
    );
  }
}
