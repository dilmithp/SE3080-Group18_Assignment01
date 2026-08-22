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
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
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
  late final TextEditingController _communicationNotesController;
  late List<AvailabilityWindow> _availabilityWindows;

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
    _communicationNotesController =
        TextEditingController(text: base.accessibilityPrefs.communicationNotes ?? '');
    _availabilityWindows = List.of(base.availabilityWindows);
    _photoUrl = base.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _localityController.dispose();
    _skillsController.dispose();
    _helpController.dispose();
    _communicationNotesController.dispose();
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
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final result = await ref.read(profileRepositoryProvider).uploadProfilePhoto(
            userId: widget.userId,
            filePath: picked.path,
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
              Text('Add availability', style: Theme.of(sheetContext).textTheme.headlineMedium),
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
        ..showSnackBar(const SnackBar(content: Text('Availability added.')));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final updated = _base.copyWith(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        locality: _localityController.text.trim(),
        skillsOffered: _parseTags(_skillsController.text),
        helpNeeded: _parseTags(_helpController.text),
        availabilityWindows: _availabilityWindows,
        // Not `_base.accessibilityPrefs.copyWith(communicationNotes: ...)` —
        // that class's copyWith does `x ?? this.x`, so passing null to
        // clear a note would silently keep the old one. Rebuilding the
        // value directly sidesteps that.
        accessibilityPrefs: AccessibilityPreferences(
          largeText: _base.accessibilityPrefs.largeText,
          highContrast: _base.accessibilityPrefs.highContrast,
          simplifiedInterface: _base.accessibilityPrefs.simplifiedInterface,
          communicationNotes: _communicationNotesController.text.trim().isEmpty
              ? null
              : _communicationNotesController.text.trim(),
        ),
        photoUrl: _photoUrl,
      );
      final useCase = ref.read(updateProfileUseCaseProvider);
      final result = await useCase(updated);
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (_) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Profile saved.')));
          if (context.canPop()) context.pop();
        },
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    label: 'Display name',
                    controller: _nameController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) => Validators.required(value, fieldName: 'Name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Locality',
                    hint: 'Your neighbourhood',
                    controller: _localityController,
                    prefixIcon: Icons.place_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'About you',
                    controller: _bioController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Skills you offer',
                    hint: 'e.g. gardening, cooking, tech help',
                    helperText: 'Separate with commas',
                    controller: _skillsController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Help you need',
                    hint: 'e.g. grocery runs, company on walks',
                    helperText: 'Separate with commas',
                    controller: _helpController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Communication notes (optional)',
                    hint: 'e.g. speaks slowly, prefers texting, hard of '
                        'hearing on the left',
                    helperText: 'Shown to a matched volunteer before a session',
                    controller: _communicationNotesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Availability', style: Theme.of(context).textTheme.titleLarge),
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
                    label: 'Add availability',
                    icon: Icons.add,
                    secondary: true,
                    onPressed: _addAvailabilityWindow,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Save profile',
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
