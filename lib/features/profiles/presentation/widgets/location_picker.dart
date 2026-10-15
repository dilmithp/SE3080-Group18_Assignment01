import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';

/// Fallback map center when [LocationPicker.initial] is null/unset *and*
/// device geolocation isn't available or was declined. `(0, 0)` — the
/// placeholder every brand-new profile is seeded with — is the Gulf of
/// Guinea and meaningless for this app, so it must never be shown silently.
/// Colombo, Sri Lanka is used instead: this project's home market and dev
/// context, so a fresh profile with no other signal lands somewhere
/// plausible for this app's actual users rather than in open ocean.
const _defaultCenter = LatLng(6.9271, 79.8612);
const double _defaultZoom = 12;
const double _pickedZoom = 15;

/// Reusable map and geolocation widget for picking a profile's home coordinate.
///
/// On web, renders a fixed-height interactive [GoogleMap].
/// On mobile (Android APK / iOS), provides a GPS-driven location detection card
/// with a prominent "Use my current location" button powered by [Geolocator].
///
/// A text caption echoes back the selected coordinate as plain-language
/// confirmation with full screen-reader [Semantics] support.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    required this.initial,
    required this.onChanged,
    super.key,
  });

  /// Current value, if any. `(0, 0)` is treated the same as null — it's the
  /// unset placeholder, never a real coordinate to center on.
  final GeoCoordinates? initial;
  final ValueChanged<GeoCoordinates> onChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _marker;
  bool _isLocating = false;

  bool get _hasRealInitial {
    final initial = widget.initial;
    return initial != null && (initial.latitude != 0 || initial.longitude != 0);
  }

  LatLng get _initialCameraTarget => _hasRealInitial
      ? LatLng(widget.initial!.latitude, widget.initial!.longitude)
      : _defaultCenter;

  @override
  void initState() {
    super.initState();
    if (_hasRealInitial) {
      _marker = _initialCameraTarget;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _selectPoint(LatLng point, {bool animateCamera = false}) {
    setState(() => _marker = point);
    if (animateCamera && kIsWeb) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, _pickedZoom));
    }
    widget.onChanged(GeoCoordinates(latitude: point.latitude, longitude: point.longitude));
  }

  Future<void> _useCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    void notify(String message) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        notify('Location services are turned off. Please enable them in your device settings.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        notify('Location permission was declined. You can still set your locality above.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        notify('Location permission is blocked. Please enable it in your device or browser settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      _selectPoint(LatLng(position.latitude, position.longitude), animateCamera: true);
      notify('Location updated: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
    } catch (_) {
      notify("Couldn't retrieve current location. Please verify GPS is enabled and try again.");
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final statusText = _marker == null
        ? 'No location pinned yet.'
        : 'Selected: ${_marker!.latitude.toStringAsFixed(4)}, '
            '${_marker!.longitude.toStringAsFixed(4)}';

    return Semantics(
      container: true,
      label: 'Location picker. Current status: $statusText',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your location', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: SizedBox(
              height: 220,
              child: kIsWeb
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _initialCameraTarget,
                        zoom: _defaultZoom,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: (point) => _selectPoint(point),
                      markers: {
                        if (_marker != null)
                          Marker(
                            markerId: const MarkerId('selected-location'),
                            position: _marker!,
                          ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    )
                  : Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.cardAll,
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _marker != null ? Icons.location_on : Icons.location_searching,
                              size: 44,
                              color: _marker != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _marker != null
                                  ? 'GPS Pin Set'
                                  : 'Map view available on Web',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _marker != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _marker != null
                                  ? '${_marker!.latitude.toStringAsFixed(4)}, ${_marker!.longitude.toStringAsFixed(4)}'
                                  : 'Tap "Use my current location" below to capture device GPS.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            kIsWeb && _marker == null
                ? 'Tap anywhere on the map to set your area, or use the button below.'
                : statusText,
            style: subtleStyle,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Use my current location',
            icon: Icons.my_location,
            isLoading: _isLocating,
            onPressed: _useCurrentLocation,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This helps us find companions and volunteers near you — you can leave it approximate.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
