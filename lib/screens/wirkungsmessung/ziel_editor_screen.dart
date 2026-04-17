import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/b_e_ni.dart';
import '../../models/bei_bw.dart';
import '../../models/bei_nrw.dart';
import '../../models/bundesland.dart';
import '../../models/generisch_icf.dart';
import '../../models/hmbv.dart';
import '../../models/itp.dart';
import '../../models/teilhabeziel.dart';
import '../../models/client.dart';
import '../../providers/app_provider.dart';

/// Editor fuer ein einzelnes Teilhabeziel mit SMART-Kriterien.
class ZielEditorScreen extends StatefulWidget {
  final Client client;
  final Teilhabeziel? ziel; // null = neues Ziel

  const ZielEditorScreen({super.key, required this.client, this.ziel});

  @override
  State<ZielEditorScreen> createState() => _ZielEditorScreenState();
}

class _ZielEditorScreenState extends State<ZielEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titel;
  late TextEditingController _beschreibung;
  late TextEditingController _spezifisch;
  late TextEditingController _messbar;
  late TextEditingController _attraktiv;
  late TextEditingController _realistisch;
  late TextEditingController _icfBereich;
  DateTime? _terminiert;
  TeilhabezielKategorie _kategorie = TeilhabezielKategorie.teilziel;
  TeilhabezielStatus _status = TeilhabezielStatus.aktiv;
  int _prioritaet = 3;

  bool get _isEdit => widget.ziel != null;

  @override
  void initState() {
    super.initState();
    final z = widget.ziel;
    _titel = TextEditingController(text: z?.titel ?? '');
    _beschreibung = TextEditingController(text: z?.beschreibung ?? '');
    _spezifisch = TextEditingController(text: z?.spezifisch ?? '');
    _messbar = TextEditingController(text: z?.messbar ?? '');
    _attraktiv = TextEditingController(text: z?.attraktiv ?? '');
    _realistisch = TextEditingController(text: z?.realistisch ?? '');
    _icfBereich = TextEditingController(text: z?.icfBereich ?? '');
    _terminiert = z?.terminiert;
    _kategorie = z?.kategorie ?? TeilhabezielKategorie.teilziel;
    _status = z?.status ?? TeilhabezielStatus.aktiv;
    _prioritaet = z?.prioritaet ?? 3;
  }

  @override
  void dispose() {
    _titel.dispose();
    _beschreibung.dispose();
    _spezifisch.dispose();
    _messbar.dispose();
    _attraktiv.dispose();
    _realistisch.dispose();
    _icfBereich.dispose();
    super.dispose();
  }

  Future<void> _pickDatum() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _terminiert ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _terminiert = picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ziel = _isEdit
        ? widget.ziel!.copyWith(
            titel: _titel.text.trim(),
            beschreibung: _beschreibung.text.trim(),
            spezifisch: _spezifisch.text.trim().isEmpty ? null : _spezifisch.text.trim(),
            messbar: _messbar.text.trim().isEmpty ? null : _messbar.text.trim(),
            attraktiv: _attraktiv.text.trim().isEmpty ? null : _attraktiv.text.trim(),
            realistisch: _realistisch.text.trim().isEmpty ? null : _realistisch.text.trim(),
            terminiert: _terminiert,
            icfBereich: _icfBereich.text.trim().isEmpty ? null : _icfBereich.text.trim(),
            kategorie: _kategorie,
            status: _status,
            prioritaet: _prioritaet,
          )
        : Teilhabeziel.create(
            clientId: widget.client.id,
            titel: _titel.text.trim(),
            beschreibung: _beschreibung.text.trim(),
            spezifisch: _spezifisch.text.trim().isEmpty ? null : _spezifisch.text.trim(),
            messbar: _messbar.text.trim().isEmpty ? null : _messbar.text.trim(),
            attraktiv: _attraktiv.text.trim().isEmpty ? null : _attraktiv.text.trim(),
            realistisch: _realistisch.text.trim().isEmpty ? null : _realistisch.text.trim(),
            terminiert: _terminiert,
            icfBereich: _icfBereich.text.trim().isEmpty ? null : _icfBereich.text.trim(),
            kategorie: _kategorie,
            status: _status,
            prioritaet: _prioritaet,
          );
    Navigator.pop(context, ziel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ziel bearbeiten' : 'Neues Ziel'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Speichern'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Klient-Info
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('Klient: ${widget.client.vollstaendigerName}'),
                subtitle: widget.client.klientenId != null
                    ? Text('ID: ${widget.client.klientenId}')
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Titel
            TextFormField(
              controller: _titel,
              decoration: const InputDecoration(
                labelText: 'Titel *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beschreibung,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            Text('SMART-Kriterien',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSmartField('S', 'Spezifisch', 'Was genau soll erreicht werden?', _spezifisch),
            _buildSmartField('M', 'Messbar', 'Woran ist das Ziel erkennbar?', _messbar),
            _buildSmartField('A', 'Attraktiv', 'Warum ist das wichtig fuer den Klienten?', _attraktiv),
            _buildSmartField('R', 'Realistisch', 'Was ist konkret moeglich?', _realistisch),

            // Terminiert
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: const Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: const Text('Terminiert (bis wann?)'),
              subtitle: Text(_terminiert != null
                  ? '${_terminiert!.day.toString().padLeft(2, '0')}.${_terminiert!.month.toString().padLeft(2, '0')}.${_terminiert!.year}'
                  : 'Kein Termin gesetzt'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_terminiert != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _terminiert = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDatum,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // ICF-Verknuepfung
            _buildIcfAuswahl(),

            const SizedBox(height: 16),

            // Kategorie
            DropdownButtonFormField<TeilhabezielKategorie>(
              initialValue: _kategorie,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: TeilhabezielKategorie.values
                  .map((k) => DropdownMenuItem(
                        value: k,
                        child: Text(_kategorieName(k)),
                      ))
                  .toList(),
              onChanged: (v) => v != null ? setState(() => _kategorie = v) : null,
            ),

            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<TeilhabezielStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: TeilhabezielStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusName(s)),
                      ))
                  .toList(),
              onChanged: (v) => v != null ? setState(() => _status = v) : null,
            ),

            const SizedBox(height: 16),

            // Prioritaet
            Text('Prioritaet: $_prioritaet / 5',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            Slider(
              value: _prioritaet.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_prioritaet',
              onChanged: (v) => setState(() => _prioritaet = v.round()),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEdit ? 'Aenderungen speichern' : 'Ziel erstellen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcfAuswahl() {
    final orgBundesland = context.read<AppProvider>().settings.bundesland;
    final effektiv = widget.client.effektivesBundesland(orgBundesland);
    final profil = BundeslandProfile.forLand(effektiv);

    if (profil.beiNrwVerfuegbar) {
      return _buildDropdownAuswahl<BEINRWLebensbereich>(
        label: 'BEI_NRW-Lebensbereich',
        optionen: BEINRWLebensbereich.values,
        labelFor: (b) => '${b.icfCode} - ${b.displayName}',
        codeFor: (b) => b.icfCode,
        descFor: (b) => b.kurzBeschreibung,
        anzeigeVon: (b) => '${b.icfCode} ${b.displayName}',
      );
    }
    if (profil.beiBwVerfuegbar) {
      return _buildDropdownAuswahl<BEIBWLebensbereich>(
        label: 'BEI_BW-Lebensbereich',
        optionen: BEIBWLebensbereich.values,
        labelFor: (b) => '${b.icfCode} - ${b.displayName}',
        codeFor: (b) => b.icfCode,
        descFor: (b) => b.kurzBeschreibung,
        anzeigeVon: (b) => '${b.icfCode} ${b.displayName}',
      );
    }
    if (profil.itpVerfuegbar) {
      return _buildDropdownAuswahl<ITPLebensbereich>(
        label: 'ITP-Lebensbereich',
        optionen: ITPLebensbereich.values,
        labelFor: (b) => '${b.icfCode} - ${b.displayName}',
        codeFor: (b) => b.icfCode,
        descFor: (b) => b.kurzBeschreibung,
        anzeigeVon: (b) => '${b.icfCode} ${b.displayName}',
      );
    }
    if (profil.bEniVerfuegbar) {
      return _buildDropdownAuswahl<BENiLebensbereich>(
        label: 'B.E.Ni-Lebensbereich',
        optionen: BENiLebensbereich.values,
        labelFor: (b) => '${b.icfCode} - ${b.displayName}',
        codeFor: (b) => b.icfCode,
        descFor: (b) => b.kurzBeschreibung,
        anzeigeVon: (b) => '${b.icfCode} ${b.displayName}',
      );
    }
    if (profil.hmbvVerfuegbar) {
      return _buildDropdownAuswahl<HMBVBereich>(
        label: 'HMBV-Bereich',
        optionen: HMBVBereich.values,
        labelFor: (b) => '${b.kurzCode} - ${b.displayName}',
        codeFor: (b) => b.kurzCode,
        descFor: (b) => b.kurzBeschreibung,
        anzeigeVon: (b) => '${b.kurzCode} ${b.displayName}',
      );
    }
    if (profil.generischIcfVerfuegbar) {
      return _buildDropdownAuswahl<GenerischIcfLebensbereich>(
        label: 'ICF-Lebensbereich',
        optionen: GenerischIcfLebensbereich.values,
        labelFor: (b) => '${b.icfCode} - ${b.displayName}',
        codeFor: (b) => b.icfCode,
        descFor: (b) => b.kurzBeschreibung,
        anzeigeVon: (b) => '${b.icfCode} ${b.displayName}',
      );
    }

    // Berlin und Fallback: generisches ICF-Textfeld
    return TextFormField(
      controller: _icfBereich,
      decoration: InputDecoration(
        labelText: profil.bundesland == Bundesland.berlin
            ? 'ICF-Bereich (optional)'
            : 'ICF-/Bedarfsbereich (optional)',
        hintText: 'z.B. d170 Schreiben',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.category),
      ),
    );
  }

  Widget _buildDropdownAuswahl<T extends Enum>({
    required String label,
    required List<T> optionen,
    required String Function(T) labelFor,
    required String Function(T) codeFor,
    required String Function(T) descFor,
    required String Function(T) anzeigeVon,
  }) {
    T? selected;
    for (final b in optionen) {
      if (_icfBereich.text.startsWith(codeFor(b))) {
        selected = b;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
          initialValue: selected,
          decoration: InputDecoration(
            labelText: '$label (optional)',
            hintText: 'Auswaehlen...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.category),
          ),
          items: optionen
              .map((b) => DropdownMenuItem(value: b, child: Text(labelFor(b))))
              .toList(),
          onChanged: (b) {
            setState(() {
              _icfBereich.text = b != null ? anzeigeVon(b) : '';
            });
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              descFor(selected),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmartField(String letter, String label, String hint, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(letter, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: c,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _kategorieName(TeilhabezielKategorie k) {
    switch (k) {
      case TeilhabezielKategorie.leitziel: return 'Leitziel';
      case TeilhabezielKategorie.teilziel: return 'Teilhabeziel';
      case TeilhabezielKategorie.handlungsziel: return 'Handlungsziel';
    }
  }

  String _statusName(TeilhabezielStatus s) {
    switch (s) {
      case TeilhabezielStatus.aktiv: return 'Aktiv';
      case TeilhabezielStatus.erreicht: return 'Erreicht';
      case TeilhabezielStatus.pausiert: return 'Pausiert';
      case TeilhabezielStatus.abgebrochen: return 'Abgebrochen';
    }
  }
}
