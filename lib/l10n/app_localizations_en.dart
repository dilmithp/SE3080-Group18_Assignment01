// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Elderly Companion';

  @override
  String get homeTitle => 'Elderly Companion';

  @override
  String get homeWhatToDo => 'What would you like to do?';

  @override
  String get homeAccessibility => 'Accessibility';

  @override
  String get navProfile => 'Profile';

  @override
  String get navMatching => 'Find Companions';

  @override
  String get navScheduling => 'Scheduling';

  @override
  String get navMessages => 'Messages';

  @override
  String get navCommunity => 'Community';

  @override
  String get signOut => 'Sign out';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEditTooltip => 'Edit profile';

  @override
  String get profileCompleteAction => 'Complete profile';

  @override
  String get profileEmptyTitle => 'Your profile is empty';

  @override
  String get profileEmptyMessage =>
      'Add your name, interests and availability so companions and helpers can find you.';

  @override
  String get profileCompletenessComplete => 'Your profile is complete';

  @override
  String profileCompletenessPercent(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String get profileNextSteps => 'Next steps';

  @override
  String get profileAbout => 'About';

  @override
  String get profileLanguages => 'Languages';

  @override
  String get profileSafetyPreferences => 'Safety preferences';

  @override
  String get profileSkillsOffered => 'Skills offered';

  @override
  String get profileHelpNeeded => 'Help needed';

  @override
  String get profileAvailability => 'Availability';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileDisplayName => 'Display name';

  @override
  String get editProfileLocality => 'Locality';

  @override
  String get editProfileLocalityHint => 'Your neighbourhood';

  @override
  String get editProfileBio => 'About you';

  @override
  String editProfileBioMaxLength(int max) {
    return 'Bio must be at most $max characters.';
  }

  @override
  String get editProfileSkills => 'Skills you offer';

  @override
  String get editProfileSkillsHint => 'e.g. gardening, cooking, tech help';

  @override
  String get editProfileHelpNeeded => 'Help you need';

  @override
  String get editProfileHelpHint => 'e.g. grocery runs, company on walks';

  @override
  String get editProfileLanguages => 'Languages you speak';

  @override
  String get editProfileLanguagesHint => 'e.g. English, Sinhala, Tamil';

  @override
  String get editProfileLanguagesHelper =>
      'Helps you find a volunteer who speaks your language';

  @override
  String get editProfileSafetyPreferences => 'Safety preferences';

  @override
  String get editProfileCommunicationNotes => 'Communication notes (optional)';

  @override
  String get editProfileCommunicationNotesHint =>
      'e.g. speaks slowly, prefers texting, hard of hearing on the left';

  @override
  String get editProfileEmergencyContact => 'Emergency contact';

  @override
  String get editProfileContactName => 'Contact name (optional)';

  @override
  String get editProfileContactNameHint =>
      'e.g. a family member or close friend';

  @override
  String get editProfileContactPhone => 'Contact phone (optional)';

  @override
  String get editProfileContactPhoneHint => 'e.g. +94 71 234 5678';

  @override
  String get editProfileAddAvailability => 'Add availability';

  @override
  String get editProfileSave => 'Save profile';

  @override
  String get editProfileSaved => 'Profile saved.';

  @override
  String editProfileTagTooLong(int max) {
    return 'Each tag must be at most $max characters.';
  }

  @override
  String editProfileTooManyTags(int max) {
    return 'Add at most $max tags.';
  }

  @override
  String get availabilityAdded => 'Availability added.';

  @override
  String get availabilityRemoved => 'Availability window removed.';

  @override
  String get availabilityUndoRemove => 'Undo';

  @override
  String get accessibilitySettingsTitle => 'Accessibility Settings';

  @override
  String get accessibilityCustomise => 'Customize Your Experience';

  @override
  String get accessibilityCustomiseSubtitle =>
      'Adjust text sizes, screen contrast, and navigation to best fit your comfort.';

  @override
  String accessibilityTextSize(int percent) {
    return 'Text Size ($percent%)';
  }

  @override
  String get accessibilityTextPreview => 'Preview text size below:';

  @override
  String get accessibilityPreviewSentence =>
      'Elderly Companionship & Micro-Volunteering platform text preview.';

  @override
  String get accessibilityStandard => 'Standard';

  @override
  String get accessibilityLarge => 'Large';

  @override
  String get accessibilityExtraLarge => 'Extra Large';

  @override
  String get accessibilityDisplayLayout => 'Display & Layout';

  @override
  String get accessibilityHighContrast => 'High Contrast Mode';

  @override
  String get accessibilityHighContrastDesc =>
      'Increases text and button contrast for higher readability.';

  @override
  String get accessibilitySimplified => 'Simplified Interface';

  @override
  String get accessibilitySimplifiedDesc =>
      'Reduces visual clutter and enlarges touch controls.';

  @override
  String get accessibilityReducedMotion => 'Reduced Motion';

  @override
  String get accessibilityReducedMotionDesc =>
      'Disables decorative animations throughout the app.';

  @override
  String get accessibilityAssistanceAudio => 'Assistance & Audio';

  @override
  String get accessibilityVoiceGuided => 'Voice-Guided Prompts';

  @override
  String get accessibilityVoiceGuidedDesc =>
      'Reads out guidance hints for screen actions and forms.';

  @override
  String get accessibilityDataSaver => 'Data Saver';

  @override
  String get accessibilityDataSaverDesc =>
      'Shrinks photo uploads and hides images in lists to reduce data use.';

  @override
  String get accessibilityLanguage => 'Language';

  @override
  String get accessibilityLanguageDesc =>
      'Choose the language for the app interface.';

  @override
  String get accessibilityReset => 'Reset Accessibility Defaults';

  @override
  String get accessibilityResetConfirm =>
      'Accessibility preferences reset to default.';

  @override
  String get offlineBanner => 'You are offline';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String callButtonLabel(String name) {
    return 'Call $name';
  }

  @override
  String get callButtonFallback => 'Call emergency contact';

  @override
  String get langPickerTitle => 'Choose Language';

  @override
  String get langEnglish => 'English';

  @override
  String get langSinhala => 'සිංහල';

  @override
  String get langTamil => 'தமிழ்';
}
