import 'package:flutter/material.dart';
import '../models/client.dart';

/// Dialog zur Erfassung der DSGVO-Einwilligung eines Klienten (Art. 9 DSGVO).
/// Sozial- und Gesundheitsdaten erfordern explizite Einwilligung.
class ClientConsentDialog extends StatefulWidget {
  final Client client;

  const ClientConsentDialog({super.key, required this.client});

  /// Zeigt den Dialog und gibt die aktualisierte Einwilligung zurueck.
  static Future<Client?> show(BuildContext context, Client client) {
    return showDialog<Client>(
      context: context,
      builder: (ctx) => ClientConsentDialog(client: client),
    );
  }

  @override
  State<ClientConsentDialog> createState() => _ClientConsentDialogState();
}

class _ClientConsentDialogState extends State<ClientConsentDialog> {
  late bool _consented;
  late TextEditingController _signatureController;
  late TextEditingController _bemerkungController;
  late TextEditingController _widerrufBisController;
  DateTime? _consentDate;

  @override
  void initState() {
    super.initState();
    _consented = widget.client.einwilligungVorhanden;
    _signatureController = TextEditingController(text: widget.client.einwilligungUnterschriftVon ?? '');
    _bemerkungController = TextEditingController(text: widget.client.einwilligungBemerkung ?? '');
    _widerrufBisController = TextEditingController(text: widget.client.einwilligungWiderruflichBis ?? '');
    _consentDate = widget.client.einwilligungDatum;
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _bemerkungController.dispose();
    _widerrufBisController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _consentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _consentDate = picked);
    }
  }

  void _save() {
    final updated = widget.client.copyWith(
      einwilligungVorhanden: _consented,
      einwilligungDatum: _consented ? (_consentDate ?? DateTime.now()) : null,
      einwilligungUnterschriftVon: _consented ? _signatureController.text.trim() : null,
      einwilligungBemerkung: _bemerkungController.text.trim().isNotEmpty ? _bemerkungController.text.trim() : null,
      einwilligungWiderruflichBis: _widerrufBisController.text.trim().isNotEmpty ? _widerrufBisController.text.trim() : null,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(Icons.privacy_tip,
          size: 48,
          color: _consented ? Colors.green : Colors.orange),
      title: const Text('DSGVO-Einwilligung'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Art. 9 Abs. 2a DSGVO',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Sozial- und Gesundheitsdaten von ${widget.client.vollstaendigerName} '
                    'duerfen nur mit ausdruecklicher Einwilligung verarbeitet werden.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Einwilligung liegt vor'),
              subtitle: Text(_consented
                  ? 'Schriftliche Einwilligung dokumentiert'
                  : 'Keine Einwilligung'),
              value: _consented,
              onChanged: (v) => setState(() => _consented = v),
            ),
            if (_consented) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Datum der Einwilligung'),
                subtitle: Text(_consentDate != null
                    ? '${_consentDate!.day.toString().padLeft(2, '0')}.${_consentDate!.month.toString().padLeft(2, '0')}.${_consentDate!.year}'
                    : 'Nicht gesetzt'),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Aendern'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _signatureController,
                decoration: const InputDecoration(
                  labelText: 'Unterschrieben von *',
                  hintText: 'Klient oder gesetzlicher Vertreter',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _widerrufBisController,
                decoration: const InputDecoration(
                  labelText: 'Widerruflich bis (optional)',
                  hintText: 'z.B. unbefristet, 31.12.2030',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bemerkungController,
                decoration: const InputDecoration(
                  labelText: 'Bemerkung (optional)',
                  hintText: 'Besondere Hinweise',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hinweis: Die schriftliche Einwilligung muss separat aufbewahrt werden. '
                'Diese App speichert nur die Information dass eine Einwilligung vorliegt.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
