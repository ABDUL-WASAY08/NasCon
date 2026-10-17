import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../repositories/mock/mock_data.dart';
import '../../repositories/repository_providers.dart';

/// Screen 01 — Login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Guard against duplicate submissions — the button is also disabled while
    // loading, but a fast double-tap must not enqueue two requests.
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final sessionController = ref.read(sessionProvider.notifier);
      if (_isRegistering) {
        await sessionController.register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await sessionController.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = ErrorMapper.messageFor(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _useDemoAccount(DemoAccount account) {
    setState(() {
      _emailController.text = account.email;
      _passwordController.text = account.password;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showDemoAccounts = ref.watch(appConfigProvider).useMockBackend;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sheet),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.primaryGradient,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _isRegistering ? 'Create Account' : 'Welcome Back',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _isRegistering
                          ? 'Create your NaSCon league account'
                          : 'Sign in to your league account',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    if (_isRegistering) ...[
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full name',
                        hintText: 'Your name',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Enter at least 2 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email address',
                      hintText: 'you@example.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !_isLoading,
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !_isLoading,
                      validator: _isRegistering
                          ? (value) {
                              if (value == null || value.length < 8) {
                                return 'Use at least 8 characters.';
                              }
                              if (value.length > 72) {
                                return 'Password must be 72 characters or fewer.';
                              }
                              return null;
                            }
                          : AppValidators.password,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      InfoBanner(
                        message: _errorMessage!,
                        icon: Icons.error_outline_rounded,
                        tone: InfoBannerTone.warning,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    CustomButton(
                      text: _isRegistering ? 'Create Account' : 'Sign In',
                      isLoading: _isLoading,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                              _isRegistering = !_isRegistering;
                              _errorMessage = null;
                            }),
                      child: Text(
                        _isRegistering
                            ? 'Already have an account? Sign in'
                            : 'New to NaSCon? Create an account',
                      ),
                    ),
                    if (showDemoAccounts) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _DemoAccounts(
                        onSelected: _isLoading ? null : _useDemoAccount,
                      ),
                    ],
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

/// Development helper: fills the form with a documented demo account.
///
/// Only rendered when the mock backend is enabled, so it can never be mistaken
/// for a production sign-in path.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onSelected});

  final ValueChanged<DemoAccount>? onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: AppSizes.iconMd,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Demo accounts (mock backend)',
                  style: AppTextStyles.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final account in MockData.demoAccounts)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: onSelected == null ? null : () => onSelected!(account),
              title: Text(
                account.user.role.label,
                style: AppTextStyles.bodyMedium,
              ),
              subtitle: Text(
                account.email,
                style: AppTextStyles.helper.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.login_rounded, size: 18),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Shared demo password: ${MockData.demoAccounts.first.password}',
            style: AppTextStyles.helper.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
