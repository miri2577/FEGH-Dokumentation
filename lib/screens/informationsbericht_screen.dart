import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/informationsbericht.dart';
import '../models/teilhabeziel.dart' as wm;
import '../models/zielmessung.dart' as zm;
import '../services/wirkungsmessung_service.dart';
import '../services/file_storage_service.dart';
import '../services/pdf_generator_service.dart';
import 'pdf_preview_screen.dart';
import '../widgets/klienten_akte_widget.dart';

class InformationsberichtScreen extends StatefulWidget {
  final Client client;
  final Informationsbericht? existingBericht;

  const InformationsberichtScreen({
    super.key,
    required this.client,
    this.existingBericht,
  });

  @override
  State<InformationsberichtScreen> createState() => _InformationsberichtScreenState();
}

class _InformationsberichtScreenState extends State<InformationsberichtScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showDokuPanel = false;
  double _dokuPanelWidth = 380;

  // Kopfdaten
  late TextEditingController _teilhabefachdienstCtrl;
  late TextEditingController _idKostenuebernahmeCtrl;
  DateTime? _berichtszeitraumVon;
  DateTime? _berichtszeitraumBis;
  late TextEditingController _leistungstypCtrl;
  late TextEditingController _leistungserbringerCtrl;
  late TextEditingController _emailTelNrCtrl;
  late TextEditingController _strasseCtrl;
  late TextEditingController _hausnummerCtrl;
  late TextEditingController _adresshinweisCtrl;
  late TextEditingController _plzCtrl;
  late TextEditingController _ortCtrl;

  // Persoenliche Daten
  String? _anrede;
  String? _titel;
  late TextEditingController _familiennameCtrl;
  late TextEditingController _vornameCtrl;
  late TextEditingController _geburtsnameCtrl;
  DateTime? _geburtsdatum;
  late TextEditingController _geburtsortCtrl;
  String? _geschlecht;
  late TextEditingController _familienstandCtrl;
  late TextEditingController _telefonFestnetzCtrl;
  late TextEditingController _telefonMobilCtrl;
  late TextEditingController _emailCtrl;

  // Freitext-Sektionen
  late TextEditingController _allgemeineInfosCtrl;
  late TextEditingController _weitereAnmerkungenCtrl;
  bool? _nachtAssistenz;
  late TextEditingController _zusammenfassungCtrl;
  late TextEditingController _ortDatumCtrl;
  late TextEditingController _leistungserbringerUnterschriftCtrl;
  late TextEditingController _eintragungKlientCtrl;

  // Teilhabeziele
  List<_TeilhabezielFormData> _teilhabeziele = [];

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    final b = widget.existingBericht;

    _teilhabefachdienstCtrl = TextEditingController(text: b?.teilhabefachdienst ?? 'Treptow-Koepenick');
    _idKostenuebernahmeCtrl = TextEditingController(text: b?.idKostenuebernahme ?? widget.client.klientenId ?? '');
    _berichtszeitraumVon = b?.berichtszeitraumVon;
    _berichtszeitraumBis = b?.berichtszeitraumBis;
    _leistungstypCtrl = TextEditingController(text: b?.leistungstyp ?? '');
    _leistungserbringerCtrl = TextEditingController(text: b?.leistungserbringer ?? '');
    _emailTelNrCtrl = TextEditingController(text: b?.emailTelNr ?? '');
    _strasseCtrl = TextEditingController(text: b?.strasse ?? '');
    _hausnummerCtrl = TextEditingController(text: b?.hausnummer ?? '');
    _adresshinweisCtrl = TextEditingController(text: b?.weitererAdresshinweis ?? '');
    _plzCtrl = TextEditingController(text: b?.postleitzahl ?? '');
    _ortCtrl = TextEditingController(text: b?.ort ?? '');

    // Auto-Fill aus Client-Daten
    _anrede = b?.anrede;
    _titel = b?.titel;
    _familiennameCtrl = TextEditingController(text: b?.familienname ?? c.nachname ?? '');
    _vornameCtrl = TextEditingController(text: b?.vorname ?? c.vorname ?? '');
    _geburtsnameCtrl = TextEditingController(text: b?.geburtsname ?? '');
    _geburtsdatum = b?.geburtsdatum ?? c.geburtsdatum;
    _geburtsortCtrl = TextEditingController(text: b?.geburtsort ?? '');
    _geschlecht = b?.geschlecht;
    _familienstandCtrl = TextEditingController(text: b?.familienstand ?? '');
    _telefonFestnetzCtrl = TextEditingController(text: b?.telefonFestnetz ?? '');
    _telefonMobilCtrl = TextEditingController(text: b?.telefonMobil ?? '');
    _emailCtrl = TextEditingController(text: b?.email ?? '');

    _allgemeineInfosCtrl = TextEditingController(text: b?.allgemeineInformationen ?? '');
    _weitereAnmerkungenCtrl = TextEditingController(text: b?.weitereAnmerkungen ?? '');
    _nachtAssistenz = b?.nachtAssistenz;
    _zusammenfassungCtrl = TextEditingController(text: b?.zusammenfassung ?? '');
    _ortDatumCtrl = TextEditingController(text: b?.ortDatum ?? '');
    _leistungserbringerUnterschriftCtrl = TextEditingController(text: b?.leistungserbringerUnterschrift ?? '');
    _eintragungKlientCtrl = TextEditingController(text: b?.eintragungKlient ?? '');

    // Teilhabeziele aus Client-TIB-Zielen vorbelegen
    if (b?.teilhabeziele != null && b!.teilhabeziele!.isNotEmpty) {
      _teilhabeziele = b.teilhabeziele!.map((t) => _TeilhabezielFormData.fromModel(t)).toList();
    } else if (c.individuelleTibZiele != null && c.individuelleTibZiele!.isNotEmpty) {
      _teilhabeziele = c.individuelleTibZiele!.asMap().entries.map((e) {
        return _TeilhabezielFormData(
          teilhabezielTextCtrl: TextEditingController(text: e.value),
          teilhabezielNr: e.key + 1,
        );
      }).toList();
    } else {
      _teilhabeziele = [_TeilhabezielFormData()];
    }
  }

  @override
  void dispose() {
    _teilhabefachdienstCtrl.dispose();
    _idKostenuebernahmeCtrl.dispose();
    _leistungstypCtrl.dispose();
    _leistungserbringerCtrl.dispose();
    _emailTelNrCtrl.dispose();
    _strasseCtrl.dispose();
    _hausnummerCtrl.dispose();
    _adresshinweisCtrl.dispose();
    _plzCtrl.dispose();
    _ortCtrl.dispose();
    _familiennameCtrl.dispose();
    _vornameCtrl.dispose();
    _geburtsnameCtrl.dispose();
    _geburtsortCtrl.dispose();
    _familienstandCtrl.dispose();
    _telefonFestnetzCtrl.dispose();
    _telefonMobilCtrl.dispose();
    _emailCtrl.dispose();
    _allgemeineInfosCtrl.dispose();
    _weitereAnmerkungenCtrl.dispose();
    _zusammenfassungCtrl.dispose();
    _ortDatumCtrl.dispose();
    _leistungserbringerUnterschriftCtrl.dispose();
    _eintragungKlientCtrl.dispose();
    for (final tz in _teilhabeziele) {
      tz.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('Informationsbericht: ${widget.client.vollstaendigerName}'),
        actions: [
          if (!isWide)
            IconButton(
              icon: Icon(_showDokuPanel ? Icons.edit_note : Icons.folder_open),
              tooltip: _showDokuPanel ? 'Formular anzeigen' : 'Dokumentation anzeigen',
              onPressed: () => setState(() => _showDokuPanel = !_showDokuPanel),
            ),
          IconButton(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save),
            tooltip: 'Entwurf speichern',
          ),
          IconButton(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF exportieren',
          ),
        ],
      ),
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Formular (links, flexibel)
        Expanded(
          child: _buildFormular(),
        ),
        // Drag-Handle zum Resizen
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dokuPanelWidth = (_dokuPanelWidth - details.delta.dx).clamp(280, 700);
              });
            },
            child: Container(
              width: 6,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: Container(
                  width: 2,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Dokumentation (rechts, verstellbar)
        SizedBox(
          width: _dokuPanelWidth,
          child: KlientenAkteWidget(
            clientId: widget.client.id,
            clientName: widget.client.vollstaendigerName,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    if (_showDokuPanel) {
      return KlientenAkteWidget(
        clientId: widget.client.id,
        clientName: widget.client.vollstaendigerName,
      );
    }
    return _buildFormular();
  }

  Widget _buildFormular() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSektionHeader('Kopfdaten'),
            _buildKopfdatenCard(),
            const SizedBox(height: 24),

            _buildSektionHeader('1. Angaben zur leistungsberechtigten Person'),
            _buildPersonendatenCard(),
            const SizedBox(height: 24),

            _buildSektionHeader('2. Allgemeine Informationen'),
            _buildAllgemeineInfosCard(),
            const SizedBox(height: 24),

            _buildSektionHeader('3. Bericht zu vereinbarten Teilhabezielen'),
            ..._buildTeilhabezieleCards(),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _addTeilhabeziel,
                  icon: const Icon(Icons.add),
                  label: const Text('Weiteres Teilhabeziel'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _uebernehmenAusWirkungsmessung,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Aus Wirkungsmessung übernehmen'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSektionHeader('Weitere Anmerkungen zu den Zielen'),
            _buildWeitereAnmerkungenCard(),
            const SizedBox(height: 24),

            _buildSektionHeader('4. Zusammenfassung / Ausblick'),
            _buildZusammenfassungCard(),
            const SizedBox(height: 24),

            _buildSektionHeader('5. Unterschriften'),
            _buildUnterschriftenCard(),
            const SizedBox(height: 24),

            _buildSektionHeader('6. Eintragungen der leistungsberechtigten Person'),
            _buildEintragungKlientCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSektionHeader(String titel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titel,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildKopfdatenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _teilhabefachdienstCtrl,
              decoration: const InputDecoration(
                labelText: 'Teilhabefachdienst Soziales',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _idKostenuebernahmeCtrl,
              decoration: const InputDecoration(
                labelText: 'ID Kostenuebernahme',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate((d) => setState(() => _berichtszeitraumVon = d)),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Berichtszeitraum von',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_berichtszeitraumVon != null
                          ? _formatDate(_berichtszeitraumVon!)
                          : 'Datum waehlen'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate((d) => setState(() => _berichtszeitraumBis = d)),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'bis',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_berichtszeitraumBis != null
                          ? _formatDate(_berichtszeitraumBis!)
                          : 'Datum waehlen'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _leistungstypCtrl,
              decoration: const InputDecoration(
                labelText: 'Leistungstyp',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _leistungserbringerCtrl,
              decoration: const InputDecoration(
                labelText: 'Leistungserbringer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailTelNrCtrl,
              decoration: const InputDecoration(
                labelText: 'E-Mail / Tel Nr',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 24),
            Text('Adresse', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _strasseCtrl,
              decoration: const InputDecoration(
                labelText: 'Strasse',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hausnummerCtrl,
              decoration: const InputDecoration(
                labelText: 'Hausnummer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresshinweisCtrl,
              decoration: const InputDecoration(
                labelText: 'Weiterer Adresshinweis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _plzCtrl,
                    decoration: const InputDecoration(
                      labelText: 'PLZ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ort',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonendatenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _anrede,
                    decoration: const InputDecoration(
                      labelText: 'Anrede',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Herr', 'Frau', 'Divers'].map((v) =>
                      DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() => _anrede = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _titel,
                    decoration: const InputDecoration(
                      labelText: 'Titel',
                      border: OutlineInputBorder(),
                    ),
                    items: [null, 'Dr.', 'Prof.', 'Prof. Dr.'].map((v) =>
                      DropdownMenuItem(value: v, child: Text(v ?? 'Kein Titel'))).toList(),
                    onChanged: (v) => setState(() => _titel = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _familiennameCtrl,
              decoration: const InputDecoration(
                labelText: 'Familienname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vornameCtrl,
              decoration: const InputDecoration(
                labelText: 'Vorname(n)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _geburtsnameCtrl,
              decoration: const InputDecoration(
                labelText: 'Geburtsname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate((d) => setState(() => _geburtsdatum = d)),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Geburtsdatum',
                  border: OutlineInputBorder(),
                ),
                child: Text(_geburtsdatum != null
                    ? _formatDate(_geburtsdatum!)
                    : 'Datum waehlen'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _geburtsortCtrl,
              decoration: const InputDecoration(
                labelText: 'Geburtsort',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _geschlecht,
              decoration: const InputDecoration(
                labelText: 'Geschlecht',
                border: OutlineInputBorder(),
              ),
              items: ['maennlich', 'weiblich', 'divers'].map((v) =>
                DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _geschlecht = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _familienstandCtrl,
              decoration: const InputDecoration(
                labelText: 'Familienstand',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 24),
            Text('Kontaktinformationen', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonFestnetzCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefon (Festnetz)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonMobilCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefon (Mobil)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllgemeineInfosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Angaben zu Ausbildung, Arbeit, Tagesstruktur, bedeutsame Kontakte und weitere relevante Informationen',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allgemeineInfosCtrl,
              decoration: const InputDecoration(
                labelText: 'Allgemeine Informationen',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: 'Ausbildung, Beschaeftigung, Kontakte, Sozialraum...',
              ),
              maxLines: 12,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTeilhabezieleCards() {
    return _teilhabeziele.asMap().entries.map((entry) {
      final index = entry.key;
      final tz = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Teilhabeziel ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_teilhabeziele.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeTeilhabeziel(index),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: tz.leitzielNrCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Leitziel Nr',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: tz.leitzielTextCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Leitziel',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: tz.teilhabezielNrCtrl,
                        decoration: const InputDecoration(
                          labelText: 'TH-Ziel Nr',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: tz.teilhabezielTextCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Teilhabeziel aus ZLP',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tz.indikatorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Indikator',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text('Ziel erreicht?', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...ZielerreichungStatus.values.map((status) {
                  return RadioListTile<ZielerreichungStatus>(
                    title: Text(_zielerreichungLabel(status)),
                    value: status,
                    groupValue: tz.zielerreichung,
                    onChanged: (v) => setState(() => tz.zielerreichung = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 12),
                Text('Abweichende Einschaetzung der leistungsberechtigten Person?',
                    style: Theme.of(context).textTheme.bodySmall),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: tz.abweichendeEinschaetzung,
                      onChanged: (v) => setState(() => tz.abweichendeEinschaetzung = v),
                    ),
                    const Text('Nein'),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: true,
                      groupValue: tz.abweichendeEinschaetzung,
                      onChanged: (v) => setState(() => tz.abweichendeEinschaetzung = v),
                    ),
                    const Text('Ja'),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tz.erlaeuterungCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Erlaeuterung zur Zielerreichung',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    hintText: 'Was wurde erreicht/nicht erreicht? Welche Methoden?',
                  ),
                  maxLines: 8,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildWeitereAnmerkungenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prioritaeten Zielbearbeitung, Abgleich mit Indikatoren, foerderliche und hinderliche Kontextfaktoren',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weitereAnmerkungenCtrl,
              decoration: const InputDecoration(
                labelText: 'Weitere Anmerkungen zu den Zielen',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
            ),
            const SizedBox(height: 16),
            Text('Wurden Leistungen zur Erreichbarkeit in der Nacht in Anspruch genommen?'),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _nachtAssistenz,
                  onChanged: (v) => setState(() => _nachtAssistenz = v),
                ),
                const Text('Nein'),
                const SizedBox(width: 16),
                Radio<bool>(
                  value: true,
                  groupValue: _nachtAssistenz,
                  onChanged: (v) => setState(() => _nachtAssistenz = v),
                ),
                const Text('Ja'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZusammenfassungCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aussagen zu Umfang und Art der Unterstuetzung, Veraenderung Zielstellung, Hinweise fuer neue Ziel- und Leistungsplanung',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zusammenfassungCtrl,
              decoration: const InputDecoration(
                labelText: 'Zusammenfassung / Ausblick',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnterschriftenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _ortDatumCtrl,
              decoration: const InputDecoration(
                labelText: 'Ort, Datum',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _leistungserbringerUnterschriftCtrl,
              decoration: const InputDecoration(
                labelText: 'Leistungserbringer (Ansprechperson/Bezugsbetreuung)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEintragungKlientCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'z.B. zur Kenntnis / Einverstaendnis / andere Sichtweise',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _eintragungKlientCtrl,
              decoration: const InputDecoration(
                labelText: 'Eintragungen der leistungsberechtigten Person',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  void _addTeilhabeziel() {
    setState(() {
      _teilhabeziele.add(_TeilhabezielFormData());
    });
  }

  /// Laedt die Teilhabeziele aus der Wirkungsmessung und befuellt das Formular.
  /// Zielerreichung wird aus der letzten GAS-Messung abgeleitet.
  Future<void> _uebernehmenAusWirkungsmessung() async {
    final wmService = WirkungsmessungService();
    final ziele = await wmService.zieleFuerClient(widget.client.id);
    final aktiveZiele = ziele
        .where((z) => z.status == wm.TeilhabezielStatus.aktiv ||
            z.status == wm.TeilhabezielStatus.erreicht)
        .toList();

    if (aktiveZiele.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Keine aktiven Teilhabeziele aus der Wirkungsmessung gefunden. '
          'Zuerst unter "Teilhabeziele & Wirkung" anlegen.',
        )),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aus Wirkungsmessung uebernehmen'),
        content: Text(
          '${aktiveZiele.length} Teilhabeziele werden aus der Wirkungsmessung '
          'uebernommen. Die Zielerreichung wird aus der letzten GAS-Messung '
          'abgeleitet. Bisherige Eintraege werden ersetzt.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uebernehmen')),
        ],
      ),
    );
    if (confirm != true) return;

    // Aktuelle Form-Zustaende verwerfen
    for (final tz in _teilhabeziele) {
      tz.dispose();
    }
    final neueFormDaten = <_TeilhabezielFormData>[];

    for (int i = 0; i < aktiveZiele.length; i++) {
      final z = aktiveZiele[i];
      final messungen = await wmService.messungenFuerZiel(z.id);
      ZielerreichungStatus? zielerreichung;
      if (messungen.isNotEmpty) {
        final letzte = zm.GasBewertungExtension(messungen.last.bewertung).wert;
        zielerreichung = zielerreichungAusGas(letzte);
      } else if (z.status == wm.TeilhabezielStatus.erreicht) {
        zielerreichung = ZielerreichungStatus.vollErreicht;
      }

      final erlaeuterung = messungen.isNotEmpty && messungen.last.kommentar != null
          ? messungen.last.kommentar!
          : z.beschreibung;

      neueFormDaten.add(_TeilhabezielFormData.fromModel(Teilhabeziel(
        teilhabezielNr: i + 1,
        teilhabezielText: z.titel,
        indikator: [z.spezifisch, z.messbar]
            .where((s) => s != null && s.isNotEmpty)
            .join(' | '),
        zielerreichung: zielerreichung,
        erlaeuterung: erlaeuterung,
        leitzielText: z.kategorie == wm.TeilhabezielKategorie.leitziel ? z.titel : null,
      )));
    }

    if (!mounted) return;
    setState(() {
      _teilhabeziele = neueFormDaten;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${aktiveZiele.length} Ziele uebernommen'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeTeilhabeziel(int index) {
    setState(() {
      _teilhabeziele[index].dispose();
      _teilhabeziele.removeAt(index);
    });
  }

  Future<void> _selectDate(Function(DateTime) onSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _zielerreichungLabel(ZielerreichungStatus status) {
    switch (status) {
      case ZielerreichungStatus.vollErreicht:
        return 'Das Ziel wurde voll erreicht.';
      case ZielerreichungStatus.teilweiseErreicht:
        return 'Das Ziel wurde teilweise erreicht.';
      case ZielerreichungStatus.nichtErreicht:
        return 'Das Ziel wurde nicht erreicht.';
      case ZielerreichungStatus.nichtBeurteilbar:
        return 'Die Zielerreichung kann nicht beurteilt werden.';
    }
  }

  Informationsbericht _buildBerichtFromForm() {
    return Informationsbericht(
      id: widget.existingBericht?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: widget.client.id,
      createdAt: widget.existingBericht?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      istEntwurf: true,
      teilhabefachdienst: _teilhabefachdienstCtrl.text,
      idKostenuebernahme: _idKostenuebernahmeCtrl.text,
      berichtszeitraumVon: _berichtszeitraumVon,
      berichtszeitraumBis: _berichtszeitraumBis,
      leistungstyp: _leistungstypCtrl.text,
      leistungserbringer: _leistungserbringerCtrl.text,
      emailTelNr: _emailTelNrCtrl.text,
      strasse: _strasseCtrl.text,
      hausnummer: _hausnummerCtrl.text,
      weitererAdresshinweis: _adresshinweisCtrl.text,
      postleitzahl: _plzCtrl.text,
      ort: _ortCtrl.text,
      anrede: _anrede,
      titel: _titel,
      familienname: _familiennameCtrl.text,
      vorname: _vornameCtrl.text,
      geburtsname: _geburtsnameCtrl.text,
      geburtsdatum: _geburtsdatum,
      geburtsort: _geburtsortCtrl.text,
      geschlecht: _geschlecht,
      familienstand: _familienstandCtrl.text,
      telefonFestnetz: _telefonFestnetzCtrl.text,
      telefonMobil: _telefonMobilCtrl.text,
      email: _emailCtrl.text,
      allgemeineInformationen: _allgemeineInfosCtrl.text,
      teilhabeziele: _teilhabeziele.map((tz) => Teilhabeziel(
        leitzielNr: int.tryParse(tz.leitzielNrCtrl.text),
        leitzielText: tz.leitzielTextCtrl.text,
        teilhabezielNr: int.tryParse(tz.teilhabezielNrCtrl.text),
        teilhabezielText: tz.teilhabezielTextCtrl.text,
        indikator: tz.indikatorCtrl.text,
        zielerreichung: tz.zielerreichung,
        abweichendeEinschaetzung: tz.abweichendeEinschaetzung,
        erlaeuterung: tz.erlaeuterungCtrl.text,
      )).toList(),
      weitereAnmerkungen: _weitereAnmerkungenCtrl.text,
      nachtAssistenz: _nachtAssistenz,
      zusammenfassung: _zusammenfassungCtrl.text,
      ortDatum: _ortDatumCtrl.text,
      leistungserbringerUnterschrift: _leistungserbringerUnterschriftCtrl.text,
      eintragungKlient: _eintragungKlientCtrl.text,
    );
  }

  Future<void> _saveDraft() async {
    final bericht = _buildBerichtFromForm();
    final storage = FileStorageService();
    final berichte = await storage.loadBerichte();

    // Bestehenden Entwurf aktualisieren oder neuen hinzufuegen
    final existingIndex = berichte.indexWhere((b) => b.id == bericht.id);
    if (existingIndex >= 0) {
      berichte[existingIndex] = bericht;
    } else {
      berichte.add(bericht);
    }

    final success = await storage.saveBerichte(berichte);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Entwurf gespeichert' : 'Fehler beim Speichern'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    // Plausi-Check: Pflichtfelder fuer rechtssichere Einreichung
    final fehlende = <String>[];
    if (_teilhabefachdienstCtrl.text.trim().isEmpty) fehlende.add('Teilhabefachdienst/Bezirk');
    if (_idKostenuebernahmeCtrl.text.trim().isEmpty) fehlende.add('ID Kostenuebernahme');
    if (_familiennameCtrl.text.trim().isEmpty) fehlende.add('Familienname');
    if (_vornameCtrl.text.trim().isEmpty) fehlende.add('Vorname');
    if (_berichtszeitraumVon == null) fehlende.add('Berichtszeitraum von');
    if (_berichtszeitraumBis == null) fehlende.add('Berichtszeitraum bis');
    if (_leistungserbringerCtrl.text.trim().isEmpty) fehlende.add('Leistungserbringer');
    if (_teilhabeziele.isEmpty ||
        _teilhabeziele.every((z) => z.teilhabezielTextCtrl.text.trim().isEmpty)) {
      fehlende.add('Mindestens ein Teilhabeziel');
    }
    if (_zusammenfassungCtrl.text.trim().isEmpty) fehlende.add('Zusammenfassung/Ausblick');
    if (_ortDatumCtrl.text.trim().isEmpty) fehlende.add('Ort, Datum');

    // Warnungen (nicht hart-blockierend)
    final warnungen = <String>[];
    final zieleOhneErreichung = _teilhabeziele
        .where((z) => z.teilhabezielTextCtrl.text.trim().isNotEmpty && z.zielerreichung == null)
        .length;
    if (zieleOhneErreichung > 0) {
      warnungen.add('$zieleOhneErreichung Ziele ohne Zielerreichungs-Status');
    }
    final zieleOhneIndikator = _teilhabeziele
        .where((z) => z.teilhabezielTextCtrl.text.trim().isNotEmpty && z.indikatorCtrl.text.trim().isEmpty)
        .length;
    if (zieleOhneIndikator > 0) {
      warnungen.add('$zieleOhneIndikator Ziele ohne Indikator (messbares Kriterium)');
    }

    if (fehlende.isNotEmpty || warnungen.isNotEmpty) {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            fehlende.isNotEmpty ? Icons.error : Icons.warning_amber,
            color: fehlende.isNotEmpty ? Colors.red : Colors.orange,
            size: 40,
          ),
          title: Text(fehlende.isNotEmpty ? 'Pflichtfelder fehlen' : 'Hinweise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fehlende.isNotEmpty) ...[
                  const Text('Folgende Pflichtfelder sind leer:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 6),
                  ...fehlende.map((f) => Text('• $f', style: const TextStyle(fontSize: 13))),
                  const SizedBox(height: 12),
                  const Text(
                    'Ein Bericht ohne Pflichtangaben kann vom Teilhabefachdienst '
                    'zurueckgewiesen werden.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                if (warnungen.isNotEmpty) ...[
                  if (fehlende.isNotEmpty) const SizedBox(height: 16),
                  const Text('Weitere Hinweise:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
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
                backgroundColor: fehlende.isNotEmpty ? Colors.red.shade700 : null,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Trotzdem exportieren'),
            ),
          ],
        ),
      );
      if (result != true) return;
    }

    // Nur noch Template-Fill: fuellt das offizielle Berliner PDF-Formular aus.
    if (!mounted) return;
    await _generateAndExportPdf('syncfusion');
  }

  Future<void> _generateAndExportPdf(String variant) async {
    debugPrint('[PDF] _generateAndExportPdf gestartet: variant=$variant');
    try {
      final bericht = _buildBerichtFromForm().copyWith(istEntwurf: false);
      debugPrint('[PDF] Bericht gebaut: id=${bericht.id}');
      debugPrint('[PDF] familienname=${bericht.familienname}, vorname=${bericht.vorname}');
      debugPrint('[PDF] teilhabefachdienst=${bericht.teilhabefachdienst}');
      debugPrint('[PDF] idKostenuebernahme=${bericht.idKostenuebernahme}');
      debugPrint('[PDF] leistungserbringer=${bericht.leistungserbringer}');
      debugPrint('[PDF] allgemeineInformationen=${bericht.allgemeineInformationen?.substring(0, (bericht.allgemeineInformationen?.length ?? 0).clamp(0, 50))}');
      debugPrint('[PDF] zusammenfassung=${bericht.zusammenfassung?.substring(0, (bericht.zusammenfassung?.length ?? 0).clamp(0, 50))}');

      final pdfData = await PdfGeneratorService.generateInformationsberichtSyncfusion(bericht);
      const suffix = 'Formular101';
      debugPrint('[PDF] PDF generiert: ${pdfData.length} Bytes');

      final fileName = 'Informationsbericht_${suffix}_${widget.client.vollstaendigerName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (!mounted) return;
      // Druckvorschau anzeigen mit Print/Save Optionen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            pdfBytes: pdfData,
            title: 'Informationsbericht ($suffix)',
            fileName: fileName,
          ),
        ),
      );
      debugPrint('[PDF] Druckvorschau geoeffnet');
    } catch (e, stackTrace) {
      debugPrint('[PDF] FEHLER: $e');
      debugPrint('[PDF] StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF-Fehler: $e'), duration: const Duration(seconds: 5)),
        );
      }
    }
  }
}

class _TeilhabezielFormData {
  final TextEditingController leitzielNrCtrl;
  final TextEditingController leitzielTextCtrl;
  final TextEditingController teilhabezielNrCtrl;
  final TextEditingController teilhabezielTextCtrl;
  final TextEditingController indikatorCtrl;
  final TextEditingController erlaeuterungCtrl;
  ZielerreichungStatus? zielerreichung;
  bool? abweichendeEinschaetzung;

  _TeilhabezielFormData({
    TextEditingController? leitzielNrCtrl,
    TextEditingController? leitzielTextCtrl,
    TextEditingController? teilhabezielNrCtrl,
    TextEditingController? teilhabezielTextCtrl,
    TextEditingController? indikatorCtrl,
    TextEditingController? erlaeuterungCtrl,
    this.zielerreichung,
    this.abweichendeEinschaetzung,
    int? teilhabezielNr,
  })  : leitzielNrCtrl = leitzielNrCtrl ?? TextEditingController(),
        leitzielTextCtrl = leitzielTextCtrl ?? TextEditingController(),
        teilhabezielNrCtrl = teilhabezielNrCtrl ?? TextEditingController(text: teilhabezielNr?.toString() ?? ''),
        teilhabezielTextCtrl = teilhabezielTextCtrl ?? TextEditingController(),
        indikatorCtrl = indikatorCtrl ?? TextEditingController(),
        erlaeuterungCtrl = erlaeuterungCtrl ?? TextEditingController();

  factory _TeilhabezielFormData.fromModel(Teilhabeziel t) {
    return _TeilhabezielFormData(
      leitzielNrCtrl: TextEditingController(text: t.leitzielNr?.toString() ?? ''),
      leitzielTextCtrl: TextEditingController(text: t.leitzielText ?? ''),
      teilhabezielNrCtrl: TextEditingController(text: t.teilhabezielNr?.toString() ?? ''),
      teilhabezielTextCtrl: TextEditingController(text: t.teilhabezielText ?? ''),
      indikatorCtrl: TextEditingController(text: t.indikator ?? ''),
      erlaeuterungCtrl: TextEditingController(text: t.erlaeuterung ?? ''),
      zielerreichung: t.zielerreichung,
      abweichendeEinschaetzung: t.abweichendeEinschaetzung,
    );
  }

  void dispose() {
    leitzielNrCtrl.dispose();
    leitzielTextCtrl.dispose();
    teilhabezielNrCtrl.dispose();
    teilhabezielTextCtrl.dispose();
    indikatorCtrl.dispose();
    erlaeuterungCtrl.dispose();
  }
}
