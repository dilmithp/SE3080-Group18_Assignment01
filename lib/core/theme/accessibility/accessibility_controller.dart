import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';

const _prefsKeyTextScale = 'accessibility.textScale';
const _prefsKeyHighContrast = 'accessibility.highContrast';
const _prefsKeySimplifiedMode = 'accessibility.simplifiedMode';
const _prefsKeyVoiceGuidedPrompts = 'accessibility.voiceGuidedPrompts';
const _prefsKeyReducedMotion = 'accessibility.reducedMotion';
const _prefsKeyDataSaver = 'accessibility.dataSaver';
const _prefsKeyLanguageCode = 'accessibility.languageCode';

/// Owns [AccessibilityState] and persists it with `shared_preferences` so
/// preferences survive app restarts. Consumed by app.dart to drive
/// `MaterialApp.router`'s theme and text scaling.
class AccessibilityController extends Notifier<AccessibilityState> {
  @override
  AccessibilityState build() {
    _load();
    return const AccessibilityState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AccessibilityState(
      textScale: prefs.getDouble(_prefsKeyTextScale) ?? 1.0,
      highContrast: prefs.getBool(_prefsKeyHighContrast) ?? false,
      simplifiedMode: prefs.getBool(_prefsKeySimplifiedMode) ?? false,
      voiceGuidedPrompts: prefs.getBool(_prefsKeyVoiceGuidedPrompts) ?? false,
      reducedMotion: prefs.getBool(_prefsKeyReducedMotion) ?? false,
      dataSaver: prefs.getBool(_prefsKeyDataSaver) ?? false,
      languageCode: prefs.getString(_prefsKeyLanguageCode),
    );
  }

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(
      AccessibilityState.minTextScale,
      AccessibilityState.maxTextScale,
    );
    state = state.copyWith(textScale: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKeyTextScale, clamped);
  }

  Future<void> setHighContrast(bool enabled) async {
    state = state.copyWith(highContrast: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyHighContrast, enabled);
  }

  Future<void> setSimplifiedMode(bool enabled) async {
    state = state.copyWith(simplifiedMode: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeySimplifiedMode, enabled);
  }

  Future<void> setVoiceGuidedPrompts(bool enabled) async {
    state = state.copyWith(voiceGuidedPrompts: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyVoiceGuidedPrompts, enabled);
  }

  Future<void> setReducedMotion(bool enabled) async {
    state = state.copyWith(reducedMotion: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyReducedMotion, enabled);
  }

  Future<void> setDataSaver(bool enabled) async {
    state = state.copyWith(dataSaver: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyDataSaver, enabled);
  }

  /// Sets the app's language. `null` goes back to following the device's
  /// own locale.
  Future<void> setLanguage(String? languageCode) async {
    state = state.copyWith(languageCode: languageCode, clearLanguageCode: languageCode == null);
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_prefsKeyLanguageCode);
    } else {
      await prefs.setString(_prefsKeyLanguageCode, languageCode);
    }
  }

  /// Merges in values read from the signed-in user's persisted profile
  /// (`UserProfile.accessibilityPrefs`, owned by features/profiles) without
  /// this class knowing that type exists — the caller maps that shape down
  /// to these three primitives first. [voiceGuidedPrompts] has no persisted
  /// counterpart, so it's left untouched.
  Future<void> seedFrom({
    required bool highContrast,
    required bool simplifiedMode,
    required double textScale,
  }) async {
    final clamped = textScale.clamp(
      AccessibilityState.minTextScale,
      AccessibilityState.maxTextScale,
    );
    state = state.copyWith(
      highContrast: highContrast,
      simplifiedMode: simplifiedMode,
      textScale: clamped,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyHighContrast, highContrast);
    await prefs.setBool(_prefsKeySimplifiedMode, simplifiedMode);
    await prefs.setDouble(_prefsKeyTextScale, clamped);
  }
}

final accessibilityControllerProvider =
    NotifierProvider<AccessibilityController, AccessibilityState>(
  AccessibilityController.new,
);
