import 'package:flutter/material.dart';
import '../../data/profile_api.dart';
import '../../domain/models/profile.dart';

class EditProfilePage extends StatefulWidget {
  final Profile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileApi _profileApi = ProfileApi();

  late TextEditingController _fullNameController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _bikeModelController;
  late TextEditingController _bikeNumberController;
  late TextEditingController _bioController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profileData = widget.profile.profileData;
    _fullNameController = TextEditingController(text: profileData.fullName);
    _avatarUrlController = TextEditingController(
      text: profileData.avatarUrl ?? '',
    );
    _bikeModelController = TextEditingController(
      text: profileData.bikeModel ?? '',
    );
    _bikeNumberController = TextEditingController(
      text: profileData.bikeNumber ?? '',
    );
    _bioController = TextEditingController(text: profileData.bio ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _avatarUrlController.dispose();
    _bikeModelController.dispose();
    _bikeNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _profileApi.updateProfile(
        fullName: _fullNameController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim(),
        bikeModel: _bikeModelController.text.trim(),
        bikeNumber: _bikeNumberController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveProfile, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Avatar URL
              TextFormField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  helperText: 'Enter a valid image URL',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.hasScheme) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bike Model
              TextFormField(
                controller: _bikeModelController,
                decoration: const InputDecoration(
                  labelText: 'Bike Model',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.two_wheeler),
                  helperText: 'e.g., Royal Enfield Classic 350',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your bike model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bike Number
              TextFormField(
                controller: _bikeNumberController,
                decoration: const InputDecoration(
                  labelText: 'Bike Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                  helperText: 'e.g., KA01AB1234',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your bike number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  helperText: 'Tell us about yourself',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a bio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your profile information will be visible to other riders in your crew.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
