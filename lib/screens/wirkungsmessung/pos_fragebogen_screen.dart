import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/pos_messung.dart';
import '../../services/wirkungsmessung_service.dart';

/// Personal Outcomes Scale (POS) - Fragebogen mit 48 Items in 8 Domaenen.
/// Unterstuetzt neue Messung und Bearbeiten vorhandener Messung.
class PosFragebogenScreen extends StatefulWidget {
  final Client client;
  final String bewertetVon;
  final PosMessung? existing;

  const PosFragebogenScreen({
    super.key,
    required this.client,
    required this.bewertetVon,
    this.existing,
  });

  @override
  State<PosFragebogenScreen> createState() => _PosFragebogenScreenState();
}

class _PosFragebogenScreenState extends State<PosFragebogenScreen> {
  final _service = WirkungsmessungService();
  late Map<String, List<int>> _bewertungen;
  late DateTime _messdatum;
  final _kommentar = TextEditingController();
  int _aktuelleDomaene = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _bewertungen = {
        for (final e in widget.existing!.bewertungen.entries)
          e.key: List<int>.from(e.value),
      };
      _messdatum = widget.existing!.messdatum;
      _kommentar.text = widget.existing!.kommentar ?? '';
    } else {
      _bewertungen = PosMessung.leereBewertungen();
      _messdatum = DateTime.now();
    }
  }

  @override
  void dispose() {
    _kommentar.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  int _gesamtPunkte() {
    return _bewertungen.values
        .fold<int>(0, (sum, items) => sum + items.fold<int>(0, (s, v) => s + v));
  }

  int _domaenePunkte(PosDomaene d) {
    return (_bewertungen[d.name] ?? []).fold<int>(0, (s, v) => s + v);
  }

  int _beantworteteItems() {
    return _bewertungen.values.fold<int>(
      0,
      (sum, items) => sum + items.where((v) => v > 0).length,
    );
  }

  Future<void> _pickDatum() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _messdatum,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _messdatum = picked);
  }

  Future<void> _speichern() async {
    final beantwortet = _beantworteteItems();
    if (beantwortet < 48) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unvollstaendig'),
          content: Text(
            'Es sind nur $beantwortet von 48 Items beantwortet. '
            'Trotzdem speichern?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zurueck'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Trotzdem speichern'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        messdatum: _messdatum,
        bewertungen: _bewertungen,
        kommentar: _kommentar.text.trim().isEmpty ? null : _kommentar.text.trim(),
      );
      await _service.updatePosMessung(updated);
    } else {
      final neu = PosMessung.create(
        clientId: widget.client.id,
        messdatum: _messdatum,
        bewertetVon: widget.bewertetVon,
        bewertungen: _bewertungen,
        kommentar: _kommentar.text.trim().isEmpty ? null : _kommentar.text.trim(),
      );
      await _service.addPosMessung(neu);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Color _bewertungFarbe(int wert) {
    switch (wert) {
      case 1: return const Color(0xFFEF6C00);
      case 2: return const Color(0xFFFFB300);
      case 3: return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  String _bewertungLabel(int wert) {
    switch (wert) {
      case 1: return 'Trifft nicht zu';
      case 2: return 'Trifft teilweise zu';
      case 3: return 'Trifft voll zu';
      default: return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domaenen = PosDomaene.values;
    final currentDom = domaenen[_aktuelleDomaene];
    final items = currentDom.items;
    final werte = _bewertungen[currentDom.name] ?? List.filled(6, 0);
    final domPunkte = _domaenePunkte(currentDom);
    final gesamtPunkte = _gesamtPunkte();
    final gesamtProzent = (gesamtPunkte / 144.0 * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Outcomes Scale'),
        actions: [
          TextButton.icon(
            onPressed: _speichern,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Speichern'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress + Score
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.client.vollstaendigerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDatum,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        '${_messdatum.day.toString().padLeft(2, '0')}.${_messdatum.month.toString().padLeft(2, '0')}.${_messdatum.year}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Domaene ${_aktuelleDomaene + 1}/8',
                              style: theme.textTheme.bodySmall),
                          LinearProgressIndicator(
                            value: (_aktuelleDomaene + 1) / 8,
                            minHeight: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Gesamt', style: theme.textTheme.bodySmall),
                        Text('$gesamtPunkte / 144  ($gesamtProzent%)',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Domaene Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentDom.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Text('$domPunkte / 18 Punkte',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),

          // Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length + 1, // + Kommentarfeld auf letzter Domaene
              itemBuilder: (_, i) {
                if (i < items.length) {
                  return _buildItemCard(i, items[i], werte[i], currentDom);
                }
                // Kommentar-Feld nur auf letzter Domaene
                if (_aktuelleDomaene == domaenen.length - 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _kommentar,
                      decoration: const InputDecoration(
                        labelText: 'Gesamtkommentar (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Navigation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _aktuelleDomaene > 0
                      ? () => setState(() => _aktuelleDomaene--)
                      : null,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Zurueck'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_beantworteteItems()}/48 Items',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                if (_aktuelleDomaene < domaenen.length - 1)
                  FilledButton.icon(
                    onPressed: () => setState(() => _aktuelleDomaene++),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Weiter'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _speichern,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Speichern'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, String frage, int wert, PosDomaene domaene) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${index + 1}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(frage,
                      style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [1, 2, 3].map((punkt) {
                final selected = wert == punkt;
                final farbe = _bewertungFarbe(punkt);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          final list = List<int>.from(_bewertungen[domaene.name] ?? List.filled(6, 0));
                          list[index] = punkt;
                          _bewertungen[domaene.name] = list;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? farbe.withValues(alpha: 0.2) : Colors.transparent,
                          border: Border.all(
                            color: selected ? farbe : Colors.grey.withValues(alpha: 0.3),
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('$punkt',
                                style: TextStyle(
                                  color: farbe,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                )),
                            const SizedBox(height: 2),
                            Text(_bewertungLabel(punkt),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: farbe,
                                  fontSize: 10,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
