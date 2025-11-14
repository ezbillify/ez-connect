import 'package:flutter/material.dart';

enum ToastType { info, success, error }

class CustomToast {
  const CustomToast._();

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    final theme = Theme.of(context);

    Color backgroundColor;
    Color foregroundColor;

    switch (type) {
      case ToastType.success:
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = theme.colorScheme.onPrimary;
        break;
      case ToastType.error:
        backgroundColor = theme.colorScheme.error;
        foregroundColor = theme.colorScheme.onError;
        break;
      case ToastType.info:
      default:
        backgroundColor = theme.colorScheme.secondaryContainer;
        foregroundColor = theme.colorScheme.onSecondaryContainer;
        break;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            trimmedMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
