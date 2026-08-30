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

/// Reusable map widget for picking a profile's home coordinate.
///
/// Renders a fixed-height [GoogleMap]; tapping it drops/moves a single
/// [Marker] and reports the tapped point via [onChanged]. A prominent
/// "Use my current location" button offers a one-tap alternative to tapping
/// a precise spot on the map — important for this app's elderly users, who
/// shouldn't have to rely on hitting a tiny pin accurately. A text caption
/// under the map echoes back the selected coordinate as plain-language
/// confirmation, and a helper line beneath explains why the app wants this.
///
/// Web-only for now: this repo has no `android/`/`ios/` runner folder yet
/// (see CLAUDE.md), so native Google Maps API key wiring
/// (`AndroidManifest` meta-data, `GMSServices.provideAPIKey`) hasn't been
/// done and can't be from here. The web JS SDK is already loaded by
/// `web/index.html`/`web/maps_config.js`.
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
    if (animateCamera) {
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
        notify('Location services are turned off. Turn them on to use this, '
            'or tap the map to set your area instead.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        notify('Location permission was declined — you can still tap the '
            'map to set your area.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        notify('Location permission is blocked in your browser settings. '
            'You can still tap the map to set your area.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _selectPoint(LatLng(position.latitude, position.longitude), animateCamera: true);
    } catch (_) {
      notify("Couldn't get your current location. You can still tap the "
          'map to set your area.');
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your location', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.cardAll,
          child: SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCameraTarget,
                zoom: _defaultZoom,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (point) => _selectPoint(point),
              markers: {
                if (_marker != null)
                  Marker(markerId: const MarkerId('selected-location'), position: _marker!),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _marker == null
              ? 'Tap anywhere on the map to set your area.'
              : 'Selected: ${_marker!.latitude.toStringAsFixed(4)}, '
                  '${_marker!.longitude.toStringAsFixed(4)}',
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
          'This helps us find companions and volunteers near you — you can '
          'leave it approximate.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
