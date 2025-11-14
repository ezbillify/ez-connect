import 'package:flutter/material.dart';
import 'package:app/shared/widgets/loading_spinner.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expand = true,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style ??
          ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      child: isLoading
          ? LoadingSpinner(
              size: 20,
              strokeWidth: 2.4,
              color: theme.colorScheme.onPrimary,
            )
          : Text(label),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}
