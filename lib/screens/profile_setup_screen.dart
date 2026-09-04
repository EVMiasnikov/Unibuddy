import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/user.dart';
import '../widgets/global_location_picker.dart';
import '../widgets/primary_button.dart';
import 'main_screen.dart';

const List<String> kAvailableLanguages = [
  'English',
  'Italian',
  'Russian',
  'Spanish',
  'French',
  'German',
  'Chinese',
  'Other',
];

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
  });

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _surnameController =
      TextEditingController();

  final _universityController =
      TextEditingController();

  final _ageController =
      TextEditingController();

  // =========================================================
  // GLOBAL LOCATION
  // =========================================================

  String? _selectedCountry;
  String? _selectedCity;

  AcademicPosition? _position;
  Sex? _sex;

  final Set<String> _selectedLanguages = {};

  Uint8List? _photoBytes;

  String? _existingPhotoUrl;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    final user =
        context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    _isEditing = user.hasCompletedProfile;

    _nameController.text =
        user.name ?? '';

    _surnameController.text =
        user.surname ?? '';

    _universityController.text =
        user.university ?? '';

    // Existing location will be passed into the
    // same GlobalLocationPicker used by Create Request.
    _selectedCountry = user.country;
    _selectedCity = user.city;

    _ageController.text =
        user.age?.toString() ?? '';

    _position = user.position;
    _sex = user.sex;

    _selectedLanguages.addAll(
      user.languages,
    );

    _existingPhotoUrl =
        user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _universityController.dispose();
    _ageController.dispose();

    super.dispose();
  }

  // =========================================================
  // PHOTO
  // =========================================================

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) {
      return;
    }

    final bytes =
        await picked.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _photoBytes = bytes;
    });
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // LocationPicker is shared by Profile and Request,
    // but it is not itself a TextFormField, so validate here.
    if (_selectedCountry == null ||
        _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a country and city.',
          ),
        ),
      );

      return;
    }

    final authController =
        context.read<AuthController>();

    final profileController =
        context.read<ProfileController>();

    final baseUser =
        authController.currentUser;

    if (baseUser == null) {
      return;
    }

    final updatedBaseUser =
        baseUser.copyWith(
      name:
          _nameController.text.trim(),

      surname:
          _surnameController.text.trim(),

      university:
          _universityController.text.trim(),

      country:
          _selectedCountry,

      city:
          _selectedCity,

      position:
          _position,

      age:
          int.tryParse(
        _ageController.text.trim(),
      ),

      languages:
          _selectedLanguages.toList(),

      sex:
          _sex,
    );

    final savedUser =
        await profileController.saveProfile(
      updatedBaseUser,
      photoBytes: _photoBytes,
    );

    if (!mounted) {
      return;
    }

    if (savedUser == null) {
      return;
    }

    authController.setCurrentUser(
      savedUser,
    );

    if (_isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context)
          .pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const MainScreen(),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final profileController =
        context.watch<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit profile'
              : 'Complete your profile',
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding:
                const EdgeInsets.all(24),

            children: [
              // ===============================================
              // PHOTO
              // ===============================================

              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,

                  child: CircleAvatar(
                    radius: 48,

                    backgroundImage:
                        _photoBytes != null
                            ? MemoryImage(
                                _photoBytes!,
                              )
                            : (_existingPhotoUrl !=
                                        null &&
                                    _existingPhotoUrl!
                                        .isNotEmpty
                                ? NetworkImage(
                                    _existingPhotoUrl!,
                                  )
                                : null)
                                as ImageProvider?,

                    child:
                        _photoBytes == null &&
                                (_existingPhotoUrl ==
                                        null ||
                                    _existingPhotoUrl!
                                        .isEmpty)
                            ? const Icon(
                                Icons.add_a_photo,
                                size: 32,
                              )
                            : null,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Tap to add a photo (optional)',
                ),
              ),

              const SizedBox(height: 24),

              // ===============================================
              // NAME
              // ===============================================

              TextFormField(
                controller:
                    _nameController,

                decoration:
                    const InputDecoration(
                  labelText: 'Name',
                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ===============================================
              // SURNAME
              // ===============================================

              TextFormField(
                controller:
                    _surnameController,

                decoration:
                    const InputDecoration(
                  labelText: 'Surname',
                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ===============================================
              // UNIVERSITY
              // ===============================================

              TextFormField(
                controller:
                    _universityController,

                decoration:
                    const InputDecoration(
                  labelText: 'University',
                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ===============================================
              // GLOBAL LOCATION
              // SAME COMPONENT AS CREATE REQUEST
              // ===============================================

              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Choose your location from the standardized global list so buddy matching stays consistent.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 12),

              GlobalLocationPicker(
                initialCountry:
                    _selectedCountry,

                initialCity:
                    _selectedCity,

                onChanged: (location) {
                  setState(() {
                    if (location == null) {
                      _selectedCountry =
                          null;

                      _selectedCity =
                          null;
                    } else {
                      _selectedCountry =
                          location.country;

                      _selectedCity =
                          location.city;
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // ===============================================
              // POSITION
              // ===============================================

              DropdownButtonFormField<
                  AcademicPosition>(
                initialValue:
                    _position,

                decoration:
                    const InputDecoration(
                  labelText: 'Position',
                  border:
                      OutlineInputBorder(),
                ),

                items:
                    AcademicPosition.values
                        .map(
                  (position) {
                    return DropdownMenuItem(
                      value: position,
                      child: Text(
                        position.label,
                      ),
                    );
                  },
                ).toList(),

                onChanged: (value) {
                  setState(() {
                    _position = value;
                  });
                },

                validator: (value) {
                  if (value == null) {
                    return 'Required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ===============================================
              // AGE
              // ===============================================

              TextFormField(
                controller:
                    _ageController,

                decoration:
                    const InputDecoration(
                  labelText: 'Age',
                  border:
                      OutlineInputBorder(),
                ),

                keyboardType:
                    TextInputType.number,

                validator: (value) {
                  final age =
                      int.tryParse(
                    value?.trim() ?? '',
                  );

                  if (age == null ||
                      age < 16 ||
                      age > 100) {
                    return 'Enter a valid age';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ===============================================
              // SEX
              // ===============================================

              DropdownButtonFormField<Sex>(
                initialValue:
                    _sex,

                decoration:
                    const InputDecoration(
                  labelText: 'Sex',
                  border:
                      OutlineInputBorder(),
                ),

                items:
                    Sex.values.map(
                  (sex) {
                    return DropdownMenuItem(
                      value: sex,
                      child:
                          Text(sex.label),
                    );
                  },
                ).toList(),

                onChanged: (value) {
                  setState(() {
                    _sex = value;
                  });
                },

                validator: (value) {
                  if (value == null) {
                    return 'Required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ===============================================
              // LANGUAGES
              // ===============================================

              Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'Languages you speak',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleSmall,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,

                children:
                    kAvailableLanguages
                        .map(
                  (language) {
                    final selected =
                        _selectedLanguages
                            .contains(
                      language,
                    );

                    return FilterChip(
                      label:
                          Text(language),

                      selected:
                          selected,

                      onSelected:
                          (value) {
                        setState(() {
                          if (value) {
                            _selectedLanguages
                                .add(
                              language,
                            );
                          } else {
                            _selectedLanguages
                                .remove(
                              language,
                            );
                          }
                        });
                      },
                    );
                  },
                ).toList(),
              ),

              // ===============================================
              // ERROR
              // ===============================================

              if (profileController
                      .errorMessage !=
                  null) ...[
                const SizedBox(
                  height: 16,
                ),

                Text(
                  profileController
                      .errorMessage!,

                  style:
                      const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ===============================================
              // SAVE
              // ===============================================

              PrimaryButton(
                label:
                    _isEditing
                        ? 'Save changes'
                        : 'Save and continue',

                isLoading:
                    profileController
                        .isSaving,

                onPressed:
                    _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}