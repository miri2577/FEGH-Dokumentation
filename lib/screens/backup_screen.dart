import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/backup_service.dart';
import '../services/audit_logger.dart';

/// Screen fuer Backup-Erstellung und Wiederherstellung.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isCreating = false;
  bool _isRestoring = false;
  String? _statusMessage;
  bool _statusError = false;

  Future<void> _createBackup() async {
    final passwordController = TextEditingController();
    final usePassword = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup verschluesseln?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Empfehlung: Backup mit Passwort verschluesseln. '
              'Ohne Passwort wird das Backup im Klartext gespeichert.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Backup-Passwort (optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Backup erstellen')),
        ],
      ),
    );

    if (usePassword != true) return;
    if (!mounted) return;

    setState(() {
      _isCreating = true;
      _statusMessage = null;
    });

    try {
      final app = Provider.of<AppProvider>(context, listen: false);
      final backupService = BackupService();
      final result = await backupService.createBackup(
        clients: app.clients,
        appointments: app.appointments,
        emailTargets: app.emailTargets,
        settings: app.settings,
        password: passwordController.text.isNotEmpty ? passwordController.text : null,
      );

      if (result.success) {
        await AuditLogger.instance.log(
          action: 'data.backup_created',
          userId: app.settings.userName,
          context: {'encrypted': passwordController.text.isNotEmpty},
        );
        setState(() {
          _statusMessage = 'Backup erfolgreich erstellt: ${result.filePath ?? "geteilt"}';
          _statusError = false;
        });
      } else {
        setState(() {
          _statusMessage = 'Fehler: ${result.error ?? "Unbekannter Fehler"}';
          _statusError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Fehler: $e';
        _statusError = true;
      });
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Backup wiederherstellen'),
        content: const Text(
          'WARNUNG: Bestehende Daten werden ueberschrieben!\n\n'
          'Es wird empfohlen, vorher ein aktuelles Backup zu erstellen.\n\n'
          'Fortfahren?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Fortfahren'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'enc', 'bak'],
    );

    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final file = result.files.first;
    String? password;

    // Falls Datei verschluesselt: Passwort abfragen
    final passwordController = TextEditingController();
    final passwordResult = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup-Passwort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Falls das Backup verschluesselt ist, geben Sie das Passwort ein:'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Passwort (leer lassen bei unverschluesselt)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Wiederherstellen')),
        ],
      ),
    );
    if (passwordResult != true) return;
    password = passwordController.text.isNotEmpty ? passwordController.text : null;
    if (!mounted) return;

    setState(() {
      _isRestoring = true;
      _statusMessage = null;
    });

    try {
      final backupService = BackupService();
      RestoreResult restoreResult;

      if (file.bytes != null) {
        restoreResult = await backupService.restoreBackupFromBytes(
          fileBytes: file.bytes!,
          fileName: file.name,
          password: password,
        );
      } else if (file.path != null) {
        restoreResult = await backupService.restoreBackup(
          filePath: file.path!,
          password: password,
        );
      } else {
        setState(() {
          _statusMessage = 'Datei konnte nicht gelesen werden';
          _statusError = true;
          _isRestoring = false;
        });
        return;
      }

      if (restoreResult.success) {
        final clientCount = restoreResult.clients?.length ?? 0;
        final appointmentCount = restoreResult.appointments?.length ?? 0;
        if (mounted) {
          final app = Provider.of<AppProvider>(context, listen: false);
          await AuditLogger.instance.log(
            action: 'data.backup_restored',
            userId: app.settings.userName,
            context: {'clientCount': clientCount, 'appointmentCount': appointmentCount},
          );
          await app.refreshData();
        }
        setState(() {
          _statusMessage = 'Wiederhergestellt: $clientCount Klienten, $appointmentCount Termine';
          _statusError = false;
        });
      } else {
        setState(() {
          _statusMessage = 'Fehler: ${restoreResult.error ?? "Unbekannter Fehler"}';
          _statusError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Fehler: $e';
        _statusError = true;
      });
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Wiederherstellung')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info-Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backups enthalten alle Klienten, Termine und Einstellungen. '
                      'Empfehlung: Mit Passwort verschluesseln und auf externer Festplatte ablegen (3-2-1 Regel).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Backup erstellen
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.backup, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Text('Backup erstellen',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstellt eine Backup-Datei mit allen Klienten, Terminen und Einstellungen. '
                      'Optional verschluesselt mit einem Passwort.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isCreating ? null : _createBackup,
                        icon: _isCreating
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(_isCreating ? 'Erstelle...' : 'Backup erstellen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Backup wiederherstellen
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restore, color: theme.colorScheme.secondary, size: 28),
                        const SizedBox(width: 12),
                        Text('Backup wiederherstellen',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'WARNUNG: Bestehende Daten werden ueberschrieben! '
                      'Erstellen Sie vorher ein Backup der aktuellen Daten.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRestoring ? null : _restoreBackup,
                        icon: _isRestoring
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_file),
                        label: Text(_isRestoring ? 'Stelle wieder her...' : 'Backup waehlen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_statusError ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusError ? Colors.red : Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusError ? Icons.error : Icons.check_circle,
                      color: _statusError ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_statusMessage!,
                          style: TextStyle(color: _statusError ? Colors.red : Colors.green)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 3-2-1 Backup-Regel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3-2-1 Backup-Regel',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _ruleItem(theme, '3', 'Drei Kopien der Daten'),
                    _ruleItem(theme, '2', 'Zwei verschiedene Speichermedien'),
                    _ruleItem(theme, '1', 'Eine Kopie an einem anderen Ort (offsite)'),
                    const SizedBox(height: 8),
                    Text(
                      'Empfehlung: Lokales Geraet + externe Festplatte + Cloud-Sync (HiDrive/Nextcloud).',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleItem(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(number, style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
