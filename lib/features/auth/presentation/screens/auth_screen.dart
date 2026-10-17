import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

/// The authentication screen.
///
/// Frontend only: a sliding tab switcher toggles **Login** / **Sign Up**, the
/// form lives in a single glassmorphic card, and both tabs animate in with a
/// cross-fade + slide. Submitting shows a 1-second loader before navigating to
/// the [DashboardScreen] — no auth backend is wired.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.onAuthenticated});

  /// Overrides the default navigation to the dashboard (used by hosts/tests).
  final VoidCallback? onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setMode(bool login) {
    if (_isLoading || _isLogin == login) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLogin = login);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(seconds: 1)); // simulated request
    if (!mounted) return;
    setState(() => _isLoading = false);
    _openDashboard();
  }

  void _openDashboard() {
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!.call();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: _header(scheme),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 80),
                        child: CustomCard(
                          radius: 24,
                          blur: 20,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.7),
                          borderColor: scheme.primary.withValues(alpha: 0.18),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AuthTabSwitcher(
                                  isLogin: _isLogin,
                                  onChanged: _setMode,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                AnimatedSize(
                                  duration: AppConstants.animationMedium,
                                  curve: Curves.easeInOut,
                                  alignment: Alignment.topCenter,
                                  child: AnimatedSwitcher(
                                    duration: AppConstants.animationMedium,
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.05, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Column(
                                      key: ValueKey(_isLogin),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: _fields(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                CustomButton(
                                  text: _isLogin ? 'Login' : 'Create Account',
                                  isLoading: _isLoading,
                                  trailingIcon: Icons.arrow_forward_rounded,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _divider(scheme),
                                const SizedBox(height: AppSpacing.lg),
                                _socialRow(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 160),
                        child: _footer(scheme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields() {
    final fields = <Widget>[];

    if (!_isLogin) {
      fields
        ..add(
          CustomTextField(
            controller: _nameController,
            label: 'Full name',
            hintText: 'Jane Doe',
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            validator: (value) => _isLogin ? null : AppValidators.name(value),
          ),
        )
        ..add(const SizedBox(height: AppSpacing.lg));
    }

    fields
      ..add(
        CustomTextField(
          controller: _emailController,
          label: 'Email address',
          hintText: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !_isLoading,
          validator: AppValidators.email,
        ),
      )
      ..add(const SizedBox(height: AppSpacing.lg))
      ..add(
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          textInputAction: _isLogin
              ? TextInputAction.done
              : TextInputAction.next,
          enabled: !_isLoading,
          validator: AppValidators.password,
        ),
      );

    if (_isLogin) {
      fields
        ..add(const SizedBox(height: AppSpacing.xs))
        ..add(
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => _notify('A password reset link has been sent.'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Forgot Password?'),
            ),
          ),
        );
    } else {
      fields
        ..add(const SizedBox(height: AppSpacing.lg))
        ..add(
          CustomTextField(
            controller: _confirmController,
            label: 'Confirm password',
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_reset_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            validator: (value) => _isLogin
                ? null
                : AppValidators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
          ),
        )
        ..add(const SizedBox(height: AppSpacing.md))
        ..add(_termsCheckbox());
    }

    return fields;
  }

  Widget _header(ColorScheme scheme) {
    return Column(
      children: [
        Text(
          _isLogin ? 'Welcome Back!' : 'Create Account',
          textAlign: TextAlign.center,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isLogin
              ? 'Sign in to continue to your dashboard.'
              : 'Join us and get started in less than a minute.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _termsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: _isLoading
              ? null
              : (value) => setState(() => _acceptedTerms = value ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppSpacing.xs),
        const Expanded(
          child: Text('I agree to the Terms & Conditions'),
        ),
      ],
    );
  }

  Widget _divider(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(child: Divider(color: scheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Or continue with',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: scheme.outline)),
      ],
    );
  }

  Widget _socialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          icon: Icons.g_mobiledata,
          tooltip: 'Continue with Google',
          onPressed: _isLoading ? null : () => _notify('Google sign-in soon.'),
        ),
        const SizedBox(width: AppSpacing.lg),
        _SocialButton(
          icon: Icons.apple,
          tooltip: 'Continue with Apple',
          onPressed: _isLoading ? null : () => _notify('Apple sign-in soon.'),
        ),
        const SizedBox(width: AppSpacing.lg),
        _SocialButton(
          icon: Icons.code_rounded,
          tooltip: 'Continue with GitHub',
          onPressed: _isLoading ? null : () => _notify('GitHub sign-in soon.'),
        ),
      ],
    );
  }

  Widget _footer(ColorScheme scheme) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account?" : 'Already have an account?',
          style: AppTextStyles.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => _setMode(!_isLogin),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(_isLogin ? 'Sign Up' : 'Login'),
        ),
      ],
    );
  }
}

/// The Login / Sign Up segmented switcher with a sliding indicator.
class _AuthTabSwitcher extends StatelessWidget {
  const _AuthTabSwitcher({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _tab(
                  context,
                  label: 'Login',
                  selected: isLogin,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _tab(
                  context,
                  label: 'Sign Up',
                  selected: !isLogin,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: selected ? Colors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A small outline card hosting a social provider icon.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 58,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline),
            ),
            child: Icon(icon, size: 26, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Decorative background glows behind the glass card.
class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        children: [
          Container(color: scheme.surface),
          Positioned(
            top: -120,
            left: -80,
            child: _Glow(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: _Glow(color: AppColors.secondary.withValues(alpha: 0.28)),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
