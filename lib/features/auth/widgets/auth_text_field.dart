import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// A labelled input for the auth form.
///
/// The label sits *above* the field as a small uppercase caption rather than
/// as a Material floating label. A floating label animates into the field's
/// own box, which means the field is a different height before and after
/// focus and the form visibly reflows as you tab through it — and it makes
/// every input look like stock Material. A fixed caption keeps the rhythm
/// still and matches the overline treatment used above every number in the
/// app.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.md,
            ),
            // The caption above is the label; an error string here would
            // duplicate it, so validation shows as the border color only.
            errorStyle: TextStyle(height: 0.6, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
