import 'package:flutter/material.dart';

/// A compact icon(+label) button, meant to sit side-by-side in a row
/// (unlike MainActionTile, which is sized for a grid).
class MainActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showLabel;

  const MainActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: showLabel ? 16 : 20,
                horizontal: 8,
              ),
              child: showLabel
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      icon,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
