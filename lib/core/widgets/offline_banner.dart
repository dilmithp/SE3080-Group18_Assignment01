import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A slim banner that appears at the very top of the screen whenever the
/// device loses network connectivity. It disappears automatically when
/// connectivity is restored.
///
/// Implementation note: we poll connectivity via [InternetAddress.lookup]
/// because `connectivity_plus` adds a transitive dependency the project hasn't
/// taken yet. The poll is infrequent (every 5 s) and stops when the widget is
/// disposed, so the overhead is negligible.
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
    if (kIsWeb) return;
    bool offline;
    try {
      // A lightweight DNS lookup to google.com — succeeds when online, throws
      // when fully offline.
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      offline = result.isEmpty || result.first.rawAddress.isEmpty;
    } catch (_) {
      offline = true;
    }
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Semantics(
      label: 'Offline banner: You are currently offline',
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
                  'You are offline',
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
