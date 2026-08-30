import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../models/buddy_request.dart';
import '../widgets/app_drawer.dart';

import 'chat_screen.dart';
import 'my_tasks_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({
    super.key,
  });

  @override
  State<OffersScreen> createState() =>
      _OffersScreenState();
}

class _OffersScreenState
    extends State<OffersScreen> {
  HelpType? _selectedHelpType;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _loadOffers();
    });
  }

  // =========================================================
  // LOAD OFFERS
  // =========================================================

  Future<void> _loadOffers() async {
    final user =
        context
            .read<AuthController>()
            .currentUser;

    if (user == null) {
      return;
    }

    await context
        .read<RequestController>()
        .loadOffers(
          user.id,
          user.city,
        );
  }

  // =========================================================
  // ACCEPT REQUEST
  // =========================================================

  Future<void> _acceptRequest(
    BuddyRequest request,
  ) async {
    final user =
        context
            .read<AuthController>()
            .currentUser;

    if (user == null ||
        request.id == null) {
      return;
    }

    // =======================================================
    // CONFIRM DIALOG
    // =======================================================

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Accept Request',
          ),

          content: Text(
            'Do you want to accept this '
            '${request.helpType.label} request?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },

              child:
                  const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },

              child:
                  const Text(
                'Accept',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // Check whether the page still exists after await.
    if (!mounted) {
      return;
    }

    // =======================================================
    // ACCEPT + CREATE CHAT
    // =======================================================

    final success =
        await context
            .read<RequestController>()
            .acceptRequest(
              request: request,
              buddyId: user.id,
              buddyName:
                  user.fullName,
            );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Request accepted successfully.',
          ),
        ),
      );
    } else {
      final error =
          context
                  .read<
                      RequestController>()
                  .errorMessage ??
              'Failed to accept request.';

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(error),
        ),
      );
    }
  }

  // =========================================================
  // DRAWER
  // =========================================================

  void _openMyChats() {
    // Close the drawer.
    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const ChatScreen(),
      ),
    );
  }

  void _openMyTasks() {
    // Close the drawer.
    Navigator.of(context).pop();

    // Offers → My Tasks
    Navigator.of(context)
        .pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const MyTasksScreen(),
      ),
    );
  }

  void _switchMode() {
    // Close the drawer.
    Navigator.of(context).pop();

    // Return to the mode selection screen.
    Navigator.of(context).pop();
  }

  // =========================================================
  // UI
  // =========================================================

  List<BuddyRequest> _visibleOffers(
    List<BuddyRequest> offers,
  ) {
    final visible =
        offers.where((offer) {
      final selected =
          _selectedHelpType;

      return selected == null ||
          offer.helpType == selected;
    }).toList();

    visible.sort(
      (a, b) =>
          a.dateTime.compareTo(b.dateTime),
    );

    return visible;
  }

  String _selectedTypeLabel() {
    final selected =
        _selectedHelpType;

    if (selected == null) {
      return 'All request types';
    }

    return selected.label;
  }

  Widget _buildTypeFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      child: DropdownButtonFormField<HelpType?>(
        initialValue:
            _selectedHelpType,

        isExpanded:
            true,

        decoration:
            const InputDecoration(
          labelText:
              'Request type',
          prefixIcon:
              Icon(Icons.filter_list),
          border:
              OutlineInputBorder(),
        ),

        items: [
          const DropdownMenuItem<HelpType?>(
            value:
                null,
            child:
                Text('All request types'),
          ),
          ...HelpType.values.map(
            (type) {
              return DropdownMenuItem<HelpType?>(
                value:
                    type,
                child:
                    Text(type.label),
              );
            },
          ),
        ],

        onChanged: (value) {
          setState(() {
            _selectedHelpType = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller =
        context.watch<
            RequestController>();

    return Scaffold(
      // =====================================================
      // DRAWER
      // =====================================================

      drawer: AppDrawer(
        mode:
            AppDrawerMode.buddy,

        onOffers: () {
          Navigator.of(context)
              .pop();
        },

        onMyTasks:
            _openMyTasks,

        onMyChats:
            _openMyChats,

        onSwitchMode:
            _switchMode,
      ),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon:
                  const Icon(
                Icons.menu,
              ),

              onPressed: () {
                Scaffold.of(context)
                    .openDrawer();
              },
            );
          },
        ),

        title:
            const Text(
          'Offers',
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        child:
            _buildBody(
          controller,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD BODY
  // =========================================================

  Widget _buildBody(
    RequestController controller,
  ) {
    // First load
    if (controller.isLoading &&
        controller.offers.isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    // Failed to load
    if (controller.errorMessage !=
            null &&
        controller.offers.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                controller
                    .errorMessage!,

                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              OutlinedButton(
                onPressed:
                    _loadOffers,

                child:
                    const Text(
                  'Try again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No offers
    if (controller.offers.isEmpty) {
      return const Center(
        child: Padding(
          padding:
              EdgeInsets.all(
            32,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            children: [
              Icon(
                Icons
                    .volunteer_activism_outlined,

                size: 56,

                color:
                    Colors.grey,
              ),

              SizedBox(
                height: 16,
              ),

              Text(
                'No requests available.',

                style:
                    TextStyle(
                  fontSize: 18,

                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),

              SizedBox(
                height: 8,
              ),

              Text(
                'New requests from students '
                'will appear here.',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // OFFER LIST
    // =======================================================

    final offers =
        _visibleOffers(controller.offers);

    return Column(
      children: [
        _buildTypeFilter(),

        if (offers.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No ${_selectedTypeLabel().toLowerCase()} requests available.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  _loadOffers,

              child:
                  ListView.separated(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                itemCount:
                    offers.length,

                separatorBuilder:
                    (_, _) =>
                        const SizedBox(
                  height: 12,
                ),

                itemBuilder:
                    (context, index) {
                  final request =
                      offers[index];

                  return _OfferCard(
                    request:
                        request,

                    isLoading:
                        controller
                            .isLoading,

                    onAccept: () {
                      _acceptRequest(
                        request,
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ===========================================================
// OFFER CARD
// ===========================================================

class _OfferCard
    extends StatelessWidget {
  final BuddyRequest request;

  final bool isLoading;

  final VoidCallback onAccept;

  const _OfferCard({
    required this.request,
    required this.isLoading,
    required this.onAccept,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final date =
        request.dateTime;

    final dateText =
        '${date.day}/'
        '${date.month}/'
        '${date.year}';

    final timeText =
        TimeOfDay
            .fromDateTime(
              date,
            )
            .format(context);

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            // =================================================
            // HELP TYPE
            // =================================================

            Text(
              request
                  .helpType.label,

              style:
                  const TextStyle(
                fontSize: 17,

                fontWeight:
                    FontWeight
                        .bold,
              ),
            ),

            // =================================================
            // SPECIFIC BUDDY LABEL
            // =================================================
            //
            // targetBuddyId != null
            // This means this request was specifically sent to the current buddy.
            //
            // Because RequestService already handles filtering,
            // other buddies will never see it.

            if (request.targetBuddyId !=
                null) ...[
              const SizedBox(
                height: 10,
              ),

              const Chip(
                avatar: Icon(
                  Icons
                      .star_outline,
                  size: 18,
                ),

                label: Text(
                  'Requested specifically for you',
                ),
              ),
            ],

            // =================================================
            // OTHER HELP TYPE
            // =================================================

            if (request.helpType ==
                    HelpType.other &&
                request.customHelp !=
                    null &&
                request.customHelp!
                    .isNotEmpty) ...[
              const SizedBox(
                height: 6,
              ),

              Text(
                request
                    .customHelp!,
              ),
            ],

            const SizedBox(
              height: 12,
            ),

            // =================================================
            // REQUESTER
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons
                      .person_outline,

                  size: 18,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    request
                        .requesterName,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // =================================================
            // LOCATION
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons
                      .location_on_outlined,

                  size: 18,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    '${request.city}, '
                    '${request.country}',
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // =================================================
            // DATE + TIME
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons
                      .schedule_outlined,

                  size: 18,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  '$dateText · '
                  '$timeText',
                ),
              ],
            ),

            // =================================================
            // NOTE
            // =================================================

            if (request.note !=
                    null &&
                request.note!
                    .isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),

              Text(
                request.note!,

                style:
                    const TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ],

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // ACCEPT BUTTON
            // =================================================

            Align(
              alignment:
                  Alignment
                      .centerRight,

              child:
                  FilledButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : onAccept,

                icon:
                    const Icon(
                  Icons
                      .check_circle_outline,
                ),

                label:
                    const Text(
                  'Accept Request',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
