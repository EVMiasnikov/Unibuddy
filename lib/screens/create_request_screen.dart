import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../models/buddy_request.dart';
import '../services/buddy_search_service.dart';
import '../widgets/global_location_picker.dart';
import '../widgets/main_bottom_bar.dart';

import 'buddy_search_screen.dart';
import 'profile_view_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({
    super.key,
  });

  @override
  State<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState
    extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customHelpController =
      TextEditingController();

  final _noteController =
      TextEditingController();

  HelpType? _selectedHelpType;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // =========================================================
  // GLOBAL LOCATION
  // =========================================================

  LocationSelection? _selectedLocation;

  // =========================================================
  // SPECIFIC BUDDY
  // =========================================================

  BuddySearchResult? _selectedBuddy;

  @override
  void dispose() {
    _customHelpController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  // =========================================================
  // SELECT DATE
  // =========================================================

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 2,
      ),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  // =========================================================
  // SELECT TIME
  // =========================================================

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime:
          _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  // =========================================================
  // SEARCH SPECIFIC BUDDY
  // =========================================================

  Future<void> _selectSpecificBuddy() async {
    final location = _selectedLocation;

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a country and city before searching for a buddy.',
          ),
        ),
      );

      return;
    }

    final user =
        context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    final buddy =
        await Navigator.of(context)
            .push<BuddySearchResult>(
      MaterialPageRoute(
        builder: (_) => BuddySearchScreen(
          city: location.city,
          currentUserId: user.id,
        ),
      ),
    );

    if (!mounted || buddy == null) {
      return;
    }

    setState(() {
      _selectedBuddy = buddy;
    });
  }

  // =========================================================
  // CREATE REQUEST
  // =========================================================

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedHelpType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a help type.',
          ),
        ),
      );

      return;
    }

    // Country + City 必须通过统一 Picker 选择
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a country and city.',
          ),
        ),
      );

      return;
    }

    if (_selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select date and time.',
          ),
        ),
      );

      return;
    }

    final user =
        context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    final requestDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final customHelp =
        _customHelpController.text.trim();

    final note =
        _noteController.text.trim();

    final location = _selectedLocation!;

    final request = BuddyRequest(
      requesterId: user.id,

      requesterName: user.fullName,

      helpType: _selectedHelpType!,

      customHelp:
          _selectedHelpType == HelpType.other
              ? customHelp
              : null,

      note: note.isEmpty ? null : note,

      // =====================================================
      // GLOBAL LOCATION
      // =====================================================

      country: location.country,

      city: location.city,

      dateTime: requestDateTime,

      // Unselected = null
      // Selected = specific buddy UID
      targetBuddyId: _selectedBuddy?.id,

      acceptedBuddyId: null,

      status: RequestStatus.pending,

      createdAt: DateTime.now(),
    );

    final success =
        await context
            .read<RequestController>()
            .createRequest(
              request,
            );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request created successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } else {
      final error =
          context
                  .read<RequestController>()
                  .errorMessage ??
              'Failed to create request.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestController =
        context.watch<RequestController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Request',
        ),
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            // =================================================
            // HELP TYPE
            // =================================================

            DropdownButtonFormField<HelpType>(
              initialValue: _selectedHelpType,

              decoration: const InputDecoration(
                labelText: 'Help type *',
                border: OutlineInputBorder(),
              ),

              items:
                  HelpType.values.map(
                (type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.label,
                    ),
                  );
                },
              ).toList(),

              onChanged: (value) {
                setState(() {
                  _selectedHelpType = value;
                });
              },

              validator: (value) {
                if (value == null) {
                  return 'Please select a help type.';
                }

                return null;
              },
            ),

            // =================================================
            // OTHER
            // =================================================

            if (_selectedHelpType ==
                HelpType.other) ...[
              const SizedBox(height: 16),

              TextFormField(
                controller:
                    _customHelpController,

                decoration: const InputDecoration(
                  labelText:
                      'What help do you need? *',
                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  if (_selectedHelpType ==
                          HelpType.other &&
                      (value == null ||
                          value.trim().isEmpty)) {
                    return 'Please describe the help you need.';
                  }

                  return null;
                },
              ),
            ],

            const SizedBox(height: 20),

            // =================================================
            // GLOBAL COUNTRY + CITY PICKER
            // =================================================

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Select the location where you need help.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            GlobalLocationPicker(
              onChanged: (location) {
                final oldLocation =
                    _selectedLocation;

                final locationChanged =
                    oldLocation?.countryCode !=
                            location?.countryCode ||
                        oldLocation?.city !=
                            location?.city;

                setState(() {
                  _selectedLocation =
                      location;

                  if (locationChanged) {
                    _selectedBuddy = null;
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // =================================================
            // SPECIFIC BUDDY
            // =================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Specific Buddy',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  'Optional',
                  style: TextStyle(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            const Text(
              'Leave this empty to make the request visible to all available buddies in the selected city.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            if (_selectedBuddy == null)
              OutlinedButton.icon(
                onPressed:
                    _selectSpecificBuddy,

                icon: const Icon(
                  Icons.person_search,
                ),

                label: const Text(
                  'Search Buddy',
                ),
              )
            else
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(14),

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,

                        backgroundImage:
                            _selectedBuddy!
                                            .photoUrl !=
                                        null &&
                                    _selectedBuddy!
                                        .photoUrl!
                                        .isNotEmpty
                                ? NetworkImage(
                                    _selectedBuddy!
                                        .photoUrl!,
                                  )
                                : null,

                        child:
                            _selectedBuddy!
                                            .photoUrl ==
                                        null ||
                                    _selectedBuddy!
                                        .photoUrl!
                                        .isEmpty
                                ? const Icon(
                                    Icons.person,
                                  )
                                : null,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              _selectedBuddy!
                                  .fullName,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            if (_selectedBuddy!
                                    .university !=
                                null)
                              Text(
                                _selectedBuddy!
                                    .university!,
                              ),

                            if (_selectedBuddy!
                                    .city !=
                                null)
                              Text(
                                _selectedBuddy!.city!,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip:
                            'View profile',

                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProfileViewScreen(
                                userId:
                                    _selectedBuddy!
                                        .id,
                              ),
                            ),
                          );
                        },

                        icon: const Icon(
                          Icons
                              .account_circle_outlined,
                        ),
                      ),

                      IconButton(
                        tooltip: 'Remove',

                        onPressed: () {
                          setState(() {
                            _selectedBuddy =
                                null;
                          });
                        },

                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // =================================================
            // DATE
            // =================================================

            OutlinedButton.icon(
              onPressed: _selectDate,

              icon: const Icon(
                Icons.calendar_today_outlined,
              ),

              label: Text(
                _selectedDate == null
                    ? 'Select date *'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // TIME
            // =================================================

            OutlinedButton.icon(
              onPressed: _selectTime,

              icon: const Icon(
                Icons.schedule_outlined,
              ),

              label: Text(
                _selectedTime == null
                    ? 'Select time *'
                    : _selectedTime!
                        .format(context),
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // NOTE
            // =================================================

            TextFormField(
              controller: _noteController,

              maxLines: 4,

              decoration: const InputDecoration(
                labelText: 'Additional note',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // =================================================
            // CREATE
            // =================================================

            FilledButton(
              onPressed:
                  requestController.isLoading
                      ? null
                      : _createRequest,

              child:
                  requestController.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Request',
                        ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          const MainBottomBar(),
    );
  }
}