import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// A location picked on the map: coordinates plus a human-readable label
/// resolved via reverse geocoding (or a raw coordinate string as fallback).
class PickedLocation {
  final double lat;
  final double lng;
  final String label;

  const PickedLocation({
    required this.lat,
    required this.lng,
    required this.label,
  });
}

/// Two modes in one screen:
/// - Pick mode (default): drag the map under a fixed pin, confirm to
///   reverse-geocode that point and return it as a PickedLocation.
/// - Read-only mode (`readOnly: true`): just shows a marker at a known
///   point (`viewLat`/`viewLng`), or geocodes `initialQuery` first when
///   coordinates aren't known (e.g. viewing a request that only has a
///   city, no precise pin). No confirm action, nothing is returned.
class LocationPickerScreen extends StatefulWidget {
  /// Pick mode: free-text place to center the map on initially.
  /// Read-only mode (when viewLat/viewLng are null): free-text place to
  /// geocode and show a marker at.
  final String? initialQuery;

  final bool readOnly;
  final double? viewLat;
  final double? viewLng;

  /// Read-only mode only: app bar title. Defaults to a generic title.
  final String? title;

  const LocationPickerScreen({
    super.key,
    this.initialQuery,
    this.readOnly = false,
    this.viewLat,
    this.viewLng,
    this.title,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(41.9028, 12.4964); // Rome, as a fallback
  static const _userAgent = 'Unibuddy Flutter App (student project)';

  final MapController _mapController = MapController();

  LatLng _center = _defaultCenter;
  bool _isLoadingCenter = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();

    if (widget.readOnly && widget.viewLat != null && widget.viewLng != null) {
      _center = LatLng(widget.viewLat!, widget.viewLng!);
      _isLoadingCenter = false;
    } else {
      _resolveCenterFromQuery();
    }
  }

  Future<void> _resolveCenterFromQuery() async {
    final query = widget.initialQuery?.trim();
    if (query == null || query.isEmpty) {
      setState(() => _isLoadingCenter = false);
      return;
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '1',
      });

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List<dynamic>;
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat'] as String? ?? '');
          final lon = double.tryParse(first['lon'] as String? ?? '');
          if (lat != null && lon != null) {
            _center = LatLng(lat, lon);
          }
        }
      }
    } catch (_) {
      // Fall back to the default center - not finding the city's rough
      // position isn't worth blocking the map over.
    }

    if (!mounted) return;
    setState(() => _isLoadingCenter = false);
  }

  Future<void> _confirmLocation() async {
    setState(() => _isConfirming = true);

    final center = _mapController.camera.center;
    String label =
        '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}';

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': center.latitude.toString(),
        'lon': center.longitude.toString(),
        'format': 'json',
      });

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = result['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          label = displayName;
        }
      }
    } catch (_) {
      // Keep the coordinate-based label - the pin position is still saved
      // even if we can't resolve a readable address right now.
    }

    if (!mounted) return;

    Navigator.of(context).pop(
      PickedLocation(lat: center.latitude, lng: center.longitude, label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (widget.readOnly ? 'Location' : 'Choose a specific location'),
        ),
      ),
      body: _isLoadingCenter
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.unibuddy',
                    ),
                    if (widget.readOnly)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _center,
                            width: 48,
                            height: 48,
                            child: const Icon(Icons.location_pin, size: 48, color: Colors.red),
                          ),
                        ],
                      ),
                  ],
                ),
                // Pick mode only: fixed pin overlay - the map moves
                // underneath it, so whatever sits under the pin's tip is
                // the picked point.
                if (!widget.readOnly)
                  const IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.location_pin, size: 48, color: Colors.red),
                    ),
                  ),
              ],
            ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: _isLoadingCenter || _isConfirming ? null : _confirmLocation,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: const Text('Confirm location'),
            ),
    );
  }
}