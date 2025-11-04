import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  List<drive.File> _cloudBackups = [];
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);
    try {
      _isSignedIn = BackupService.instance.isSignedIn;
      if (_isSignedIn) {
        await _loadCloudBackups();
      }
    } catch (e) {
      _showError('Error checking sign-in status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCloudBackups() async {
    try {
      _cloudBackups = await BackupService.instance.listGoogleDriveBackups();
    } catch (e) {
      _showError('Error loading cloud backups: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final success = await BackupService.instance.signInWithGoogle();
      if (success) {
        setState(() => _isSignedIn = true);
        await _loadCloudBackups();
        _showSuccess('Successfully signed in to Google Drive');
      } else {
        _showError('Failed to sign in to Google Drive');
      }
    } catch (e) {
      _showError('Error signing in: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await BackupService.instance.signOut();
      setState(() {
        _isSignedIn = false;
        _cloudBackups.clear();
      });
      _showSuccess('Signed out from Google Drive');
    } catch (e) {
      _showError('Error signing out: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAndUploadBackup() async {
    setState(() => _isLoading = true);
    try {
      // Create local backup
      final localPath = await BackupService.instance.createLocalBackup();

      // Upload to Google Drive
      final success = await BackupService.instance.uploadToGoogleDrive(localPath);

      if (success) {
        await _loadCloudBackups(); // Refresh the list
        _showSuccess('Backup uploaded to Google Drive successfully');
      } else {
        _showError('Failed to upload backup to Google Drive');
      }
    } catch (e) {
      _showError('Error creating/uploading backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFromCloud(drive.File backupFile) async {
    setState(() => _isLoading = true);
    try {
      final localPath = await BackupService.instance.downloadFromGoogleDrive(backupFile.id!);
      if (localPath != null) {
        final success = await BackupService.instance.restoreFromBackup(localPath);
        if (success) {
          _showSuccess('Data restored successfully from ${backupFile.name}');
        } else {
          _showError('Failed to restore data');
        }
      } else {
        _showError('Failed to download backup file');
      }
    } catch (e) {
      _showError('Error restoring from cloud: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      final path = await BackupService.instance.createLocalBackup();
      _showSuccess('Local backup created: ${path.split('/').last}');
    } catch (e) {
      _showError('Error creating local backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoogleDriveSection(),
                  const SizedBox(height: 24),
                  _buildLocalBackupSection(),
                  if (_isSignedIn && _cloudBackups.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildCloudBackupsSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildGoogleDriveSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Google Drive Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isSignedIn) ...[
              Text('Signed in as: ${BackupService.instance.userEmail}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _createAndUploadBackup,
                      icon: const Icon(Icons.backup),
                      label: const Text('Backup to Cloud'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _signOut,
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ] else ...[
              const Text('Sign in to Google Drive to enable cloud backup'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocalBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Local Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Create a backup file stored on your device'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createLocalBackup,
                icon: const Icon(Icons.save),
                label: const Text('Create Local Backup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudBackupsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cloud Backups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._cloudBackups.map((backup) => ListTile(
              leading: const Icon(Icons.cloud_download),
              title: Text(backup.name ?? 'Unknown'),
              subtitle: Text('Created: ${_formatDate(backup.createdTime)}'),
              trailing: IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () => _restoreFromCloud(backup),
                tooltip: 'Restore from this backup',
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}