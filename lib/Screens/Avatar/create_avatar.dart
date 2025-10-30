import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';
import 'package:video_gen_app/Component/round_button.dart';
import 'package:video_gen_app/Component/round_textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:video_gen_app/Services/Api/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';

class CreateAvatar extends StatefulWidget {
  const CreateAvatar({super.key});

  @override
  State<CreateAvatar> createState() => _CreateAvatarState();
}

class _CreateAvatarState extends State<CreateAvatar> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  String _selectedGender = 'Male';
  File? _selectedImage;
  File? _selectedVoice;
  final ImagePicker _picker = ImagePicker();
  bool _isCreating = false;
  FlutterSoundRecorder? _audioRecorder;

  // Voice recording variables
  bool _isRecording = false;
  bool _isHolding = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  String _voiceSource = 'none'; // 'none', 'recorded', 'uploaded'
  OverlayEntry? _recordingOverlay;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _timer?.cancel();
    _hideRecordingOverlay();
    _audioRecorder?.closeRecorder();
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
      body: GestureDetector(
        onTap: () {
          // Stop recording if user taps anywhere on screen
          if (_isRecording) {
            print("🛑 Screen tapped - stopping recording");
            _stopRecording();
          }
        },
        child: SafeArea(
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
                                color: Colors.black.withValues(alpha: 0.3),
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
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blueColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.blueColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.blueColor,
                            size: 20,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tip for Best Results",
                            style: TextStyle(
                              color: AppColors.blueColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Upload a clear, front-facing photo with good lighting for best AI avatar quality.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
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
                  enabledBorderColor: AppColors.greyColor.withValues(
                    alpha: 0.3,
                  ),
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
                  enabledBorderColor: AppColors.greyColor.withValues(
                    alpha: 0.3,
                  ),
                  focusedBorderColor: AppColors.purpleColor,
                ),
                const SizedBox(height: 24),

                // Voice Recording/Upload Section
                const Text(
                  "Voice Sample",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Voice options row
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Record Voice Button
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (details) {
                            print("👆 Tap down detected");
                            setState(() {
                              _isHolding = true;
                            });
                            if (!_isRecording) {
                              _startRecording();
                            }
                          },
                          onTapUp: (details) {
                            print("👆 Tap up detected");
                            setState(() {
                              _isHolding = false;
                            });
                            if (_isRecording) {
                              _stopRecording();
                            }
                          },
                          onTapCancel: () {
                            print("👆 Tap cancelled");
                            setState(() {
                              _isHolding = false;
                            });
                            if (_isRecording) {
                              _stopRecording();
                            }
                          },
                          child: Container(
                            height: 65,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : (_isHolding
                                        ? AppColors.purpleColor.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.darkGreyColor),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isRecording
                                    ? Colors.red
                                    : (_voiceSource == 'recorded'
                                          ? AppColors.purpleColor
                                          : AppColors.greyColor.withValues(
                                              alpha: 0.3,
                                            )),
                                width:
                                    _isRecording || _voiceSource == 'recorded'
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  flex: 3,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Pulsing animation for recording
                                      if (_isRecording)
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 1000,
                                          ),
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        transform: _isHolding
                                            ? (Matrix4.identity()..scale(1.05))
                                            : Matrix4.identity(),
                                        child: Icon(
                                          _isRecording
                                              ? Icons.mic
                                              : Icons.keyboard_voice,
                                          color: _isRecording
                                              ? Colors.red
                                              : (_voiceSource == 'recorded'
                                                    ? AppColors.purpleColor
                                                    : Colors.grey),
                                          size: _isRecording ? 20 : 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Flexible(
                                  flex: 1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _isRecording
                                          ? "${_recordDuration.inSeconds}s"
                                          : (_voiceSource == 'recorded'
                                                ? "Recorded"
                                                : "Hold"),
                                      style: TextStyle(
                                        color: _isRecording
                                            ? Colors.red
                                            : (_voiceSource == 'recorded'
                                                  ? AppColors.purpleColor
                                                  : Colors.grey),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Upload Voice Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickVoice,
                          child: Container(
                            height: 65,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.darkGreyColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _voiceSource == 'uploaded'
                                    ? AppColors.purpleColor
                                    : AppColors.greyColor.withValues(
                                        alpha: 0.3,
                                      ),
                                width: _voiceSource == 'uploaded' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  flex: 3,
                                  child: Icon(
                                    Icons.upload_file,
                                    color: _voiceSource == 'uploaded'
                                        ? AppColors.purpleColor
                                        : Colors.grey,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Flexible(
                                  flex: 1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _voiceSource == 'uploaded'
                                          ? "Done"
                                          : "Upload",
                                      style: TextStyle(
                                        color: _voiceSource == 'uploaded'
                                            ? AppColors.purpleColor
                                            : Colors.grey,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Voice file name or recording info
                if (_selectedVoice != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.purpleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.purpleColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.audiotrack,
                          color: AppColors.purpleColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _voiceSource == 'recorded'
                                ? "Voice recorded (${_recordDuration.inSeconds}s)"
                                : "File: ${_selectedVoice!.path.split('/').last}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedVoice = null;
                            _voiceSource = 'none';
                            _recordDuration = Duration.zero;
                          }),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blueColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.blueColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.blueColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Hold record button for 3-30s or upload audio (MP3, WAV, M4A)",
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 9,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                  onChanged: (value) =>
                      setState(() => _selectedGender = value!),
                ),
                const SizedBox(height: 40),

                // Create Button
                RoundButton(
                  title: _isCreating ? "Creating Avatar..." : "Create Avatar",
                  onPress: _isCreating ? () {} : _createAvatar,
                  leadingIcon: _isCreating ? null : Icons.add_circle,
                  leadingIconColor: Colors.white,
                  bgColor: _isCreating
                      ? AppColors.greyColor.withValues(alpha: 0.5)
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
                  bgColor: AppColors.greyColor.withValues(alpha: 0.3),
                  borderRadius: 12,
                  fontSize: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ],
            ),
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
        border: Border.all(color: AppColors.greyColor.withValues(alpha: 0.3)),
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
          _voiceSource = 'uploaded';
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

  Future<void> _startRecording() async {
    try {
      // Check permission first
      final currentPermission = await Permission.microphone.status;

      if (!currentPermission.isGranted) {
        print("🔐 Requesting microphone permission...");
        // Store the holding state before requesting permission
        final wasHolding = _isHolding;

        final permission = await Permission.microphone.request();
        if (!permission.isGranted) {
          print("❌ Microphone permission denied");
          _showError("Microphone permission required for voice recording");
          setState(() {
            _isHolding = false;
          });
          return;
        }
        print("✅ Microphone permission granted");

        // Check if user was holding and is still holding after permission dialog
        if (!wasHolding || !_isHolding) {
          print(
            "🚫 User released button during permission request, not starting recording",
          );
          setState(() {
            _isHolding = false;
          });
          return;
        }
      }

      // Double check if still holding before starting recording
      if (!_isHolding) {
        print("🚫 User not holding button, not starting recording");
        return;
      }

      print("🎙️ Starting recording...");

      // Get application documents directory for recording
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordedFilePath = '${directory.path}/recorded_voice_$timestamp.aac';

      // Start recording with AAC format (compatible and converts to MP3 on Cloudinary)
      await _audioRecorder!.startRecorder(
        toFile: _recordedFilePath!,
        codec: Codec.aacMP4,
      );

      setState(() {
        _isRecording = true;
        _isHolding = true;
        _recordDuration = Duration.zero;
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordDuration = Duration(seconds: timer.tick);
          });

          // Auto stop after 30 seconds
          if (_recordDuration.inSeconds >= 30) {
            _stopRecording();
          }
        }
      });

      // Show recording overlay
      _showRecordingOverlay();

      print("🎙️ Recording started to: $_recordedFilePath");
    } catch (e) {
      print("Error starting recording: $e");
      _showError("Failed to start recording: $e");
      setState(() {
        _isRecording = false;
        _isHolding = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      print("🛑 Stopping recording... Duration: ${_recordDuration.inSeconds}s");

      // Stop the actual recording
      final recordedPath = await _audioRecorder!.stopRecorder();

      _timer?.cancel();
      _hideRecordingOverlay();

      setState(() {
        _isRecording = false;
        _isHolding = false;
      });

      // Check if recording was long enough
      if (_recordDuration.inSeconds >= 3) {
        if (recordedPath != null && await File(recordedPath).exists()) {
          final recordedFile = File(recordedPath);
          final fileSize = await recordedFile.length();

          print("🎵 Recording saved to: $recordedPath");
          print("📁 File size: $fileSize bytes");
          print("📂 File exists: ${await recordedFile.exists()}");
          print("🎧 File extension: ${recordedFile.path.split('.').last}");

          // Check if file has content
          if (fileSize > 0) {
            setState(() {
              _selectedVoice = recordedFile;
              _voiceSource = 'recorded';
            });
          } else {
            print("❌ Recorded file is empty!");
            _showError("Recording failed - file is empty");
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text("Voice recorded (${_recordDuration.inSeconds}s)"),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          _showError("Recording failed - no audio file created");
          setState(() {
            _recordDuration = Duration.zero;
          });
        }
      } else if (_recordDuration.inSeconds > 0 &&
          _recordDuration.inSeconds < 3) {
        _showError("Recording too short! Hold for at least 3 seconds.");
        setState(() {
          _recordDuration = Duration.zero;
        });

        // Clean up the short recording file
        if (recordedPath != null && await File(recordedPath).exists()) {
          await File(recordedPath).delete();
        }
      }
    } catch (e) {
      print("Error stopping recording: $e");
      _showError("Failed to stop recording: $e");
      setState(() {
        _isRecording = false;
        _isHolding = false;
        _recordDuration = Duration.zero;
      });
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
      print("📸 Image path: ${_selectedImage?.path}");
      print("🎵 Voice path: ${_selectedVoice?.path}");

      final result = await ApiService.createAvatar(
        name: _nameController.text.trim(),
        profession: _professionController.text.trim(),
        gender: _selectedGender,
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

  void _showRecordingOverlay() {
    _hideRecordingOverlay(); // Remove any existing overlay

    _recordingOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          onTap: () {
            // Cancel recording if user taps outside the recording container
            print(
              "🚫 User tapped outside recording overlay - canceling recording",
            );
            _cancelRecording();
          },
          child: Material(
            color: Colors.black.withValues(
              alpha: 0.3,
            ), // Semi-transparent background
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Prevent event bubbling when tapping on the recording container
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        child: Icon(Icons.mic, color: Colors.red, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Recording...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) => Text(
                          "${_recordDuration.inSeconds}s",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Tap outside to cancel recording",
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_recordingOverlay!);
  }

  void _hideRecordingOverlay() {
    _recordingOverlay?.remove();
    _recordingOverlay = null;
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;

    try {
      print("🚫 Canceling recording...");

      // Stop the actual recording
      await _audioRecorder!.stopRecorder();

      _timer?.cancel();
      _hideRecordingOverlay();

      setState(() {
        _isRecording = false;
        _isHolding = false;
        _recordDuration = Duration.zero;
        _selectedVoice = null;
        _voiceSource = 'none';
      });

      // Delete the recorded file since it's cancelled
      if (_recordedFilePath != null &&
          await File(_recordedFilePath!).exists()) {
        await File(_recordedFilePath!).delete();
        print("🗑️ Deleted cancelled recording file");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.white),
              const SizedBox(width: 8),
              Text("Recording cancelled"),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error canceling recording: $e");
      _showError("Failed to cancel recording: $e");
      setState(() {
        _isRecording = false;
        _isHolding = false;
        _recordDuration = Duration.zero;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
