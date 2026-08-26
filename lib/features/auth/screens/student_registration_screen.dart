import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedBoard;
  String? _selectedStandard;
  File? _profilePhoto;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) setState(() => _profilePhoto = File(picked.path));
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 4)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.maroon,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      _showError('Please select gender');
      return;
    }
    if (_selectedDob == null) {
      _showError('Please select date of birth');
      return;
    }
    if (_selectedBoard == null) {
      _showError('Please select board');
      return;
    }
    if (_selectedStandard == null) {
      _showError('Please select standard');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final registrationPhone = extra?['phone'] as String?;
      if (registrationPhone == null) {
        throw Exception('Phone number is missing.');
      }

      final profilePhotoUrl = _profilePhoto == null
          ? null
          : await _uploadProfilePhoto(_profilePhoto!, registrationPhone);

      await Supabase.instance.client.from('student_profiles').insert({
        'id': Supabase.instance.client.auth.currentUser?.id,
        'full_name': _nameController.text.trim(),
        'gender': _selectedGender,
        'dob': _selectedDob?.toIso8601String(),
        'parent_name': _parentNameController.text.trim(),
        'parent_phone': '+91${_parentPhoneController.text.trim()}',
        'whatsapp_number': '+91${_whatsappController.text.trim()}',
        'email': _emailController.text.trim(),
        'school_name': _schoolController.text.trim(),
        'board': _selectedBoard,
        'standard': _selectedStandard,
        'profile_photo_url': profilePhotoUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      context.go(Routes.pendingApproval);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadProfilePhoto(File file, String phone) async {
    final fileName =
        'student_${phone}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage
        .from(AppConstants.bucketProfilePhotos)
        .upload(fileName, file);

    return Supabase.instance.client.storage
        .from(AppConstants.bucketProfilePhotos)
        .getPublicUrl(fileName);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo picker
              Center(
                child: Semantics(
                  button: true,
                  label: 'Profile Photo',
                  hint: 'Double tap to select a profile photo',
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.lightSurfaceVariant,
                      backgroundImage: _profilePhoto != null
                          ? FileImage(_profilePhoto!)
                          : null,
                      child: _profilePhoto == null
                          ? const Icon(
                              Icons.add_a_photo_rounded,
                              size: 32,
                              color: AppColors.maroon,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _pickPhoto,
                  child: Text(
                    'Add Photo (Optional)',
                    style: AppTypography.poppins(
                      fontSize: 13,
                      color: AppColors.maroon,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Personal Information'),
              const SizedBox(height: 12),

              _buildTextField(
                _nameController,
                'Full Name',
                Icons.person_rounded,
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 16),

              // DOB
              Semantics(
                button: true,
                label: 'Date of Birth Picker',
                hint: 'Double tap to select date of birth',
                child: GestureDetector(
                  onTap: _pickDob,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.cake_rounded),
                        hintText: _selectedDob == null
                            ? 'Select date'
                            : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                      ),
                      controller: TextEditingController(
                        text: _selectedDob == null
                            ? ''
                            : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Parent / Guardian'),
              const SizedBox(height: 12),

              _buildTextField(
                _parentNameController,
                'Parent Name',
                Icons.family_restroom_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _parentPhoneController,
                'Parent Mobile',
                Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _whatsappController,
                'WhatsApp Number',
                Icons.message_rounded,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Contact & School'),
              const SizedBox(height: 12),

              _buildTextField(
                _emailController,
                'Email Address',
                Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                required: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _schoolController,
                'School Name',
                Icons.school_rounded,
              ),
              const SizedBox(height: 16),

              // Board
              DropdownButtonFormField<String>(
                initialValue: _selectedBoard,
                decoration: const InputDecoration(
                  labelText: 'Board',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: AppConstants.boards
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBoard = val),
              ),
              const SizedBox(height: 16),

              // Standard
              DropdownButtonFormField<String>(
                initialValue: _selectedStandard,
                decoration: const InputDecoration(
                  labelText: 'Standard / Class',
                  prefixIcon: Icon(Icons.class_rounded),
                ),
                items: AppConstants.standards
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStandard = val),
              ),
              const SizedBox(height: 40),

              PrimaryButton(
                label: 'Submit Registration',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Your registration will be reviewed by the admin.',
                  style: AppTypography.poppins(
                    fontSize: 12,
                    color: AppColors.lightOutline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: maxLength != null ? null : '',
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            }
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.maroon,
        letterSpacing: 0.5,
      ),
    );
  }
}
