import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

/// A Couchsurfing-style status toggle: "I'm accepting buddy requests" or not.
/// One tap flips it; a small edit action lets you update buddy-relevant
/// settings (currently just city) without leaving the main screen.
class BuddyStatusCard extends StatefulWidget {
  const BuddyStatusCard({super.key});

  @override
  State<BuddyStatusCard> createState() => _BuddyStatusCardState();
}

class _BuddyStatusCardState extends State<BuddyStatusCard> {
  bool _isUpdating = false;

  Future<void> _handleToggle(bool newValue) async {
    setState(() => _isUpdating = true);
    final success = await context.read<AuthController>().toggleBuddyStatus(newValue);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your status. Please try again.')),
      );
    }
  }

  Future<void> _editCity() async {
    final authController = context.read<AuthController>();
    final controller = TextEditingController(text: authController.currentUser?.city ?? '');

    final newCity = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buddy city'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newCity == null || newCity.isEmpty || !mounted) return;

    setState(() => _isUpdating = true);
    final success = await authController.updateBuddyCity(newCity);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your city. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final isAccepting = user?.isAcceptingBuddyRequests ?? false;

    return Card(
      color: isAccepting ? Colors.green.withValues(alpha: 0.08) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  color: isAccepting ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Be a Buddy',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (_isUpdating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: isAccepting,
                    onChanged: _handleToggle,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isAccepting
                  ? "You're visible to students looking for a buddy."
                  : "You're not currently accepting buddy requests.",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            if (isAccepting) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user?.city?.isNotEmpty == true ? user!.city! : 'No city set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _isUpdating ? null : _editCity,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
