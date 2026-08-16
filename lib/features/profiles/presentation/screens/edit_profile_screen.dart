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
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

/// Owner: Perera (features/profiles). Real form for creating/editing the
/// signed-in user's profile, wired to [GetProfileUseCase]'s live stream and
/// [UpdateProfileUseCase]. Availability windows and accessibility
/// preferences aren't editable here yet — they pass through unchanged.
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
    _photoUrl = base.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _localityController.dispose();
    _skillsController.dispose();
    _helpController.dispose();
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
