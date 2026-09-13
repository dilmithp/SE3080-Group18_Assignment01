import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Elderly Companion'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Elderly Companion'**
  String get homeTitle;

  /// No description provided for @homeWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get homeWhatToDo;

  /// No description provided for @homeAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get homeAccessibility;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navMatching.
  ///
  /// In en, this message translates to:
  /// **'Find Companions'**
  String get navMatching;

  /// No description provided for @navScheduling.
  ///
  /// In en, this message translates to:
  /// **'Scheduling'**
  String get navScheduling;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTooltip;

  /// No description provided for @profileCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get profileCompleteAction;

  /// No description provided for @profileEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is empty'**
  String get profileEmptyTitle;

  /// No description provided for @profileEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your name, interests and availability so companions and helpers can find you.'**
  String get profileEmptyMessage;

  /// No description provided for @profileCompletenessComplete.
  ///
  /// In en, this message translates to:
  /// **'Your profile is complete'**
  String get profileCompletenessComplete;

  /// No description provided for @profileCompletenessPercent.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String profileCompletenessPercent(int percent);

  /// No description provided for @profileNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get profileNextSteps;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileLanguages;

  /// No description provided for @profileSafetyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Safety preferences'**
  String get profileSafetyPreferences;

  /// No description provided for @profileSkillsOffered.
  ///
  /// In en, this message translates to:
  /// **'Skills offered'**
  String get profileSkillsOffered;

  /// No description provided for @profileHelpNeeded.
  ///
  /// In en, this message translates to:
  /// **'Help needed'**
  String get profileHelpNeeded;

  /// No description provided for @profileAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get profileAvailability;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get editProfileDisplayName;

  /// No description provided for @editProfileLocality.
  ///
  /// In en, this message translates to:
  /// **'Locality'**
  String get editProfileLocality;

  /// No description provided for @editProfileLocalityHint.
  ///
  /// In en, this message translates to:
  /// **'Your neighbourhood'**
  String get editProfileLocalityHint;

  /// No description provided for @editProfileBio.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get editProfileBio;

  /// No description provided for @editProfileBioMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Bio must be at most {max} characters.'**
  String editProfileBioMaxLength(int max);

  /// No description provided for @editProfileSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills you offer'**
  String get editProfileSkills;

  /// No description provided for @editProfileSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. gardening, cooking, tech help'**
  String get editProfileSkillsHint;

  /// No description provided for @editProfileHelpNeeded.
  ///
  /// In en, this message translates to:
  /// **'Help you need'**
  String get editProfileHelpNeeded;

  /// No description provided for @editProfileHelpHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. grocery runs, company on walks'**
  String get editProfileHelpHint;

  /// No description provided for @editProfileLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages you speak'**
  String get editProfileLanguages;

  /// No description provided for @editProfileLanguagesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. English, Sinhala, Tamil'**
  String get editProfileLanguagesHint;

  /// No description provided for @editProfileLanguagesHelper.
  ///
  /// In en, this message translates to:
  /// **'Helps you find a volunteer who speaks your language'**
  String get editProfileLanguagesHelper;

  /// No description provided for @editProfileSafetyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Safety preferences'**
  String get editProfileSafetyPreferences;

  /// No description provided for @editProfileCommunicationNotes.
  ///
  /// In en, this message translates to:
  /// **'Communication notes (optional)'**
  String get editProfileCommunicationNotes;

  /// No description provided for @editProfileCommunicationNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. speaks slowly, prefers texting, hard of hearing on the left'**
  String get editProfileCommunicationNotesHint;

  /// No description provided for @editProfileEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get editProfileEmergencyContact;

  /// No description provided for @editProfileContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name (optional)'**
  String get editProfileContactName;

  /// No description provided for @editProfileContactNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. a family member or close friend'**
  String get editProfileContactNameHint;

  /// No description provided for @editProfileContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone (optional)'**
  String get editProfileContactPhone;

  /// No description provided for @editProfileContactPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +94 71 234 5678'**
  String get editProfileContactPhoneHint;

  /// No description provided for @editProfileAddAvailability.
  ///
  /// In en, this message translates to:
  /// **'Add availability'**
  String get editProfileAddAvailability;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get editProfileSave;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get editProfileSaved;

  /// No description provided for @editProfileTagTooLong.
  ///
  /// In en, this message translates to:
  /// **'Each tag must be at most {max} characters.'**
  String editProfileTagTooLong(int max);

  /// No description provided for @editProfileTooManyTags.
  ///
  /// In en, this message translates to:
  /// **'Add at most {max} tags.'**
  String editProfileTooManyTags(int max);

  /// No description provided for @availabilityAdded.
  ///
  /// In en, this message translates to:
  /// **'Availability added.'**
  String get availabilityAdded;

  /// No description provided for @availabilityRemoved.
  ///
  /// In en, this message translates to:
  /// **'Availability window removed.'**
  String get availabilityRemoved;

  /// No description provided for @availabilityUndoRemove.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get availabilityUndoRemove;

  /// No description provided for @accessibilitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Settings'**
  String get accessibilitySettingsTitle;

  /// No description provided for @accessibilityCustomise.
  ///
  /// In en, this message translates to:
  /// **'Customize Your Experience'**
  String get accessibilityCustomise;

  /// No description provided for @accessibilityCustomiseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust text sizes, screen contrast, and navigation to best fit your comfort.'**
  String get accessibilityCustomiseSubtitle;

  /// No description provided for @accessibilityTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size ({percent}%)'**
  String accessibilityTextSize(int percent);

  /// No description provided for @accessibilityTextPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview text size below:'**
  String get accessibilityTextPreview;

  /// No description provided for @accessibilityPreviewSentence.
  ///
  /// In en, this message translates to:
  /// **'Elderly Companionship & Micro-Volunteering platform text preview.'**
  String get accessibilityPreviewSentence;

  /// No description provided for @accessibilityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get accessibilityStandard;

  /// No description provided for @accessibilityLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get accessibilityLarge;

  /// No description provided for @accessibilityExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get accessibilityExtraLarge;

  /// No description provided for @accessibilityDisplayLayout.
  ///
  /// In en, this message translates to:
  /// **'Display & Layout'**
  String get accessibilityDisplayLayout;

  /// No description provided for @accessibilityHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High Contrast Mode'**
  String get accessibilityHighContrast;

  /// No description provided for @accessibilityHighContrastDesc.
  ///
  /// In en, this message translates to:
  /// **'Increases text and button contrast for higher readability.'**
  String get accessibilityHighContrastDesc;

  /// No description provided for @accessibilitySimplified.
  ///
  /// In en, this message translates to:
  /// **'Simplified Interface'**
  String get accessibilitySimplified;

  /// No description provided for @accessibilitySimplifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduces visual clutter and enlarges touch controls.'**
  String get accessibilitySimplifiedDesc;

  /// No description provided for @accessibilityReducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduced Motion'**
  String get accessibilityReducedMotion;

  /// No description provided for @accessibilityReducedMotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Disables decorative animations throughout the app.'**
  String get accessibilityReducedMotionDesc;

  /// No description provided for @accessibilityAssistanceAudio.
  ///
  /// In en, this message translates to:
  /// **'Assistance & Audio'**
  String get accessibilityAssistanceAudio;

  /// No description provided for @accessibilityVoiceGuided.
  ///
  /// In en, this message translates to:
  /// **'Voice-Guided Prompts'**
  String get accessibilityVoiceGuided;

  /// No description provided for @accessibilityVoiceGuidedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reads out guidance hints for screen actions and forms.'**
  String get accessibilityVoiceGuidedDesc;

  /// No description provided for @accessibilityDataSaver.
  ///
  /// In en, this message translates to:
  /// **'Data Saver'**
  String get accessibilityDataSaver;

  /// No description provided for @accessibilityDataSaverDesc.
  ///
  /// In en, this message translates to:
  /// **'Shrinks photo uploads and hides images in lists to reduce data use.'**
  String get accessibilityDataSaverDesc;

  /// No description provided for @accessibilityLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accessibilityLanguage;

  /// No description provided for @accessibilityLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app interface.'**
  String get accessibilityLanguageDesc;

  /// No description provided for @accessibilityReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Accessibility Defaults'**
  String get accessibilityReset;

  /// No description provided for @accessibilityResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accessibility preferences reset to default.'**
  String get accessibilityResetConfirm;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offlineBanner;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @callButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callButtonLabel(String name);

  /// No description provided for @callButtonFallback.
  ///
  /// In en, this message translates to:
  /// **'Call emergency contact'**
  String get callButtonFallback;

  /// No description provided for @langPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get langPickerTitle;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langSinhala.
  ///
  /// In en, this message translates to:
  /// **'සිංහල'**
  String get langSinhala;

  /// No description provided for @langTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get langTamil;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
