import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fegh_billing/fegh_billing.dart';
import '../../models/appointment.dart';
import '../../models/client.dart';
import '../../providers/app_provider.dart';
import '../../services/audit_logger.dart';
import '../../services/rechnung_service.dart';
import 'empfaenger_editor_screen.dart';

/// Erstellt eine neue Rechnung aus Terminen im ausgewaehlten Zeitraum.
/// Gruppiert pro Klient und erzeugt Fachleistungsstunden-Positionen.
class RechnungErstellenScreen extends StatefulWidget {
  const RechnungErstellenScreen({super.key});

  @override
  State<RechnungErstellenScreen> createState() => _RechnungErstellenScreenState();
}

class _RechnungErstellenScreenState extends State<RechnungErstellenScreen> {
  final _service = RechnungService();
  DateTime _von = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _bis = DateTime.now();
  RechnungEmpfaenger? _empfaenger;
  List<RechnungEmpfaenger> _alleEmpfaenger = [];
  final _bestellnummer = TextEditingController();
  final _bemerkung = TextEditingController();
  final bool _nurAktiveKlienten = true;
  UstBefreiungsgrund _ustBefreiung = UstBefreiungsgrund.par4Nr16h;

  @override
  void initState() {
    super.initState();
    _loadEmpfaenger();
  }

  @override
  void dispose() {
    _bestellnummer.dispose();
    _bemerkung.dispose();
    super.dispose();
  }

  Future<void> _loadEmpfaenger() async {
    final liste = await _service.loadEmpfaenger();
    if (!mounted) return;
    setState(() => _alleEmpfaenger = liste);
  }

  Future<void> _neuerEmpfaenger() async {
    final result = await Navigator.push<RechnungEmpfaenger>(
      context,
      MaterialPageRoute(builder: (_) => const EmpfaengerEditorScreen()),
    );
    if (result != null) {
      await _loadEmpfaenger();
      if (mounted) setState(() => _empfaenger = result);
    }
  }

