import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:video_gen_app/Services/Api/api_service.dart';

class CreateAvatar extends StatefulWidget {
  const CreateAvatar({super.key});

  @override
  State<CreateAvatar> createState() => _CreateAvatarState();
}

class _CreateAvatarState extends State<CreateAvatar> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedStyle = 'Professional';
  File? _selectedImage;
  File? _selectedVoice;
  final ImagePicker _picker = ImagePicker();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          "Create AI Avatar",
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Create Your AI Avatar",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Customize your AI avatar with personal details",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Avatar Preview with Upload
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.blueColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.purpleColor,
                        width: 3,
                      ),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Upload Photo",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null)
                Center(
                  child: Text(
                    "Tap to change photo",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 32),

              // Name Input
              const Text(
                "Avatar Name",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RoundTextField(
                label: "Avatar Name",
                hint: "Enter avatar name (e.g., John Doe)",
                textEditingController: _nameController,
                inputType: TextInputType.text,
                bgColor: AppColors.darkGreyColor,
                enabledBorderColor: AppColors.greyColor.withOpacity(0.3),
                focusedBorderColor: AppColors.purpleColor,
              ),
              const SizedBox(height: 24),

              // Profession Input
              const Text(
                "Profession/Role",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RoundTextField(
                label: "Profession",
                hint: "Enter profession (e.g., Business Coach)",
                textEditingController: _professionController,
                inputType: TextInputType.text,
                bgColor: AppColors.darkGreyColor,
                enabledBorderColor: AppColors.greyColor.withOpacity(0.3),
                focusedBorderColor: AppColors.purpleColor,
              ),
              const SizedBox(height: 24),

              // Voice Upload Section
              const Text(
                "Voice Sample",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickVoice,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreyColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedVoice != null
                          ? AppColors.purpleColor
                          : AppColors.greyColor.withOpacity(0.3),
                      width: _selectedVoice != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedVoice != null ? Icons.audiotrack : Icons.mic,
                        color: _selectedVoice != null
                            ? AppColors.purpleColor
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedVoice != null
                              ? "Voice sample: ${_selectedVoice!.path.split('/').last}"
                              : "Upload voice sample (MP3, WAV, M4A)",
                          style: TextStyle(
                            color: _selectedVoice != null
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_selectedVoice != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedVoice = null),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Upload a 10-30 second clear audio sample for voice cloning",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Gender Selection
              const Text(
                "Gender",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedGender,
                items: ['Male', 'Female', 'Other'],
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 24),

              // Style Selection
              const Text(
                "Avatar Style",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedStyle,
                items: ['Professional', 'Casual', 'Formal', 'Creative'],
                onChanged: (value) => setState(() => _selectedStyle = value!),
              ),
              const SizedBox(height: 40),

              // Create Button
              RoundButton(
                title: _isCreating ? "Creating Avatar..." : "Create Avatar",
                onPress: _isCreating ? () {} : _createAvatar,
                leadingIcon: _isCreating ? null : Icons.add_circle,
                leadingIconColor: Colors.white,
                bgColor: _isCreating
                    ? AppColors.greyColor.withOpacity(0.5)
                    : AppColors.purpleColor,
                borderRadius: 12,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              RoundButton(
                title: "Cancel",
                onPress: () => Navigator.pop(context),
                bgColor: AppColors.greyColor.withOpacity(0.3),
                borderRadius: 12,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.darkGreyColor,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickVoice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        // Check file size (limit to 10MB)
        int fileSizeInBytes = await file.length();
        double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Voice file must be less than 10MB"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _selectedVoice = file;
        });
      }
    } catch (e) {
      print("Error picking voice file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking voice file: $e"),

          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createAvatar() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError("Please enter avatar name");
      return;
    }

    if (_professionController.text.trim().isEmpty) {
      _showError("Please enter profession");
      return;
    }

    if (_selectedImage == null) {
      _showError("Please upload a photo");
      return;
    }

    if (_selectedVoice == null) {
      _showError("Please upload a voice sample");
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      print("🚀 Starting avatar creation...");
      print("📝 Name: ${_nameController.text.trim()}");
      print("💼 Profession: ${_professionController.text.trim()}");
      print("👤 Gender: $_selectedGender");
      print("🎨 Style: $_selectedStyle");
      print("📸 Image path: ${_selectedImage?.path}");
      print("🎵 Voice path: ${_selectedVoice?.path}");

      final result = await ApiService.createAvatar(
        name: _nameController.text.trim(),
        profession: _professionController.text.trim(),
        gender: _selectedGender,
        style: _selectedStyle,
        imageFile: _selectedImage!,
        voiceFile: _selectedVoice!,
      );

      print("✅ Avatar creation successful: $result");

      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Avatar '${_nameController.text}' created successfully!",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      print("❌ Error creating avatar: $e");
      print("🔍 Error type: ${e.runtimeType}");
      print("📋 Full error details: $e");
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
