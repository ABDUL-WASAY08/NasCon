import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'auth_screen.dart';

/// The branded splash.
///
/// Pure UI. A native [AnimationController] drives the logo's scale-in +
/// fade-in; a second repeating controller gives the logo's glow ring a subtle
/// pulse and animates the loading wave. After [holdDuration] the screen hands
/// off to [AuthScreen] with [Navigator.pushReplacement] — no backend work.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.holdDuration = AppConstants.splashDuration,
  });

  final Duration holdDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;

  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _ring;

  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );
    _ring = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);

    _intro.forward();
    _timer = Timer(widget.holdDuration, _goToAuth);
  }

  void _goToAuth() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppConstants.animationSlow,
        pageBuilder: (_, _, _) => const AuthScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.darkBackground,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.darkBackground,
                AppColors.primaryDark,
                AppColors.primary,
              ],
            ),
          ),
          child: SizedBox.expand(
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _fade,
                          child: ScaleTransition(
                            scale: _scale,
                            child: _LogoMark(pulse: _ring),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _GradientTitle(text: AppConstants.appName),
                        const SizedBox(height: 10),
                        Text(
                          AppConstants.appTagline,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 56),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => _LoadingWave(progress: _pulse.value),
                      ),
                    ),
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

/// The glowing, rounded logo container with a pulsing ring.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        return Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.secondaryLight.withValues(alpha: 0.25 + 0.35 * t),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45 + 0.25 * t),
                blurRadius: 34 + 18 * t,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.20 * t),
                blurRadius: 60,
                spreadRadius: -10,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/logo.svg',
          width: 64,
          height: 64,
          semanticsLabel: '${AppConstants.appName} logo',
        ),
      ),
    );
  }
}

/// The app name in stylized gradient type.
class _GradientTitle extends StatelessWidget {
  const _GradientTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, AppColors.secondaryLight],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: AppTextStyles.h1.copyWith(
          color: Colors.white,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

/// A subtle three-dot loading wave.
class _LoadingWave extends StatelessWidget {
  const _LoadingWave({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              final bounce =
                  (math.sin((progress - i * 0.15) * 2 * math.pi) + 1) / 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Opacity(
                  opacity: 0.4 + 0.6 * bounce,
                  child: Transform.translate(
                    offset: Offset(0, -6 * bounce),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
