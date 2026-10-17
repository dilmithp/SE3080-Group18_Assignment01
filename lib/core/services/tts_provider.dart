import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/services/tts_service.dart';

/// Application-wide singleton [TtsService] managed by Riverpod.
/// The service stays alive for the entire app session — disposing it would
/// stop any in-progress utterance and reinitialise unnecessarily.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});
