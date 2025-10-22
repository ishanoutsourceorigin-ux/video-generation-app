import 'package:flutter/material.dart';
import 'package:video_gen_app/Screens/Avatar/create_avatar.dart';
import 'package:video_gen_app/Screens/Video/generate_video_screen.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Utils/animated_page_route.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:video_gen_app/Services/credit_system_service.dart';

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
  int _userCredits = 0;

  @override
  void initState() {
    super.initState();
    _fetchAvatars();
    _fetchUserCredits();
  }

  Future<void> _fetchAvatars() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      print('🔍 Fetching avatars from API...');
      final response = await ApiService.getAvatars();
      // print('📋 API Response: $response');

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

  Future<void> _fetchUserCredits() async {
    try {
      final credits = await CreditSystemService.getUserCredits();
      setState(() {
        _userCredits = credits;
      });
    } catch (e) {
      print('❌ Error fetching user credits: $e');
      // Don't show error for credits, just keep it as 0
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
              title: const Text(
                "My Avatars",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                // Credit balance display
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purpleColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.purpleColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.purpleColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_userCredits',
                        style: TextStyle(
                          color: AppColors.purpleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      onRefresh: () async {
        await Future.wait([_fetchAvatars(), _fetchUserCredits()]);
      },
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

    return GestureDetector(
      onTap: () {
        // Navigate to avatar detail screen
        _navigateToAvatarDetail(avatar);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: status == 'active'
                ? [
                    AppColors.purpleColor.withValues(alpha: 0.1),
                    AppColors.blueColor.withValues(alpha: 0.05),
                  ]
                : [
                    AppColors.darkGreyColor,
                    AppColors.darkGreyColor.withValues(alpha: 0.8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: status == 'active'
                ? AppColors.purpleColor.withValues(alpha: 0.3)
                : AppColors.greyColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Enhanced Avatar circle with image or initials
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purpleColor, AppColors.blueColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: imageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  // Status indicator dot
                  if (status == 'active')
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),

              // Enhanced Avatar details
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'active'
                                ? Colors.green.withValues(alpha: 0.15)
                                : status == 'processing'
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: status == 'active'
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : status == 'processing'
                                  ? Colors.orange.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status == 'active' ? 'READY' : status.toUpperCase(),
                            style: TextStyle(
                              color: status == 'active'
                                  ? Colors.green
                                  : status == 'processing'
                                  ? Colors.orange
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            profession,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          color: Colors.grey.shade500,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatDate,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Enhanced Generate Video button (only for active avatars)
              if (status == 'active') ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    // Prevent navigation to detail screen when video button is tapped
                    final result = await Navigator.push(
                      context,
                      AnimatedPageRoute(
                        page: GenerateVideoScreen(avatar: avatar),
                      ),
                    );
                    // Refresh avatar list and credits after video generation
                    if (result == true) {
                      _fetchAvatars();
                      _fetchUserCredits();
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purpleColor, AppColors.blueColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ] else if (status == 'processing') ...[
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to avatar detail screen
  void _navigateToAvatarDetail(Map<String, dynamic> avatar) {
    // Show avatar details in a dialog or navigate to detail screen
    showDialog(
      context: context,
      builder: (context) => _buildAvatarDetailDialog(avatar),
    );
  }

  // Build avatar detail dialog
  Widget _buildAvatarDetailDialog(Map<String, dynamic> avatar) {
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

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkGreyColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.purpleColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Avatar Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Avatar image/initials
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.purpleColor, AppColors.blueColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imageUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
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
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Avatar details
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              profession,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: status == 'active'
                    ? Colors.green.withValues(alpha: 0.15)
                    : status == 'processing'
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: status == 'active'
                      ? Colors.green.withValues(alpha: 0.3)
                      : status == 'processing'
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                status == 'active' ? 'READY TO USE' : status.toUpperCase(),
                style: TextStyle(
                  color: status == 'active'
                      ? Colors.green
                      : status == 'processing'
                      ? Colors.orange
                      : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Created date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_outlined,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  createdAt.isNotEmpty
                      ? 'Created ${_formatCreationDate(createdAt)}'
                      : 'Recently created',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (status == 'active') ...[
              Row(
                children: [
                  Expanded(
                    child: RoundButton(
                      title: "Generate Video",
                      onPress: () async {
                        Navigator.pop(context); // Close dialog first
                        final result = await Navigator.push(
                          context,
                          AnimatedPageRoute(
                            page: GenerateVideoScreen(avatar: avatar),
                          ),
                        );
                        if (result == true) {
                          _fetchAvatars();
                        }
                      },
                      leadingIcon: Icons.videocam_rounded,
                      leadingIconColor: Colors.white,
                      bgColor: AppColors.purpleColor,
                      borderRadius: 12,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RoundButton(
                      title: "Delete Avatar",
                      onPress: () {
                        Navigator.pop(context); // Close dialog first
                        _showDeleteAvatarConfirmation(avatar);
                      },
                      leadingIcon: Icons.delete_outline,
                      leadingIconColor: Colors.white,
                      bgColor: Colors.red.shade600,
                      borderRadius: 12,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Show delete button for non-active avatars too
              Row(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status == 'processing'
                            ? 'Avatar is being processed...'
                            : 'Avatar not ready',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RoundButton(
                      title: "Delete Avatar",
                      onPress: () {
                        Navigator.pop(context); // Close dialog first
                        _showDeleteAvatarConfirmation(avatar);
                      },
                      leadingIcon: Icons.delete_outline,
                      leadingIconColor: Colors.white,
                      bgColor: Colors.red.shade600,
                      borderRadius: 12,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to format creation date
  String _formatCreationDate(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'recently';
    }
  }

  // Show delete avatar confirmation dialog
  void _showDeleteAvatarConfirmation(Map<String, dynamic> avatar) {
    final String name = avatar['name'] ?? 'Unknown';
    final String avatarId = avatar['_id'] ?? avatar['id'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGreyColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade400,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$name"?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. The avatar and all associated data will be permanently deleted.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAvatar(avatarId, name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Delete avatar method
  Future<void> _deleteAvatar(String avatarId, String avatarName) async {
    if (avatarId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete avatar: Invalid avatar ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkGreyColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deleting $avatarName...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );

      // Call delete API
      await ApiService.deleteAvatar(avatarId);

      // Close loading dialog
      Navigator.pop(context);

      // Refresh avatar list
      _fetchAvatars();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$avatarName deleted successfully',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error deleting avatar: ${e.toString().replaceFirst('Exception: ', '')}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
