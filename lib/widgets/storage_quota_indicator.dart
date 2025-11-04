import 'package:flutter/material.dart';
import '../services/file_service.dart';

class StorageQuotaIndicator extends StatefulWidget {
  const StorageQuotaIndicator({super.key});

  @override
  State<StorageQuotaIndicator> createState() => _StorageQuotaIndicatorState();
}

class _StorageQuotaIndicatorState extends State<StorageQuotaIndicator> {
  double _usagePercentage = 0.0;
  int _usedBytes = 0;
  int _totalBytes = FileService.maxStorageQuotaBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageUsage();
  }

  Future<void> _loadStorageUsage() async {
    try {
      final usage = await FileService.getStorageUsage();
      setState(() {
        _usedBytes = usage;
        _usagePercentage = usage / _totalBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading storage usage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 20,
        child: LinearProgressIndicator(),
      );
    }

    final color = _getColorForUsage(_usagePercentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Storage Used: ${(_usedBytes / 1024 / 1024).toStringAsFixed(1)}MB / ${(_totalBytes / 1024 / 1024).toStringAsFixed(0)}MB',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_usagePercentage > 0.8) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.warning,
                size: 16,
                color: color,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _usagePercentage.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        if (_usagePercentage > 0.9) ...[
          const SizedBox(height: 4),
          Text(
            'Storage quota almost full. Consider deleting old files or upgrading.',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Color _getColorForUsage(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.7) return Colors.yellow[700]!;
    return Colors.green;
  }
}

class StorageWarningDialog extends StatelessWidget {
  final int requiredBytes;
  final int availableBytes;

  const StorageWarningDialog({
    super.key,
    required: this.requiredBytes,
    required: this.availableBytes,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int requiredBytes,
    required int availableBytes,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => StorageWarningDialog(
        requiredBytes: requiredBytes,
        availableBytes: availableBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requiredMB = requiredBytes / 1024 / 1024;
    final availableMB = availableBytes / 1024 / 1024;

    return AlertDialog(
      title: const Text('Storage Warning'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This operation requires ${requiredMB.toStringAsFixed(1)}MB of storage space.',
          ),
          const SizedBox(height: 8),
          Text(
            'Available space: ${availableMB.toStringAsFixed(1)}MB',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'You may need to free up space by deleting old files or clearing cache.',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}