  Future<void> _pickDatum(bool von) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: von ? _von : _bis,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (von) {
          _von = picked;
        } else {
          _bis = picked;
        }
      });
    }
  }

  /// Ermittelt die Positionen aus Terminen im Zeitraum.
  List<_AggregatedPosition> _berechnePositionen(AppProvider app) {
    final appointments = app.appointments.where((a) {
      final d = DateTime(a.date.year, a.date.month, a.date.day);
      final vonD = DateTime(_von.year, _von.month, _von.day);
      final bisD = DateTime(_bis.year, _bis.month, _bis.day);
      return !d.isBefore(vonD) && !d.isAfter(bisD);
    }).toList();

    // Nur ABRECHENBARE TerminArten beruecksichtigen
    // (Supervision/Fortbildung/Fahrtzeit etc. sind im Stundensatz eingepreist)
    final abrechenbareTermine = appointments
        .where((a) => a.effectiveTerminArt.istAbrechenbar)
        .toList();

    // Gruppiere nach clientId (bei indirekten Terminen: pro ClientAllocation)
    final gruppen = <String, List<Appointment>>{};
    final indirekteStunden = <String, double>{};
    for (final a in abrechenbareTermine) {
      if (a.isIndirect && a.clientAllocations != null) {
        // Indirekte Termine: Stunden auf die zugeordneten Klienten aufteilen
        for (final alloc in a.clientAllocations!) {
          indirekteStunden[alloc.clientId] =
              (indirekteStunden[alloc.clientId] ?? 0) + alloc.stunden;
          gruppen.putIfAbsent(alloc.clientId, () => []).add(a);
        }
      } else {
        gruppen.putIfAbsent(a.clientId, () => []).add(a);
      }
    }

    final result = <_AggregatedPosition>[];
    final settings = app.settings;
    for (final entry in gruppen.entries) {
      final clientId = entry.key;
      final termine = entry.value;
      final client = app.clients.where((c) => c.id == clientId).firstOrNull;
      if (client == null) continue;
      if (_nurAktiveKlienten && client.fachleistungsstunden == null) continue;

      // Stunden korrekt aus direkten Terminen + indirekten Allocations
      double stunden = 0;
      for (final a in termine) {
        if (a.isIndirect) {
          // Bereits in indirekteStunden gezaehlt (vermeidet Doppelung)
        } else {
          stunden += a.fachleistungsstunden;
        }
      }
      stunden += indirekteStunden[clientId] ?? 0;
      if (stunden <= 0) continue;

      final satz = client.stundensatzOverride ?? settings.stundensatz;
      final minDatum = termine.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final maxDatum = termine.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);

      result.add(_AggregatedPosition(
        client: client,
        stunden: stunden,
        einzelpreis: satz,
        anzahlTermine: termine.length,
        vonDatum: minDatum,
        bisDatum: maxDatum,
      ));
    }
    result.sort((a, b) => a.client.vollstaendigerName.compareTo(b.client.vollstaendigerName));
    return result;
  }

  Future<void> _rechnungAnlegen(AppProvider app) async {
    if (_empfaenger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Empfaenger waehlen')),
      );
      return;
    }
    final positionen = _berechnePositionen(app);
    if (positionen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine abrechenbaren Termine im Zeitraum')),
      );
      return;
    }

    // Plausi-Check vor Rechnungserstellung
    if (!await _plausiCheck(app, positionen)) return;
    if (!mounted) return;

    await _wirklichAnlegen(app, positionen);
  }

  /// Prueft Klienten auf Pflichtfelder fuer rechtssichere Rechnung.
  Future<bool> _plausiCheck(AppProvider app, List<_AggregatedPosition> positionen) async {
    final fehler = <String>[]; // harte Pflichtfelder
    final warnungen = <String>[]; // weichere Hinweise

    // Empfaenger-Leitweg-ID pruefen
    if (!_empfaenger!.leitwegIdGueltig) {
      fehler.add('Empfaenger-Leitweg-ID ist formal ungueltig');
    }

    for (final p in positionen) {
      final c = p.client;
      final fallnr = c.fallnummerFuer(_empfaenger!.id);
      if (fallnr == null || fallnr.isEmpty) {
        fehler.add('${c.vollstaendigerName}: kein Aktenzeichen beim Empfaenger');
      }
      if (c.geburtsdatum == null) {
        warnungen.add('${c.vollstaendigerName}: Geburtsdatum fehlt');
      }
      if (c.leistungstypSchluessel == null || c.leistungstypSchluessel!.isEmpty) {
        warnungen.add('${c.vollstaendigerName}: Leistungstyp-Schluessel fehlt');
      }
      if (c.bewilligungsbescheidRef == null || c.bewilligungsbescheidRef!.isEmpty) {
        warnungen.add('${c.vollstaendigerName}: Bewilligungsbescheid-Ref fehlt');
      }

      // Budget-Ueberschreitung pruefen
      if (c.fachleistungsstunden != null) {
        final verbraucht = app.getFlsVerbrauchImAktuellenZeitraum(c);
        if (verbraucht > c.fachleistungsstunden!) {
          warnungen.add('${c.vollstaendigerName}: Budget ueberschritten '
              '(${verbraucht.toStringAsFixed(1)} / ${c.fachleistungsstunden} h)');
        }
      }
    }

    if (fehler.isEmpty && warnungen.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          fehler.isNotEmpty ? Icons.error : Icons.warning_amber,
          color: fehler.isNotEmpty ? Colors.red : Colors.orange,
          size: 40,
        ),
        title: Text(fehler.isNotEmpty ? 'Pflichtangaben fehlen' : 'Hinweise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fehler.isNotEmpty) ...[
                const Text(
                  'Ohne diese Angaben wird die Rechnung vom Sozialamt zurueckgewiesen:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 6),
                ...fehler.map((f) => Text('• $f', style: const TextStyle(fontSize: 13))),
              ],
              if (warnungen.isNotEmpty) ...[
                if (fehler.isNotEmpty) const SizedBox(height: 16),
                const Text(
                  'Diese Angaben werden oft verlangt:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 6),
                ...warnungen.map((w) => Text('• $w', style: const TextStyle(fontSize: 13))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zum Bearbeiten'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: fehler.isNotEmpty ? Colors.red.shade700 : null,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Trotzdem erstellen'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _wirklichAnlegen(AppProvider app, List<_AggregatedPosition> positionen) async {
    if (_empfaenger == null) {
      return;
    }

    final df = DateFormat('yyyy-MM-dd');
    final nummer = await _service.naechsteRechnungsnummer();
    final rPositionen = positionen.map((p) {
      final fallnr = p.client.fallnummerFuer(_empfaenger!.id);
      final geb = p.client.geburtsdatum != null ? df.format(p.client.geburtsdatum!) : null;
      return RechnungsPosition.create(
        bezeichnung: 'Fachleistungsstunden Eingliederungshilfe - ${p.client.vollstaendigerName}',
        menge: p.stunden,
        einheit: 'Stunde',
        einzelpreis: p.einzelpreis,
        steuerprozent: 0.0,
        leistungszeitraumVon: df.format(p.vonDatum),
        leistungszeitraumBis: df.format(p.bisDatum),
        clientId: p.client.id,
        clientName: p.client.vollstaendigerName,
        clientGeburtsdatum: geb,
        fallnummer: fallnr,
        leistungstyp: p.client.leistungstypSchluessel,
        bewilligungsRef: p.client.bewilligungsbescheidRef,
        hinweis: '${p.anzahlTermine} Termine',
      );
    }).toList();

    final rechnung = Rechnung.create(
      rechnungsnummer: nummer,
      rechnungsdatum: DateTime.now(),
      leistungsVon: _von,
      leistungsBis: _bis,
      empfaengerId: _empfaenger!.id,
      positionen: rPositionen,
      bestellnummer: _bestellnummer.text.trim().isEmpty ? null : _bestellnummer.text.trim(),
      bemerkung: _bemerkung.text.trim().isEmpty ? null : _bemerkung.text.trim(),
      ustBefreiung: _ustBefreiung,
    );
    await _service.addRechnung(rechnung);
    final userId = app.settings.userName;
    await AuditLogger.instance.logRechnungErstellt(
      userId,
      rechnung.rechnungsnummer,
      rechnung.gesamtBrutto,
    );
    if (!mounted) return;
    Navigator.pop(context, rechnung);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Neue Rechnung')),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final positionen = _berechnePositionen(app);
          final gesamt = positionen.fold<double>(0, (s, p) => s + p.stunden * p.einzelpreis);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Leistungszeitraum',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDatum(true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('Von: ${df.format(_von)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDatum(false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('Bis: ${df.format(_bis)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Empfaenger (Kostentraeger)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RechnungEmpfaenger>(
                      initialValue: _empfaenger,
                      decoration: const InputDecoration(
                        labelText: 'Empfaenger',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: _alleEmpfaenger
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('${e.name} (${e.leitwegId})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _empfaenger = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Neuer Empfaenger',
                    onPressed: _neuerEmpfaenger,
                    icon: const Icon(Icons.add_circle),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bestellnummer,
                decoration: const InputDecoration(
                  labelText: 'Bestellnummer/Aktenzeichen (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bemerkung,
                decoration: const InputDecoration(
                  labelText: 'Bemerkung (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UstBefreiungsgrund>(
                initialValue: _ustBefreiung,
                decoration: const InputDecoration(
                  labelText: 'Steuerbefreiung nach §4 UStG',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                  helperText: 'Im Zweifel Steuerberater fragen',
                ),
                items: UstBefreiungsgrund.values
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u.anzeigeText, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => v != null ? setState(() => _ustBefreiung = v) : null,
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Text('Positionen',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('Netto: ${gesamt.toStringAsFixed(2)} EUR',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              if (positionen.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(child: Text('Keine Termine im ausgewaehlten Zeitraum.')),
                    ],
                  ),
                )
              else
                ...positionen.map((p) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.person),
                        ),
                        title: Text(p.client.vollstaendigerName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.stunden.toStringAsFixed(2)} h × ${p.einzelpreis.toStringAsFixed(2)} EUR '
                            '• ${p.anzahlTermine} Termine'),
                        trailing: Text(
                          '${(p.stunden * p.einzelpreis).toStringAsFixed(2)} EUR',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: positionen.isEmpty || _empfaenger == null
                      ? null
                      : () => _rechnungAnlegen(app),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Rechnung erstellen'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AggregatedPosition {
  final Client client;
  final double stunden;
  final double einzelpreis;
  final int anzahlTermine;
  final DateTime vonDatum;
  final DateTime bisDatum;
  _AggregatedPosition({
    required this.client,
    required this.stunden,
    required this.einzelpreis,
    required this.anzahlTermine,
    required this.vonDatum,
    required this.bisDatum,
  });
}
