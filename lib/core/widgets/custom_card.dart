import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// The base surface used across the app.
///
/// Rounded (16–24px), softly shadowed, theme-aware (light/dark) and optionally
/// **glassmorphic** — pass [blur] to frost whatever sits behind it. Supports a
/// flat [color] or a [gradient] fill and an optional tap target.
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.radius = 20,
    this.color,
    this.gradient,
    this.borderColor,
    this.onTap,
    this.elevated = true,
    this.blur,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? color;
  final List<Color>? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool elevated;

  /// Backdrop blur sigma. When set, the card becomes a frosted glass surface.
  final double? blur;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    final fill = color ?? theme.cardColor;
    final border =
        borderColor ?? scheme.outline.withValues(alpha: isDark ? 0.6 : 0.9);
    final shadows = elevated
        ? [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ]
        : const <BoxShadow>[];

    Widget surface = Container(
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient == null
            ? null
            : LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: borderRadius,
        border: Border.all(color: border),
        boxShadow: blur == null ? shadows : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (blur != null) {
      surface = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
          child: surface,
        ),
      );
    }

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: surface,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      // The shadow lives on this outer layer so it survives the blur clip.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: blur != null ? shadows : null,
      ),
      clipBehavior: onTap != null ? Clip.antiAlias : Clip.none,
      child: surface,
    );
  }
}
