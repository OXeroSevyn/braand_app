import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../services/camera_service.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final bool isOwnProfile;

  const ProfileScreen({
    super.key,
    required this.user,
    this.isOwnProfile = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final CameraService _cameraService = CameraService();

  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isSaving = false;
  String? _avatarUrl;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _departmentController = TextEditingController(text: widget.user.department);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _avatarUrl = widget.user.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choose Image Source',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('Take Photo', style: GoogleFonts.spaceMono()),
              onTap: () {
                Navigator.pop(context);
                _takePictureWithCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.spaceMono(),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePictureWithCamera() async {
    try {
      await _cameraService.initializeCameras();
      final camera = _cameraService.getFrontCamera();

      if (camera == null) {
        _showError('No camera available');
        return;
      }

      _cameraController = CameraController(camera, ResolutionPreset.medium);

      await _cameraController!.initialize();

      if (!mounted) return;

      final photo = await _cameraService.takeSelfie(_cameraController!);

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _uploadProfilePicture(Uint8List.fromList(bytes));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Error: $e');
    } finally {
      _cameraController?.dispose();
      _cameraController = null;
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Request permission first (for Android 13+)
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        await _uploadProfilePicture(bytes);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Error picking image: $e');
      debugPrint('Gallery picker error: $e');
    }
  }

  Future<void> _uploadProfilePicture(Uint8List bytes) async {
    setState(() => _isSaving = true);

    try {
      final url = await _supabaseService.uploadProfilePicture(
        bytes,
        widget.user.id,
      );

      if (url != null) {
        // Save the avatar URL to the database
        await _supabaseService.updateUserProfile(
          userId: widget.user.id,
          avatarUrl: url,
        );

        // Refresh AuthProvider to update avatar everywhere
        if (mounted) {
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).refreshUserProfile();
        }

        if (mounted) {
          setState(() {
            _avatarUrl = url;
            _isSaving = false;
          });
          _showSuccess('Profile picture updated!');
        }
      } else {
        setState(() => _isSaving = false);
        _showError('Failed to upload picture');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Upload error: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      await _supabaseService.updateUserProfile(
        userId: widget.user.id,
        name: _nameController.text,
        department: _departmentController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        avatarUrl: _avatarUrl,
      );

      // Refresh user data in AuthProvider to propagate changes everywhere
      if (mounted) {
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).refreshUserProfile();
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        _showSuccess('Profile updated successfully!');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to update profile: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceMono()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceMono()),
        backgroundColor: AppColors.brand,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        actions: widget.isOwnProfile
            ? [
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            _buildProfilePicture(isDark),
            const SizedBox(height: 24),

            // Profile Details
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'DETAILS',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name
                  _buildField('NAME', _nameController, Icons.badge, isDark),
                  const SizedBox(height: 16),

                  // Email (read-only)
                  _buildReadOnlyField(
                    'EMAIL',
                    widget.user.email,
                    Icons.email,
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  // Department
                  _buildField(
                    'DEPARTMENT',
                    _departmentController,
                    Icons.business,
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _buildField('PHONE', _phoneController, Icons.phone, isDark),
                  const SizedBox(height: 16),

                  // Role (read-only)
                  _buildReadOnlyField(
                    'ROLE',
                    widget.user.role,
                    Icons.work,
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bio
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'BIO',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isEditing && widget.isOwnProfile
                      ? TextField(
                          controller: _bioController,
                          maxLines: 4,
                          style: GoogleFonts.spaceMono(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tell us about yourself...',
                            hintStyle: GoogleFonts.spaceMono(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.brand,
                                width: 2,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          widget.user.bio?.isEmpty ?? true
                              ? 'No bio added yet.'
                              : widget.user.bio!,
                          style: GoogleFonts.spaceMono(
                            fontSize: 14,
                            color: widget.user.bio?.isEmpty ?? true
                                ? Colors.grey
                                : null,
                          ),
                        ),
                ],
              ),
            ),

            // Save/Cancel Buttons
            if (_isEditing && widget.isOwnProfile) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      text: 'CANCEL',
                      color: Colors.grey,
                      textColor: Colors.white,
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                                _nameController.text = widget.user.name;
                                _departmentController.text =
                                    widget.user.department;
                                _bioController.text = widget.user.bio ?? '';
                                _phoneController.text = widget.user.phone ?? '';
                                _avatarUrl = widget.user.avatar;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NeoButton(
                      text: 'SAVE',
                      color: AppColors.brand,
                      textColor: Colors.black,
                      onPressed: _isSaving ? null : _saveProfile,
                      isLoading: _isSaving,
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

  Widget _buildProfilePicture(bool isDark) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white : Colors.black,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black : Colors.black,
                  offset: const Offset(6, 6),
                ),
              ],
            ),
            child: _avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarPlaceholder();
                      },
                    ),
                  )
                : _buildAvatarPlaceholder(),
          ),
          if (_isEditing && widget.isOwnProfile)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isSaving ? null : _showImageSourceDialog,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 3,
                    ),
                  ),
                  child: _isSaving
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 24,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        widget.user.name.substring(0, 1).toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 64,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _isEditing && widget.isOwnProfile
            ? TextField(
                controller: controller,
                style: GoogleFonts.spaceMono(fontSize: 14),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.brand, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              )
            : Text(
                controller.text.isEmpty ? 'Not set' : controller.text,
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: controller.text.isEmpty ? Colors.grey : null,
                ),
              ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
