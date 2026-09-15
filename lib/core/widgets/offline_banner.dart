import 'dart:async';

import 'package:flutter/material.dart';

import 'package:elderly_companion/core/widgets/connectivity_check_web.dart'
    if (dart.library.io) 'package:elderly_companion/core/widgets/connectivity_check_io.dart'
    as connectivity;
import 'package:elderly_companion/l10n/app_localizations.dart';

/// A slim banner that appears at the very top of the screen whenever the
/// device loses network connectivity. It disappears automatically when
/// connectivity is restored.
///
/// The actual connectivity probe is platform-conditional (see
/// connectivity_check_io.dart / connectivity_check_web.dart) — `dart:io` is
/// unavailable when compiling for web, so this file never imports it
/// directly, even behind a runtime `kIsWeb` guard.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final offline = await connectivity.isOffline();
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;

    return Semantics(
      label: 'Offline banner: ${loc.offlineBanner}',
      liveRegion: true,
      child: Material(
        elevation: 0,
        color: Theme.of(context).colorScheme.error,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 8),
                Text(
                  loc.offlineBanner,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
