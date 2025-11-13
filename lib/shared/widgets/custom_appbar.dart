import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final TextStyle? titleStyle;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: titleStyle),
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const PageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    if (subtitle != null) ...[
                      const Gap(8),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null)
                Row(
                  children: actions!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
