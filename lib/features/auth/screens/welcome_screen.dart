import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_sign_in_button.dart';

/// The single entry screen for signed-out users: toggles between sign-in
/// and sign-up, plus Google/Apple. See `auth_controller.dart` for the
/// actual logic — this screen only reads form fields and shows
/// loading/error state.
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
      controller.signUpWithEmail(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());
    } else {
      controller.signInWithEmail(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.authError)));
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 72, color: AppColors.gold)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.7, 0.7)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _isSignUp ? l10n.authWelcomeSubtitle : l10n.authWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: AppSpacing.xl),
                    Card(
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (_isSignUp) ...[
                                AuthTextField(
                                  controller: _nameController,
                                  label: l10n.authDisplayName,
                                  validator: (v) => Validators.displayName(v) == null ? null : l10n.authError,
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
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(_isSignUp ? l10n.authSignUp : l10n.authSignIn),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                                child: Text(_isSignUp ? l10n.authSwitchToSignIn : l10n.authSwitchToSignUp),
                              ),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                    child: Text(l10n.authOrDivider, style: Theme.of(context).textTheme.bodyMedium),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
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
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
