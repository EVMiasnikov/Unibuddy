import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/user.dart';
import '../widgets/primary_button.dart';
import 'main_screen.dart';

const List<String> kAvailableLanguages = [
  'English', 'Italian', 'Russian', 'Spanish', 'French', 'German', 'Chinese', 'Other',
];

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _universityController = TextEditingController();
  final _cityController = TextEditingController(); // TODO: swap for a place picker later
  final _ageController = TextEditingController();

  AcademicPosition? _position;
  Sex? _sex;
  final Set<String> _selectedLanguages = {};

  // Raw bytes work on web, mobile, and desktop alike - unlike dart:io File,
  // which doesn't exist in a browser.
  Uint8List? _photoBytes;

  // The photo already saved on the account, shown until a new one is picked.
  String? _existingPhotoUrl;

  // True if the user already had a completed profile when this screen
  // opened - i.e. they're editing, not doing first-time setup.
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    _isEditing = user.hasCompletedProfile;

    _nameController.text = user.name ?? '';
    _surnameController.text = user.surname ?? '';
    _universityController.text = user.university ?? '';
    _cityController.text = user.city ?? '';
    _ageController.text = user.age?.toString() ?? '';
    _position = user.position;
    _sex = user.sex;
    _selectedLanguages.addAll(user.languages);
    _existingPhotoUrl = user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _universityController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final profileController = context.read<ProfileController>();
    final baseUser = authController.currentUser!;

    final updatedBaseUser = baseUser.copyWith(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      university: _universityController.text.trim(),
      city: _cityController.text.trim(),
      position: _position,
      age: int.tryParse(_ageController.text.trim()),
      languages: _selectedLanguages.toList(),
      sex: _sex,
    );

    final savedUser = await profileController.saveProfile(updatedBaseUser, photoBytes: _photoBytes);

    if (!mounted) return;
    if (savedUser != null) {
      authController.setCurrentUser(savedUser);
      if (_isEditing) {
        // Came here to edit an existing profile - just return to where we were.
        Navigator.of(context).pop();
      } else {
        // First-time setup - proceed into the app.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit profile' : 'Complete your profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!)
                        : (_existingPhotoUrl != null ? NetworkImage(_existingPhotoUrl!) : null) as ImageProvider?,
                    child: (_photoBytes == null && _existingPhotoUrl == null)
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Tap to add a photo (optional)')),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(labelText: 'Surname', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: 'University', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Placeholder text field for now - swap for a place/geo picker later.
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<AcademicPosition>(
                initialValue: _position,
                decoration: const InputDecoration(labelText: 'Position', border: OutlineInputBorder()),
                items: AcademicPosition.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                    .toList(),
                onChanged: (v) => setState(() => _position = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 16 || n > 100) return 'Enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<Sex>(
                initialValue: _sex,
                decoration: const InputDecoration(labelText: 'Sex', border: OutlineInputBorder()),
                items: Sex.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (v) => setState(() => _sex = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Languages you speak', style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAvailableLanguages.map((lang) {
                  final selected = _selectedLanguages.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedLanguages.add(lang);
                        } else {
                          _selectedLanguages.remove(lang);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              if (profileController.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(profileController.errorMessage!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 32),
              PrimaryButton(
                label: _isEditing ? 'Save changes' : 'Save and continue',
                isLoading: profileController.isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}