import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/giants_logo.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_sign_in_button.dart';

/// The single entry screen for signed-out players: toggles between sign-in
/// and sign-up, plus Google/Apple.
///
/// Structured as an arena banner over a light form rather than a card
/// floating on a gradient — the banner carries the identity, the form stays
/// legible and boring on purpose. See `auth_controller.dart` for the actual
/// logic; this screen only reads form fields and shows loading/error state.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      controller.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    } else {
      controller.signInWithEmail(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.authError)));
      }
    });

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ArenaPanel(
            gradient: AppColors.arenaGradient,
            slantHeight: 32,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                const GiantsMonogram(size: 72),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.authWelcomeTitle.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 26, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.authWelcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onArenaMuted),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _ModeToggle(
                    isSignUp: _isSignUp,
                    signInLabel: l10n.authSignIn,
                    signUpLabel: l10n.authSignUp,
                    onChanged: (value) => setState(() => _isSignUp = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isSignUp) ...[
                          AuthTextField(
                            controller: _nameController,
                            label: l10n.authDisplayName,
                            validator: (v) =>
                                Validators.displayName(v) == null ? null : l10n.authError,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AuthTextField(
                          controller: _emailController,
                          label: l10n.authEmail,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => Validators.email(v) == null ? null : l10n.authError,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AuthTextField(
                          controller: _passwordController,
                          label: l10n.authPassword,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) => Validators.password(v) == null ? null : l10n.authError,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  isLoading
                      ? const SizedBox(
                          height: 52,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
                        )
                      : SlabButton(
                          label: _isSignUp ? l10n.authSignUp : l10n.authSignIn,
                          gradient: AppColors.primaryGradient,
                          background: AppColors.primary,
                          onPressed: _submit,
                        ),
                  const SizedBox(height: AppSpacing.lg),
                  _OrDivider(label: l10n.authOrDivider),
                  const SizedBox(height: AppSpacing.md),
                  SocialSignInButton(
                    label: l10n.authSignInWithGoogle,
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SocialSignInButton(
                    label: l10n.authSignInWithApple,
                    icon: Icons.apple_rounded,
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signInWithApple(),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms).moveY(begin: 12, end: 0),
        ],
      ),
    );
  }
}

/// A two-up segmented switch. Replaces the old "Don't have an account?
/// Create one" text button — the choice is binary and permanent enough to
/// deserve a control rather than a sentence.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isSignUp,
    required this.signInLabel,
    required this.signUpLabel,
    required this.onChanged,
  });

  final bool isSignUp;
  final String signInLabel;
  final String signUpLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(child: _Segment(label: signInLabel, selected: !isSignUp, onTap: () => onChanged(false))),
          Expanded(child: _Segment(label: signUpLabel, selected: isSignUp, onTap: () => onChanged(true))),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
