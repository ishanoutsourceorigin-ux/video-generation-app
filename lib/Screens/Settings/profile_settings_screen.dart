import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_gen_app/Services/simple_cloudinary_service.dart';
import 'package:video_gen_app/Services/backend_service.dart';
import 'package:video_gen_app/Config/cloudinary_config.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isImageUploading = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.appBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Profile Picture Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.greyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.purpleColor.withValues(
                            alpha: 0.2,
                          ),
                          child: _isImageUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : (_selectedImage != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _selectedImage!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (user?.photoURL != null
                                          ? ClipOval(
                                              child: Image.network(
                                                user!.photoURL!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color: AppColors
                                                            .purpleColor,
                                                      );
                                                    },
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 50,
                                              color: AppColors.purpleColor,
                                            ))),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isImageUploading ? null : _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.purpleColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _isImageUploading ? null : _pickImage,
                      child: Text(
                        "Change Profile Picture",
                        style: TextStyle(
                          color: AppColors.purpleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap the camera icon to update your photo",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.greyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Display Name Field
                    const Text(
                      "Display Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RoundTextField(
                      label: "Display Name",
                      hint: "Enter your display name",
                      textEditingController: _nameController,
                      inputType: TextInputType.text,
                      bgColor: AppColors.appBgColor,
                      enabledBorderColor: AppColors.greyColor.withValues(
                        alpha: 0.3,
                      ),
                      focusedBorderColor: AppColors.purpleColor,
                    ),

                    const SizedBox(height: 20),

                    // Email Field (Read-only)
                    const Text(
                      "Email Address",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.greyColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _emailController.text,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.lock_outline,
                            color: Colors.grey.shade500,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Email address cannot be changed",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Account Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.blueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.blueColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.blueColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Account Information",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "• Account created: ${user?.metadata.creationTime?.toString().split(' ')[0] ?? 'Unknown'}\n"
                      "• Last sign in: ${user?.metadata.lastSignInTime?.toString().split(' ')[0] ?? 'Unknown'}\n",
                      // "• Account verified: ${user?.emailVerified == true ? 'Yes' : 'No'}",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Update Button
              RoundButton(
                title: _isLoading ? "Updating..." : "Update Profile",
                onPress: _isLoading ? () {} : _updateProfile,
                bgColor: _isLoading
                    ? AppColors.greyColor
                    : AppColors.purpleColor,
                borderRadius: 12,
                fontSize: 16,
                // padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Utils.flushBarErrorMessage('Please enter your name', context);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Utils.flushBarErrorMessage(
          'No user logged in. Please sign in first.',
          context,
        );
        return;
      }
      String? photoUrl = user.photoURL;
      if (_selectedImage != null) {
        setState(() => _isImageUploading = true);

        String? uploadedUrl;

        // Try backend upload first (more secure)
        try {
          final token = await user.getIdToken();
          if (token != null) {
            uploadedUrl = await BackendService.uploadProfilePicture(
              _selectedImage!,
              token,
            );
          }
        } catch (e) {
          print('Backend upload failed, trying direct Cloudinary upload: $e');
        }

        // Fallback to direct Cloudinary upload if backend fails
        if (uploadedUrl == null) {
          if (!CloudinaryConfig.isConfigured) {
            setState(() => _isImageUploading = false);
            Utils.flushBarErrorMessage(
              'Upload failed: Backend unavailable and Cloudinary not configured',
              context,
            );
            return;
          }

          uploadedUrl = await SimpleCloudinaryService.uploadImage(
            _selectedImage!,
          );
        }

        setState(() => _isImageUploading = false);

        if (uploadedUrl == null) {
          Utils.flushBarErrorMessage(
            'Image upload failed. Check console logs for details.',
            context,
          );
          return;
        }

        photoUrl = uploadedUrl;
      }
      await user.updateDisplayName(name);
      if (photoUrl != null && photoUrl != user.photoURL) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();
      Utils.flushBarErrorMessage(
        'Profile updated successfully!',
        context,
        success: true,
      );
    } catch (e) {
      Utils.flushBarErrorMessage('Failed to update profile: $e', context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
