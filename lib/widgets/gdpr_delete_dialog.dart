import 'package:flutter/material.dart';
import '../services/audit_logger.dart';

/// DSGVO-konforme Loeschung eines einzelnen Klienten (Art. 17).
/// Zeigt Bestaetigungsdialog mit Sicherheitscode.
class GdprDeleteDialog extends StatefulWidget {
  final String clientId;
  final String clientName;
  final Future<bool> Function() onDelete;
  final String currentUser;

  const GdprDeleteDialog({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.onDelete,
    required this.currentUser,
  });

  /// Zeigt den Dialog und gibt true zurueck wenn geloescht wurde.
  static Future<bool> show({
    required BuildContext context,
    required String clientId,
    required String clientName,
    required Future<bool> Function() onDelete,
    required String currentUser,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GdprDeleteDialog(
        clientId: clientId,
        clientName: clientName,
        onDelete: onDelete,
        currentUser: currentUser,
      ),
    );
    return result ?? false;
  }

  @override
  State<GdprDeleteDialog> createState() => _GdprDeleteDialogState();
}

class _GdprDeleteDialogState extends State<GdprDeleteDialog> {
  final _codeController = TextEditingController();
  late final String _confirmCode;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 4-stelliger Bestaetigungscode
    _confirmCode = widget.clientId.hashCode.abs().toString().substring(0, 4);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _performDelete() async {
    if (_codeController.text.trim() != _confirmCode) {
      setState(() => _error = 'Falscher Bestaetigungscode');
      return;
    }

    setState(() { _isDeleting = true; _error = null; });

    final success = await widget.onDelete();

    if (success) {
      await AuditLogger.instance.logClientDelete(
        widget.currentUser,
        widget.clientId,
      );
      await AuditLogger.instance.log(
        action: 'gdpr.art17_delete',
        userId: widget.currentUser,
        context: {
          'clientId': widget.clientId,
          'clientName': widget.clientName,
          'reason': 'Art. 17 DSGVO - Recht auf Loeschung',
        },
      );
    }

    if (mounted) {
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(Icons.delete_forever, size: 48, color: theme.colorScheme.error),
      title: const Text('Klient endgueltig loeschen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACHTUNG: Diese Aktion ist unwiderruflich!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Folgende Daten werden geloescht:\n'
                    '- Klienten-Stammdaten\n'
                    '- Alle Termine und Dokumentationen\n'
                    '- Alle Berichte und Exporte\n'
                    '- Cloud-Kopien auf HiDrive\n\n'
                    'Die Dateien werden mit Zufallsdaten ueberschrieben (Crypto-Erasure).',
                    style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Klient: ${widget.clientName}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('ID: ${widget.clientId}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text('Geben Sie zur Bestaetigung folgenden Code ein:',
              style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Center(
              child: Text(_confirmCode,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: theme.colorScheme.error,
                )),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Bestaetigungscode',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 8),
            Text('Rechtsgrundlage: Art. 17 DSGVO (Recht auf Loeschung)',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _performDelete,
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
          child: _isDeleting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Endgueltig loeschen'),
        ),
      ],
    );
  }
}
