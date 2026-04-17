import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/pos_messung.dart';
import '../../services/wirkungsmessung_service.dart';
import 'pos_fragebogen_screen.dart';

/// Uebersicht aller POS-Messungen eines Klienten.
class PosUebersichtScreen extends StatefulWidget {
  final Client client;
  final String bewertetVon;

  const PosUebersichtScreen({
    super.key,
    required this.client,
    required this.bewertetVon,
  });

  @override
  State<PosUebersichtScreen> createState() => _PosUebersichtScreenState();
}

class _PosUebersichtScreenState extends State<PosUebersichtScreen> {
  final _service = WirkungsmessungService();
  List<PosMessung> _messungen = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final msgs = await _service.posMessungenFuerClient(widget.client.id);
    msgs.sort((a, b) => b.messdatum.compareTo(a.messdatum));
    if (!mounted) return;
    setState(() {
      _messungen = msgs;
      _loading = false;
    });
  }

  Future<void> _neueMessung() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PosFragebogenScreen(
          client: widget.client,
          bewertetVon: widget.bewertetVon,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _bearbeiten(PosMessung m) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PosFragebogenScreen(
          client: widget.client,
          bewertetVon: widget.bewertetVon,
          existing: m,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _loeschen(PosMessung m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Messung loeschen?'),
        content: const Text('Diese POS-Messung wird unwiderruflich geloescht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deletePosMessung(m.id);
      await _load();
    }
  }

  Color _farbeFuerProzent(double p) {
    if (p >= 75) return const Color(0xFF2E7D32);
    if (p >= 50) return const Color(0xFF7CB342);
    if (p >= 33) return const Color(0xFFFFB300);
    return const Color(0xFFEF6C00);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lebensqualitaet (POS)'),
            Text(widget.client.vollstaendigerName, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messungen.isEmpty
              ? _buildEmpty(theme)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messungen.length,
                    itemBuilder: (_, i) => _buildCard(_messungen[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _neueMessung,
        icon: const Icon(Icons.add),
        label: const Text('Neue POS-Messung'),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Noch keine POS-Messung', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Die Personal Outcomes Scale misst Lebensqualitaet in 8 Domaenen.\n'
              '48 Fragen, ca. 15-20 Minuten.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _neueMessung,
              icon: const Icon(Icons.add),
              label: const Text('Erste Messung starten'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PosMessung m) {
    final theme = Theme.of(context);
    final prozent = m.gesamtProzent;
    final farbe = _farbeFuerProzent(prozent);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _bearbeiten(m),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: farbe.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: farbe, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${prozent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: farbe,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Messung vom ${m.messdatum.day.toString().padLeft(2, '0')}.${m.messdatum.month.toString().padLeft(2, '0')}.${m.messdatum.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${m.gesamtPunkte} / 144 Punkte',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      if (v == 'edit') _bearbeiten(m);
                      if (v == 'delete') _loeschen(m);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Loeschen', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Mini-Balken fuer 8 Domaenen
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: PosDomaene.values.map((d) {
                  final dp = m.domaeneProzent(d);
                  final dc = _farbeFuerProzent(dp);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: dc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${d.displayName}: ${dp.toStringAsFixed(0)}%',
                      style: TextStyle(color: dc, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
              if (m.kommentar != null && m.kommentar!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('"${m.kommentar!}"',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
