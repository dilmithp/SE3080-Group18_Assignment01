import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/availability_window.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/safety_preference.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/widgets/location_picker.dart';
import 'package:elderly_companion/l10n/app_localizations.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String _formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// Owner: Perera (features/profiles). Real form for creating/editing the
/// signed-in user's profile, wired to [GetProfileUseCase]'s live stream and
/// [UpdateProfileUseCase]. Of `accessibilityPrefs`, only `communicationNotes`
/// is editable here — `largeText`/`highContrast`/`simplifiedInterface` are
/// device-display settings owned by AccessibilitySettingsScreen (which
/// writes them through to the profile itself; see
/// AccessibilityProfileSync), so they pass through unchanged from here.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.editProfileTitle)),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return const EmptyView(
              icon: Icons.lock_outline,
              title: 'Sign in first',
              message: 'You need to be signed in to edit your profile.',
            );
          }
          return _EditProfileLoader(userId: user.id);
        },
      ),
    );
  }
}

class _EditProfileLoader extends ConsumerWidget {
  const _EditProfileLoader({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(userId));

    return profileAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (profile) => _EditProfileForm(userId: userId, initial: profile),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.userId, required this.initial});

  final String userId;
  final UserProfile? initial;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _localityController;
  late final TextEditingController _skillsController;
  late final TextEditingController _helpController;
  late final TextEditingController _languagesController;
  late Set<String> _safetySelection;
  late final TextEditingController _communicationNotesController;
  late final TextEditingController _emergencyContactNameController;
  late final TextEditingController _emergencyContactPhoneController;
  late List<AvailabilityWindow> _availabilityWindows;
  late GeoCoordinates _geoPoint;

  String? _photoUrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  UserProfile get _base =>
      widget.initial ??
      UserProfile(
        userId: widget.userId,
        displayName: '',
        bio: '',
        locality: '',
        geoPoint: const GeoCoordinates(latitude: 0, longitude: 0),
        skillsOffered: const [],
        helpNeeded: const [],
        availabilityWindows: const [],
        accessibilityPrefs: const AccessibilityPreferences(
          largeText: false,
          highContrast: false,
          simplifiedInterface: false,
        ),
      );

  @override
  void initState() {
    super.initState();
    final base = _base;
    _nameController = TextEditingController(text: base.displayName);
    _bioController = TextEditingController(text: base.bio);
    _localityController = TextEditingController(text: base.locality);
    _skillsController = TextEditingController(text: base.skillsOffered.join(', '));
    _helpController = TextEditingController(text: base.helpNeeded.join(', '));
    _languagesController =
        TextEditingController(text: base.languagesSpoken.join(', '));
    _safetySelection = {...base.safetyPreferences};
    _communicationNotesController =
        TextEditingController(text: base.accessibilityPrefs.communicationNotes ?? '');
    _emergencyContactNameController =
        TextEditingController(text: base.emergencyContactName ?? '');
    _emergencyContactPhoneController =
        TextEditingController(text: base.emergencyContactPhone ?? '');
    _availabilityWindows = List.of(base.availabilityWindows);
    _geoPoint = base.geoPoint;
    _photoUrl = base.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _localityController.dispose();
    _skillsController.dispose();
    _languagesController.dispose();
    _helpController.dispose();
    _communicationNotesController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String text) => text
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();

  Future<void> _changePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await ref.read(profileRepositoryProvider).uploadProfilePhoto(
            userId: widget.userId,
            bytes: bytes,
          );
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (url) => setState(() => _photoUrl = url),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _addAvailabilityWindow() async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    var selectedDay = _weekdays.first;
    var startTime = const TimeOfDay(hour: 9, minute: 0);
    var endTime = const TimeOfDay(hour: 12, minute: 0);

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.editProfileAddAvailability, style: Theme.of(sheetContext).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: [
                  for (final day in _weekdays)
                    DropdownMenuItem(value: day, child: Text(day)),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => selectedDay = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: startTime,
                        );
                        if (picked != null) setSheetState(() => startTime = picked);
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text('From ${startTime.format(sheetContext)}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: endTime,
                        );
                        if (picked != null) setSheetState(() => endTime = picked);
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text('To ${endTime.format(sheetContext)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Add',
                onPressed: () {
                  final start = _formatTimeOfDay(startTime);
                  final end = _formatTimeOfDay(endTime);
                  if (start.compareTo(end) >= 0) {
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('End time must be after start time.')),
                      );
                    return;
                  }
                  setState(() {
                    _availabilityWindows.add(
                      AvailabilityWindow(
                        dayOfWeek: selectedDay,
                        startTime: start,
                        endTime: end,
                      ),
                    );
                  });
                  Navigator.of(sheetContext).pop(true);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (added ?? false) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(loc.availabilityAdded)));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final updated = _base.copyWith(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        locality: _localityController.text.trim(),
        geoPoint: _geoPoint,
        skillsOffered: _parseTags(_skillsController.text),
        helpNeeded: _parseTags(_helpController.text),
        languagesSpoken: _parseTags(_languagesController.text),
        safetyPreferences: _safetySelection.toList(),
        availabilityWindows: _availabilityWindows,
        // Not `_base.accessibilityPrefs.copyWith(communicationNotes: ...)` —
        // that class's copyWith does `x ?? this.x`, so passing null to
        // clear a note would silently keep the old one. Rebuilding the
        // value directly sidesteps that.
        accessibilityPrefs: AccessibilityPreferences(
          largeText: _base.accessibilityPrefs.largeText,
          highContrast: _base.accessibilityPrefs.highContrast,
          simplifiedInterface: _base.accessibilityPrefs.simplifiedInterface,
          textScale: _base.accessibilityPrefs.textScale,
          communicationNotes: _communicationNotesController.text.trim().isEmpty
              ? null
              : _communicationNotesController.text.trim(),
        ),
        photoUrl: _photoUrl,
      );
      final emergencyContactName =
          _emergencyContactNameController.text.trim().isEmpty
              ? null
              : _emergencyContactNameController.text.trim();
      final emergencyContactPhone =
          _emergencyContactPhoneController.text.trim().isEmpty
              ? null
              : _emergencyContactPhoneController.text.trim();
      // Same `x ?? this.x` pitfall as accessibilityPrefs above, but at the
      // entity level this time: UserProfile.copyWith can't be used to clear
      // emergencyContactName/Phone to null once set, so rebuild the entity
      // directly for those two fields instead of chaining another copyWith.
      final withEmergencyContact = UserProfile(
        userId: updated.userId,
        displayName: updated.displayName,
        photoUrl: updated.photoUrl,
        bio: updated.bio,
        locality: updated.locality,
        geoPoint: updated.geoPoint,
        skillsOffered: updated.skillsOffered,
        helpNeeded: updated.helpNeeded,
        availabilityWindows: updated.availabilityWindows,
        accessibilityPrefs: updated.accessibilityPrefs,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        languagesSpoken: updated.languagesSpoken,
        safetyPreferences: updated.safetyPreferences,
      );
      final useCase = ref.read(updateProfileUseCaseProvider);
      final result = await useCase(withEmergencyContact);
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (_) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(loc.editProfileSaved)));
          if (context.canPop()) context.pop();
        },
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        _photoUrl == null || _photoUrl!.isEmpty
                            ? const AppStatusIcon(icon: Icons.person, size: 96)
                            : CircleAvatar(
                                radius: 48,
                                backgroundImage: NetworkImage(_photoUrl!),
                              ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Change photo',
                          icon: Icons.camera_alt_outlined,
                          secondary: true,
                          isLoading: _isUploadingPhoto,
                          onPressed: _changePhoto,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: loc.editProfileDisplayName,
                    controller: _nameController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) => Validators.required(value, fieldName: 'Name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: loc.editProfileLocality,
                    hint: loc.editProfileLocalityHint,
                    controller: _localityController,
                    prefixIcon: Icons.place_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LocationPicker(
                    initial: _geoPoint,
                    onChanged: (coords) => setState(() => _geoPoint = coords),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: loc.editProfileBio,
                    controller: _bioController,
                    maxLines: 4,
                    validator: (value) => Validators.maxLength(
                      value,
                      1000,
                      fieldName: 'Bio',
                      message: (max) => loc.editProfileBioMaxLength(max),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: loc.editProfileSkills,
                    hint: loc.editProfileSkillsHint,
                    helperText: 'Separate with commas',
                    controller: _skillsController,
                    validator: (value) => Validators.tagList(
                      value,
                      tooManyMessage: (max) => loc.editProfileTooManyTags(max),
                      tagTooLongMessage: (max) => loc.editProfileTagTooLong(max),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: loc.editProfileHelpNeeded,
                    hint: loc.editProfileHelpHint,
                    helperText: 'Separate with commas',
                    controller: _helpController,
                    validator: (value) => Validators.tagList(
                      value,
                      tooManyMessage: (max) => loc.editProfileTooManyTags(max),
                      tagTooLongMessage: (max) => loc.editProfileTagTooLong(max),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: loc.editProfileLanguages,
                    hint: loc.editProfileLanguagesHint,
                    helperText: loc.editProfileLanguagesHelper,
                    controller: _languagesController,
                    validator: (value) => Validators.tagList(
                      value,
                      tooManyMessage: (max) => loc.editProfileTooManyTags(max),
                      tagTooLongMessage: (max) => loc.editProfileTagTooLong(max),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    loc.editProfileSafetyPreferences,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final option in safetyPreferenceOptions)
                        FilterChip(
                          label: Text(option),
                          selected: _safetySelection.contains(option),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _safetySelection.add(option);
                            } else {
                              _safetySelection.remove(option);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: loc.editProfileCommunicationNotes,
                    hint: loc.editProfileCommunicationNotesHint,
                    helperText: 'Shown to a matched volunteer before a session',
                    controller: _communicationNotesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(loc.editProfileEmergencyContact, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: loc.editProfileContactName,
                    hint: loc.editProfileContactNameHint,
                    controller: _emergencyContactNameController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: loc.editProfileContactPhone,
                    hint: loc.editProfileContactPhoneHint,
                    helperText: 'Shown with a one-tap call button on your profile',
                    controller: _emergencyContactPhoneController,
                    prefixIcon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.optionalPhone,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(loc.profileAvailability, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (_availabilityWindows.isEmpty)
                    Text(
                      'No availability added yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    )
                  else
                    AppCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < _availabilityWindows.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == _availabilityWindows.length - 1 ? 0 : AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule_outlined),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      '${_availabilityWindows[i].dayOfWeek} '
                                      '${_availabilityWindows[i].startTime}–'
                                      '${_availabilityWindows[i].endTime}',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Remove',
                                    onPressed: () => setState(
                                      () => _availabilityWindows.removeAt(i),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: loc.editProfileAddAvailability,
                    icon: Icons.add,
                    secondary: true,
                    onPressed: _addAvailabilityWindow,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: loc.editProfileSave,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
