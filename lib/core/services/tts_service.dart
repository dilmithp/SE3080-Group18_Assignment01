import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] that exposes a single [speak] method.
///
/// Call sites are not expected to import [FlutterTts] directly. Usage:
/// ```dart
/// final tts = ref.read(ttsServiceProvider);
/// await tts.speak('Profile saved', voiceGuidedEnabled: state.voiceGuidedPrompts);
/// ```
///
/// On web, [FlutterTts] uses the browser SpeechSynthesis API; on Android/iOS
/// it delegates to the native TTS engine. The service is silent on platforms
/// that don't have a supported engine (e.g. some emulators).
class TtsService {
  TtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _tts.setSharedInstance(true);
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // Slower for elderly users
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Sets the TTS language based on the app locale code ('en', 'si', 'ta').
  Future<void> setLocale(String languageCode) async {
    final lang = switch (languageCode) {
      'si' => 'si-LK',
      'ta' => 'ta-LK',
      _ => 'en-US',
    };
    try {
      await _tts.setLanguage(lang);
    } catch (_) {
      // Fall back silently — some engines don't have si-LK/ta-LK.
    }
  }

  /// Speaks [text] if [voiceGuidedEnabled] is true and the engine is ready.
  /// Interrupts any currently speaking prompt before starting the new one.
  Future<void> speak(String text, {required bool voiceGuidedEnabled}) async {
    if (!voiceGuidedEnabled || !_ready) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Silently swallow TTS errors — the screen must still work without audio.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
  }
}
