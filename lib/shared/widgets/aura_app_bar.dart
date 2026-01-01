import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Custom Aura-branded AppBar
class AuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AuraAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? AuraTheme.textOnPrimary,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? AuraTheme.primaryPurple,
      foregroundColor: foregroundColor ?? AuraTheme.textOnPrimary,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Custom Aura-branded SliverAppBar for scrollable pages
class AuraSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final Widget? flexibleSpace;

  const AuraSliverAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 120.0,
    this.flexibleSpace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AuraTheme.textOnPrimary,
        ),
      ),
      centerTitle: true,
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      backgroundColor: AuraTheme.primaryPurple,
      foregroundColor: AuraTheme.textOnPrimary,
      leading: leading,
      actions: actions,
      flexibleSpace: flexibleSpace,
    );
  }
}
