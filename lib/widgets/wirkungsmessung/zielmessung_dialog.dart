import 'package:flutter/material.dart';
import '../../models/teilhabeziel.dart';
import '../../models/zielmessung.dart';
import 'gas_rating_widget.dart';

/// Dialog zur Erfassung einer neuen GAS-Messung zu einem Teilhabeziel.
class ZielmessungDialog extends StatefulWidget {
  final Teilhabeziel ziel;
  final String bewertetVon;

  const ZielmessungDialog({
    super.key,
    required this.ziel,
    required this.bewertetVon,
  });

  static Future<Zielmessung?> show(
    BuildContext context, {
    required Teilhabeziel ziel,
    required String bewertetVon,
  }) {
    return showDialog<Zielmessung>(
      context: context,
      builder: (_) => ZielmessungDialog(ziel: ziel, bewertetVon: bewertetVon),
    );
  }

  @override
  State<ZielmessungDialog> createState() => _ZielmessungDialogState();
}

class _ZielmessungDialogState extends State<ZielmessungDialog> {
  GasBewertung? _bewertung;
  MesszeitpunktTyp _typ = MesszeitpunktTyp.zwischenmessung;
  DateTime _messdatum = DateTime.now();
  final _kommentar = TextEditingController();

  @override
  void dispose() {
    _kommentar.dispose();
    super.dispose();
  }

  Future<void> _pickDatum() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _messdatum,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _messdatum = picked);
  }

  void _speichern() {
    if (_bewertung == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Bewertung waehlen')),
      );
      return;
    }
    final messung = Zielmessung.create(
      zielId: widget.ziel.id,
      clientId: widget.ziel.clientId,
      messdatum: _messdatum,
      typ: _typ,
      bewertung: _bewertung!,
      kommentar: _kommentar.text.trim().isEmpty ? null : _kommentar.text.trim(),
      bewertetVon: widget.bewertetVon,
    );
    Navigator.pop(context, messung);
  }

  String _typName(MesszeitpunktTyp t) {
    switch (t) {
      case MesszeitpunktTyp.baseline: return 'Erstmessung (Baseline)';
      case MesszeitpunktTyp.zwischenmessung: return 'Zwischenmessung';
      case MesszeitpunktTyp.endmessung: return 'Endmessung';
      case MesszeitpunktTyp.adhoc: return 'Spontane Bewertung';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Messung'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ziel-Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.ziel.titel,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (widget.ziel.beschreibung.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.ziel.beschreibung,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Messzeitpunkt-Typ
              DropdownButtonFormField<MesszeitpunktTyp>(
                initialValue: _typ,
                decoration: const InputDecoration(
                  labelText: 'Typ der Messung',
                  border: OutlineInputBorder(),
                ),
                items: MesszeitpunktTyp.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(_typName(t))))
                    .toList(),
                onChanged: (v) => v != null ? setState(() => _typ = v) : null,
              ),
              const SizedBox(height: 12),

              // Datum
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Messdatum'),
                subtitle: Text(
                  '${_messdatum.day.toString().padLeft(2, '0')}.${_messdatum.month.toString().padLeft(2, '0')}.${_messdatum.year}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _pickDatum,
              ),

              const Divider(),

              // GAS-Bewertung
              Text('Bewertung (GAS)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GasRatingWidget(
                value: _bewertung,
                onChanged: (v) => setState(() => _bewertung = v),
              ),
              const SizedBox(height: 16),

              // Kommentar
              TextField(
                controller: _kommentar,
                decoration: const InputDecoration(
                  labelText: 'Kommentar (optional)',
                  hintText: 'Beobachtungen, Kontext, Begruendung...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _speichern,
          icon: const Icon(Icons.save),
          label: const Text('Speichern'),
        ),
      ],
    );
  }
}
