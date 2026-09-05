import 'package:flutter/material.dart';

import '../screens/location_picker_screen.dart';

/// The location row shown on request/task/offer cards: the precise pin
/// label when one was set, otherwise the general city/country - either
/// way, tapping it opens a read-only map centered on that location.
class LocationLink extends StatelessWidget {
  final String city;
  final String country;
  final String? specificLocationLabel;
  final double? specificLat;
  final double? specificLng;

  const LocationLink({
    super.key,
    required this.city,
    required this.country,
    this.specificLocationLabel,
    this.specificLat,
    this.specificLng,
  });

  void _open(BuildContext context) {
    final hasSpecific = specificLat != null && specificLng != null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          readOnly: true,
          viewLat: hasSpecific ? specificLat : null,
          viewLng: hasSpecific ? specificLng : null,
          initialQuery: hasSpecific ? null : '$city, $country',
          title: specificLocationLabel ?? '$city, $country',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = specificLocationLabel ?? '$city, $country';

    return InkWell(
      onTap: () => _open(context),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}