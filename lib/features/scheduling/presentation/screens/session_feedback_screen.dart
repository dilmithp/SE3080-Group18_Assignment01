import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/features/scheduling/presentation/providers/scheduling_providers.dart';

/// Placeholder screen — owner: Ranketh (features/scheduling).
///
/// The "Submit" button calls the real (currently stubbed) use case so the
/// DI wiring can be exercised end-to-end.
class SessionFeedbackScreen extends ConsumerStatefulWidget {
  const SessionFeedbackScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionFeedbackScreen> createState() =>
      _SessionFeedbackScreenState();
}

class _SessionFeedbackScreenState extends ConsumerState<SessionFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ratingController = TextEditingController(text: '5');
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ratingController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(submitFeedbackUseCaseProvider);
      final result = await useCase(
        sessionId: widget.sessionId,
        raterId: 'current-user-id',
        rating: int.parse(_ratingController.text),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      result.fold(
        (failure) => _showMessage(failure.message),
        (feedback) => _showMessage('Feedback submitted.'),
      );
    } on UnimplementedError catch (e) {
      _showMessage(e.message ?? 'Not implemented yet.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave feedback')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Session ${widget.sessionId}\nOwner: Ranketh — features/scheduling',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Rating (1-5)',
                  controller: _ratingController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final rating = int.tryParse(value ?? '');
                    if (rating == null || rating < 1 || rating > 5) {
                      return 'Enter a rating from 1 to 5.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Comment (optional)',
                  controller: _commentController,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Submit',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
