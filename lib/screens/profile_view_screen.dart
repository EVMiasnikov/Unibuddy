import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;

  const ProfileViewScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileViewScreen> createState() =>
      _ProfileViewScreenState();
}

class _ProfileViewScreenState
    extends State<ProfileViewScreen> {
  final UserService _userService = UserService();

  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userService.getProfile(
        widget.userId,
        '',
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),

              const SizedBox(height: 12),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _loadProfile();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text(
          'Profile not found.',
        ),
      );
    }

    final user = _user!;

    return ListView(
      padding: const EdgeInsets.all(24),

      children: [
        // =============================
        // Avatar
        // =============================

        Center(
          child: CircleAvatar(
            radius: 52,

            backgroundImage:
                user.photoUrl != null
                    ? NetworkImage(
                        user.photoUrl!,
                      )
                    : null,

            child:
                user.photoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 52,
                      )
                    : null,
          ),
        ),

        const SizedBox(height: 16),

        // =============================
        // Name
        // =============================

        Center(
          child: Text(
            user.fullName.isNotEmpty
                ? user.fullName
                : 'User',

            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // =============================
        // University
        // =============================

        if (user.university != null &&
            user.university!.isNotEmpty)
          _ProfileRow(
            icon:
                Icons.school_outlined,
            title: 'University',
            value:
                user.university!,
          ),
        
        // =============================
        // Country
        // =============================

        if (user.country != null &&
            user.country!.isNotEmpty)
          _ProfileRow(
            icon:
                Icons.public_outlined,
            title: 'Country',
            value:
                user.country!,
          ),

        // =============================
        // City
        // =============================

        if (user.city != null &&
            user.city!.isNotEmpty)
          _ProfileRow(
            icon:
                Icons.location_on_outlined,
            title: 'City',
            value:
                user.city!,
          ),

        // =============================
        // Academic Position
        // =============================

        if (user.position != null)
          _ProfileRow(
            icon:
                Icons.badge_outlined,
            title: 'Academic position',
            value:
                user.position!.label,
          ),

        // =============================
        // Age
        // =============================

        if (user.age != null)
          _ProfileRow(
            icon:
                Icons.cake_outlined,
            title: 'Age',
            value:
                user.age.toString(),
          ),

        // =============================
        // Sex
        // =============================

        if (user.sex != null)
          _ProfileRow(
            icon:
                Icons.person_outline,
            title: 'Sex',
            value:
                user.sex!.label,
          ),

        // =============================
        // Languages
        // =============================

        if (user.languages.isNotEmpty) ...[
          const SizedBox(height: 20),

          const Text(
            'Languages',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children:
                user.languages.map(
              (language) {
                return Chip(
                  label:
                      Text(language),
                );
              },
            ).toList(),
          ),
        ],
      ],
    );
  }
}

class _ProfileRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 22,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}