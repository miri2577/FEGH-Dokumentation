import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/teilhabeziel.dart';
import '../../models/zielmessung.dart';
import '../../services/wirkungsmessung_service.dart';
import '../../widgets/wirkungsmessung/gas_rating_widget.dart';
import '../../widgets/wirkungsmessung/zielmessung_dialog.dart';
import 'ziel_editor_screen.dart';

/// Uebersicht aller Teilhabeziele eines Klienten mit GAS-Status.
class ZielListeScreen extends StatefulWidget {
  final Client client;
  final String bewertetVon;

  const ZielListeScreen({
    super.key,
    required this.client,
    required this.bewertetVon,
  });

  @override
  State<ZielListeScreen> createState() => _ZielListeScreenState();
}

class _ZielListeScreenState extends State<ZielListeScreen> {
  final _service = WirkungsmessungService();
  List<Teilhabeziel> _ziele = [];
  Map<String, List<Zielmessung>> _messungen = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ziele = await _service.zieleFuerClient(widget.client.id);
    ziele.sort((a, b) {
      if (a.status != b.status) {
        if (a.status == TeilhabezielStatus.aktiv) return -1;
        if (b.status == TeilhabezielStatus.aktiv) return 1;
      }
      return b.prioritaet.compareTo(a.prioritaet);
    });
    final messungenMap = <String, List<Zielmessung>>{};
    for (final z in ziele) {
      messungenMap[z.id] = await _service.messungenFuerZiel(z.id);
    }
    if (!mounted) return;
    setState(() {
      _ziele = ziele;
      _messungen = messungenMap;
      _loading = false;
    });
  }

  Future<void> _neuesZiel() async {
    final result = await Navigator.push<Teilhabeziel>(
      context,
      MaterialPageRoute(builder: (_) => ZielEditorScreen(client: widget.client)),
    );
    if (result != null) {
      await _service.addZiel(result);
      await _load();
    }
  }

  Future<void> _bearbeiten(Teilhabeziel ziel) async {
    final result = await Navigator.push<Teilhabeziel>(
      context,
      MaterialPageRoute(
        builder: (_) => ZielEditorScreen(client: widget.client, ziel: ziel),
      ),
    );
    if (result != null) {
      await _service.updateZiel(result);
      await _load();
    }
  }

  Future<void> _neueMessung(Teilhabeziel ziel) async {
    final messung = await ZielmessungDialog.show(
      context,
      ziel: ziel,
      bewertetVon: widget.bewertetVon,
    );
    if (messung != null) {
      await _service.addMessung(messung);
      await _load();
    }
  }

  Future<void> _loeschen(Teilhabeziel ziel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ziel loeschen?'),
        content: Text(
          'Das Ziel "${ziel.titel}" und alle Messungen werden unwiderruflich geloescht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteZiel(ziel.id);
      await _load();
    }
  }

  Color _statusColor(TeilhabezielStatus s) {
    switch (s) {
      case TeilhabezielStatus.aktiv: return Colors.blue;
      case TeilhabezielStatus.erreicht: return Colors.green;
      case TeilhabezielStatus.pausiert: return Colors.orange;
      case TeilhabezielStatus.abgebrochen: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Teilhabeziele'),
            Text(
              widget.client.vollstaendigerName,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ziele.isEmpty
              ? _buildEmpty(theme)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _ziele.length,
                    itemBuilder: (_, i) => _buildZielCard(_ziele[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _neuesZiel,
        icon: const Icon(Icons.add),
        label: const Text('Neues Ziel'),
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
            Icon(Icons.flag_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Noch keine Teilhabeziele',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Legen Sie Ziele nach SMART-Kriterien an, um Wirkung zu messen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _neuesZiel,
              icon: const Icon(Icons.add),
              label: const Text('Erstes Ziel anlegen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZielCard(Teilhabeziel ziel) {
    final theme = Theme.of(context);
    final msgs = _messungen[ziel.id] ?? [];
    final letzteMessung = msgs.isEmpty ? null : msgs.last;
    final statusColor = _statusColor(ziel.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _bearbeiten(ziel),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kopfzeile: Titel + Status + Menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ziel.titel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ziel.statusDisplayName,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      switch (v) {
                        case 'edit': _bearbeiten(ziel); break;
                        case 'delete': _loeschen(ziel); break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Bearbeiten'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Loeschen', style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),

              // Meta: Kategorie, Prio, ICF
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _chip(theme, ziel.kategorieDisplayName, Icons.category),
                  _chip(theme, 'Prio ${ziel.prioritaet}/5', Icons.flag),
                  if (ziel.icfBereich != null)
                    _chip(theme, ziel.icfBereich!, Icons.link),
                  if (ziel.terminiert != null)
                    _chip(
                      theme,
                      'bis ${ziel.terminiert!.day.toString().padLeft(2, '0')}.${ziel.terminiert!.month.toString().padLeft(2, '0')}.${ziel.terminiert!.year}',
                      Icons.event,
                      color: ziel.istUeberfaellig ? Colors.red : null,
                    ),
                ],
              ),

              if (ziel.beschreibung.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ziel.beschreibung,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Divider(height: 20),

              // Messungen-Bereich
              Row(
                children: [
                  Expanded(
                    child: letzteMessung == null
                        ? Text(
                            'Keine Messung - Baseline faellig',
                            style: TextStyle(color: Colors.orange.shade700, fontStyle: FontStyle.italic),
                          )
                        : Row(
                            children: [
                              const Text('Letzte: ', style: TextStyle(fontSize: 13)),
                              GasRatingWidget(value: letzteMessung.bewertung, kompakt: true, readOnly: true),
                              const SizedBox(width: 8),
                              Text(
                                '${letzteMessung.messdatum.day.toString().padLeft(2, '0')}.${letzteMessung.messdatum.month.toString().padLeft(2, '0')}.${letzteMessung.messdatum.year}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              Text('(${msgs.length} Msg)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  )),
                            ],
                          ),
                  ),
                  TextButton.icon(
                    onPressed: () => _neueMessung(ziel),
                    icon: const Icon(Icons.add_chart, size: 18),
                    label: const Text('Messung'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, IconData icon, {Color? color}) {
    final c = color ?? theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c, fontSize: 11)),
        ],
      ),
    );
  }
}
