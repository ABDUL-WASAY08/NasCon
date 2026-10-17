import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The app's primary action button.
///
/// One widget for every button: filled **gradient** (default) or [isOutlined],
/// optional leading [icon], a full-width or wrap-content layout, an embedded
/// loader while [isLoading], and a touch scale-down + ripple on press.
class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.trailingIcon,
    this.gradient,
    this.fullWidth = true,
    this.height = 54,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Overrides the default primary gradient. Ignored when [isOutlined].
  final List<Color>? gradient;

  final bool fullWidth;
  final double height;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    final colors = widget.gradient ?? AppColors.primaryGradient;

    final baseForeground = widget.isOutlined ? scheme.onSurface : Colors.white;
    final foreground = _disabled
        ? baseForeground.withValues(alpha: 0.5)
        : baseForeground;

    final gradientColors = _disabled
        ? colors.map((c) => c.withValues(alpha: 0.45)).toList()
        : colors;

    final Widget content = widget.isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(baseForeground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19, color: foreground),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(color: foreground),
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 10),
                Icon(widget.trailingIcon, size: 19, color: foreground),
              ],
            ],
          );

    return AnimatedScale(
      scale: _pressed && !_disabled ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: SizedBox(
        height: widget.height,
        width: widget.fullWidth ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.isOutlined
                ? null
                : LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: radius,
            border: widget.isOutlined
                ? Border.all(color: scheme.outline)
                : null,
            boxShadow: !_disabled && !widget.isOutlined
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _disabled ? null : widget.onPressed,
              borderRadius: radius,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: widget.fullWidth ? Center(child: content) : content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
