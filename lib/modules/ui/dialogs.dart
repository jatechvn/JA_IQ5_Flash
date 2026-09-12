// lib/modules/ui/dialogs.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../i18n.dart';
import 'styles.dart';

/// Show a beautiful glassmorphic alert dialog.
Future<void> showAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  required AppTheme theme,
  String? okText,
}) async {
  final effectiveOk = okText ?? tr('confirm');
  await showDialog(
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: AlertDialog(
        backgroundColor: theme.surfaceBg.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderTheme),
        ),
        title: Text(title, style: theme.themeData.textTheme.titleLarge),
        content: Text(content, style: theme.themeData.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              effectiveOk,
              style: TextStyle(
                color: theme.gradStart,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Show a confirmation dialog with OK and Cancel options.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  required AppTheme theme,
  String? okText,
  String? cancelText,
}) async {
  final effectiveOk = okText ?? tr('confirm');
  final effectiveCancel = cancelText ?? tr('cancel');
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: AlertDialog(
        backgroundColor: theme.surfaceBg.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderTheme),
        ),
        title: Text(title, style: theme.themeData.textTheme.titleLarge),
        content: Text(content, style: theme.themeData.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              effectiveCancel,
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.gradEnd,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(effectiveOk, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
