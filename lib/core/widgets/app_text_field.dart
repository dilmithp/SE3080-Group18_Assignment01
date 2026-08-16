import 'package:flutter/material.dart';

/// Standard text input. Wraps [TextFormField] with a visible label (never
/// label-as-hint-only — low-vision users lose the label once they start
/// typing) and a semantics-friendly error slot.
///
/// Obscured fields get a show/hide toggle. Typing a password blind is a real
/// failure mode for users with reduced dexterity, and a masked field they
/// cannot check is a common reason sign-in gets abandoned.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.textInputAction,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;

  /// Example input, shown alongside the always-visible label rather than
  /// instead of it.
  final String? hint;

  /// Persistent guidance below the field — preferred over a hint for rules
  /// the user needs while typing, not just before.
  final String? helperText;

  final IconData? prefixIcon;
  final TextInputAction? textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  Widget? _visibilityToggle() {
    if (!widget.obscureText) return null;
    return IconButton(
      icon: Icon(
        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      tooltip: _obscured ? 'Show password' : 'Hide password',
      onPressed: () => setState(() => _obscured = !_obscured),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      textInputAction: widget.textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: _visibilityToggle(),
        alignLabelWithHint: widget.maxLines > 1,
      ),
    );
  }
}
