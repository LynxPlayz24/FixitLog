import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  UserProfile? _profile;
  DateTime? _selectedBirthdate;
  Uint8List? _imageBytes;
  bool _loading = true;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final email = AuthService.instance.currentUserEmail;
    if (email == null) return;

    final profile = await ProfileService.instance.loadProfile(email);
    if (!mounted) return;

    setState(() {
      _profile = profile;
      _nameController.text = profile.fullName;
      _addressController.text = profile.address;
      _phoneController.text = profile.phoneNumber;
      _selectedBirthdate = profile.birthdate;
      if (profile.profileImageBase64 != null &&
          profile.profileImageBase64!.isNotEmpty) {
        _imageBytes = base64Decode(profile.profileImageBase64!);
      }
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _profile!
      ..fullName = _nameController.text.trim()
      ..birthdate = _selectedBirthdate
      ..address = _addressController.text.trim()
      ..phoneNumber = _phoneController.text.trim();

    // Image is saved separately via _pickImage, but also ensure it's set
    if (_imageBytes != null) {
      _profile!.profileImageBase64 = base64Encode(_imageBytes!);
    }

    await ProfileService.instance.saveProfile(_profile!);

    if (!mounted) return;
    setState(() => _editing = false);
    NotificationService.instance.showSuccess(context, 'Profile saved!');
  }

  void _cancelEditing() {
    _nameController.text = _profile!.fullName;
    _addressController.text = _profile!.address;
    _phoneController.text = _profile!.phoneNumber;
    _selectedBirthdate = _profile!.birthdate;
    // Revert image
    if (_profile!.profileImageBase64 != null &&
        _profile!.profileImageBase64!.isNotEmpty) {
      _imageBytes = base64Decode(_profile!.profileImageBase64!);
    } else {
      _imageBytes = null;
    }
    setState(() => _editing = false);
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _imageBytes = bytes;
    });

    // Save immediately so the sidebar updates too
    _profile!.profileImageBase64 = base64Encode(bytes);
    await ProfileService.instance.saveProfile(_profile!);
  }

  Future<ImageSource?> _showImageSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              if (_imageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeImage() async {
    setState(() => _imageBytes = null);
    _profile!.profileImageBase64 = null;
    await ProfileService.instance.saveProfile(_profile!);
    if (mounted) {
      NotificationService.instance.showInfo(context, 'Photo removed.');
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedBirthdate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final username = AuthService.instance.currentUsername ?? 'User';
    final email = AuthService.instance.currentUserEmail ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar with photo ───────────────────────────────────
              GestureDetector(
                onTap: _editing ? _pickImage : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          AppTheme.primaryPurple.withValues(alpha: 0.1),
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : null,
                      child: _imageBytes == null
                          ? Text(
                              _initials(username),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryPurple,
                              ),
                            )
                          : null,
                    ),
                    if (_editing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                username,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // ── Info fields ────────────────────────────────────────
              _buildField(
                icon: Icons.person_outline,
                label: 'Full Name',
                controller: _nameController,
                enabled: _editing,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),

              _buildBirthdateTile(),
              const SizedBox(height: 14),

              _buildReadOnlyTile(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: _selectedBirthdate != null
                    ? '${_calcAge(_selectedBirthdate!)} years old'
                    : 'Set birthdate first',
              ),
              const SizedBox(height: 14),

              _buildField(
                icon: Icons.home_outlined,
                label: 'Address',
                controller: _addressController,
                enabled: _editing,
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              _buildField(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                controller: _phoneController,
                enabled: _editing,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 32),

              // ── Action buttons ─────────────────────────────────────
              if (_editing) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    child: const Text('Cancel'),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ──────────────────────────────────────────────────

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor:
            enabled ? colorScheme.surface : colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildBirthdateTile() {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _editing ? _pickBirthdate : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birthdate',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          filled: true,
          fillColor: _editing
              ? colorScheme.surface
              : colorScheme.surfaceContainerHighest,
          suffixIcon: _editing
              ? Icon(Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant)
              : null,
        ),
        child: Text(
          _selectedBirthdate != null
              ? _formatDate(_selectedBirthdate!)
              : 'Not set',
          style: TextStyle(
            fontSize: 16,
            color: _selectedBirthdate != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        value,
        style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
      ),
    );
  }

  // ── Utilities ────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  int _calcAge(DateTime birthdate) {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      years--;
    }
    return years;
  }
}
