import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// A clean, reusable header.
///
/// Implements [PreferredSizeWidget] so it can be dropped into
/// `Scaffold.appBar`. Transparent by default, with a back button, a title
/// (optionally two-line via [subtitle]) and right-aligned [actions].
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showBackButton = true,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.transparent = true,
    this.bottom,
    this.height = 64,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBackButton;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final bool transparent;
  final PreferredSizeWidget? bottom;
  final double height;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: height,
      backgroundColor: transparent ? Colors.transparent : null,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null),
      title: (title == null && subtitle == null)
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: AppTextStyles.h3),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
      actions: actions,
      bottom: bottom,
    );
  }
}
