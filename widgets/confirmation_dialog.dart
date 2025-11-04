import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: icon != null ? Icon(icon, size: 48) : null,
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: confirmColor != null
              ? TextButton.styleFrom(foregroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

class DeleteConfirmationDialog extends StatelessWidget {
  final String itemType;
  final String itemName;
  final String? additionalInfo;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemType,
    required this.itemName,
    this.additionalInfo,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String itemType,
    required String itemName,
    String? additionalInfo,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        itemType: itemType,
        itemName: itemName,
        additionalInfo: additionalInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Delete $itemType',
      content: 'Are you sure you want to delete "$itemName"?${additionalInfo != null ? '\n\n$additionalInfo' : ''}\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.delete_forever,
    );
  }
}

class DependencyWarningDialog extends StatelessWidget {
  final String itemType;
  final String itemName;
  final List<String> dependencies;

  const DependencyWarningDialog({
    super.key,
    required this.itemType,
    required this.itemName,
    required this.dependencies,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String itemType,
    required String itemName,
    required List<String> dependencies,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DependencyWarningDialog(
        itemType: itemType,
        itemName: itemName,
        dependencies: dependencies,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dependencyText = dependencies.join(', ');

    return ConfirmationDialog(
      title: 'Cannot Delete $itemType',
      content: '"$itemName" cannot be deleted because it has the following dependencies:\n\n$dependencyText\n\nPlease archive or reassign these items first.',
      confirmText: 'OK',
      cancelText: '', // Hide cancel button
      icon: Icons.warning,
    );
  }
}