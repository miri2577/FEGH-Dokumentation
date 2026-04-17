import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:provider/provider.dart';
import '../../models/rechnung.dart';
import '../../models/rechnung_empfaenger.dart';
import '../../providers/app_provider.dart';
import '../../services/rechnung_service.dart';
import '../../services/xrechnung_service.dart';
import 'empfaenger_editor_screen.dart';
import 'rechnung_erstellen_screen.dart';

/// Uebersicht aller Rechnungen mit XRechnung-XML-Export.
class RechnungenScreen extends StatefulWidget {
  const RechnungenScreen({super.key});

  @override
  State<RechnungenScreen> createState() => _RechnungenScreenState();
}

class _RechnungenScreenState extends State<RechnungenScreen> {
  final _service = RechnungService();
  List<Rechnung> _rechnungen = [];
  Map<String, RechnungEmpfaenger> _empfaengerMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _service.loadRechnungen();
    r.sort((a, b) => b.rechnungsdatum.compareTo(a.rechnungsdatum));
    final eListe = await _service.loadEmpfaenger();
    final eMap = {for (final e in eListe) e.id: e};
    if (!mounted) return;
    setState(() {
      _rechnungen = r;
      _empfaengerMap = eMap;
      _loading = false;
    });
  }

  Future<void> _neueRechnung() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RechnungErstellenScreen()),
    );
    await _load();
  }

  Future<void> _empfaengerVerwalten() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _EmpfaengerListeScreen()),
    );
    await _load();
  }

  Future<void> _exportiereXml(Rechnung r) async {
    final empf = _empfaengerMap[r.empfaengerId];
    if (empf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empfaenger nicht gefunden')),
      );
      return;
    }

    final app = context.read<AppProvider>();
    final settings = app.settings;

    final steller = RechnungsstellerDaten(
      name: settings.organizationId.isNotEmpty ? settings.organizationId : 'Leistungserbringer',
      strasse: '',
      plz: '',
      ort: '',
      ansprechpartner: settings.userName,
      email: null,
      telefon: null,
      elektronischeAdresse: null,
    );

    final service = XRechnungService(rechnungssteller: steller);
    final xml = service.buildXml(rechnung: r, empfaenger: empf);

    try {
      await FileSaver.instance.saveFile(
        name: 'XRechnung_${r.rechnungsnummer}',
        bytes: Uint8List.fromList(utf8.encode(xml)),
        ext: 'xml',
        mimeType: MimeType.other,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('XRechnung ${r.rechnungsnummer}.xml gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _xmlAnsehen(Rechnung r) async {
    final empf = _empfaengerMap[r.empfaengerId];
    if (empf == null) return;
    final app = context.read<AppProvider>();
    final steller = RechnungsstellerDaten(
      name: app.settings.organizationId.isNotEmpty ? app.settings.organizationId : 'Leistungserbringer',
      strasse: '',
      plz: '',
      ort: '',
    );
    final service = XRechnungService(rechnungssteller: steller);
    final xml = service.buildXml(rechnung: r, empfaenger: empf);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('XRechnung ${r.rechnungsnummer}'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              xml,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Kopieren'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: xml));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('XML in Zwischenablage kopiert')),
              );
            },
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Schliessen')),
        ],
      ),
    );
  }

  Future<void> _loeschen(Rechnung r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechnung loeschen?'),
        content: Text('Rechnung ${r.rechnungsnummer} wird unwiderruflich geloescht.'),
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
      await _service.deleteRechnung(r.id);
      await _load();
    }
  }

  Color _statusColor(RechnungStatus s) {
    switch (s) {
      case RechnungStatus.entwurf: return Colors.grey;
      case RechnungStatus.versendet: return Colors.blue;
      case RechnungStatus.bezahlt: return Colors.green;
      case RechnungStatus.storniert: return Colors.red;
    }
  }

  String _statusName(RechnungStatus s) {
    switch (s) {
      case RechnungStatus.entwurf: return 'Entwurf';
      case RechnungStatus.versendet: return 'Versendet';
      case RechnungStatus.bezahlt: return 'Bezahlt';
      case RechnungStatus.storniert: return 'Storniert';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechnungen (XRechnung)'),
        actions: [
          IconButton(
            tooltip: 'Empfaenger verwalten',
            icon: const Icon(Icons.business),
            onPressed: _empfaengerVerwalten,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rechnungen.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('Noch keine Rechnungen',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Erstellen Sie XRechnung-konforme Rechnungen aus Ihren Terminen.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _neueRechnung,
                          icon: const Icon(Icons.add),
                          label: const Text('Erste Rechnung erstellen'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rechnungen.length,
                    itemBuilder: (_, i) {
                      final r = _rechnungen[i];
                      final empf = _empfaengerMap[r.empfaengerId];
                      final farbe = _statusColor(r.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: farbe.withValues(alpha: 0.15),
                            child: Icon(Icons.receipt_long, color: farbe),
                          ),
                          title: Row(
                            children: [
                              Text(r.rechnungsnummer,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: farbe.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_statusName(r.status),
                                    style: TextStyle(color: farbe, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(empf?.name ?? 'Empfaenger unbekannt',
                                  style: const TextStyle(fontSize: 12)),
                              Text(
                                '${df.format(r.rechnungsdatum)} • ${r.positionen.length} Positionen • ${r.gesamtBrutto.toStringAsFixed(2)} EUR',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              switch (v) {
                                case 'xml': _exportiereXml(r); break;
                                case 'view': _xmlAnsehen(r); break;
                                case 'delete': _loeschen(r); break;
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'xml', child: Row(children: [
                                Icon(Icons.download, size: 18),
                                SizedBox(width: 8),
                                Text('XML herunterladen'),
                              ])),
                              PopupMenuItem(value: 'view', child: Row(children: [
                                Icon(Icons.code, size: 18),
                                SizedBox(width: 8),
                                Text('XML ansehen'),
                              ])),
                              PopupMenuItem(value: 'delete', child: Row(children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Loeschen', style: TextStyle(color: Colors.red)),
                              ])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _neueRechnung,
        icon: const Icon(Icons.add),
        label: const Text('Neue Rechnung'),
      ),
    );
  }
}

class _EmpfaengerListeScreen extends StatefulWidget {
  const _EmpfaengerListeScreen();

  @override
  State<_EmpfaengerListeScreen> createState() => _EmpfaengerListeScreenState();
}

class _EmpfaengerListeScreenState extends State<_EmpfaengerListeScreen> {
  final _service = RechnungService();
  List<RechnungEmpfaenger> _liste = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await _service.loadEmpfaenger();
    if (!mounted) return;
    setState(() {
      _liste = e;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechnungsempfaenger')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _liste.isEmpty
              ? const Center(child: Text('Noch keine Empfaenger angelegt'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _liste.length,
                  itemBuilder: (_, i) {
                    final e = _liste[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.business),
                        title: Text(e.name),
                        subtitle: Text('Leitweg: ${e.leitwegId}\n${e.strasse}, ${e.plz} ${e.ort}'),
                        isThreeLine: true,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmpfaengerEditorScreen(existing: e),
                            ),
                          );
                          await _load();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmpfaengerEditorScreen()),
          );
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Empfaenger'),
      ),
    );
  }
}
